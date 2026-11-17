import Foundation
import CryptoKit
import NovelDomain
#if canImport(Darwin)
import Darwin
#endif

public enum LibraryError: LocalizedError, Equatable {
    case invalidFile, busy, changedOnDisk, duplicateProject, missingProject, damagedCover
    public var errorDescription: String? {
        switch self {
        case .invalidFile: "作品文件损坏或包含不支持的文件。"
        case .busy: "另一进程正在保存作品，请重试。"
        case .changedOnDisk: "磁盘中的作品已变化。请先导出当前编辑副本，再重新打开。"
        case .duplicateProject: "作品库中已有这部小说。请打开已有作品。"
        case .missingProject: "找不到作品，请检查文稿目录。"
        case .damagedCover: "封面文件缺失或校验失败，请重新选择图片。"
        }
    }
}

enum LibraryFiles {
    static var manager: FileManager { FileManager() }
    static func directory(_ url: URL, create: Bool = false) throws {
        if create && !manager.fileExists(atPath: url.path) { try manager.createDirectory(at: url, withIntermediateDirectories: true) }
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values.isDirectory == true, values.isSymbolicLink != true else { throw LibraryError.invalidFile }
    }
    static func regular(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else { throw LibraryError.invalidFile }
    }
    static func digest(_ files: [String: Data]) -> String {
        var hash = SHA256()
        for name in files.keys.sorted() {
            hash.update(data: Data(name.utf8)); hash.update(data: Data([0]))
            var count = UInt64(files[name]!.count).bigEndian
            withUnsafeBytes(of: &count) { hash.update(data: Data($0)) }
            hash.update(data: files[name]!)
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
    static func fileDigest(_ url: URL) throws -> (String, Int64) {
        try regular(url)
        let handle = try FileHandle(forReadingFrom: url); defer { try? handle.close() }
        var hash = SHA256(), count: Int64 = 0
        while let data = try handle.read(upToCount: 65_536), !data.isEmpty { hash.update(data: data); count += Int64(data.count) }
        return (hash.finalize().map { String(format: "%02x", $0) }.joined(), count)
    }
    static func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
        let handle = try FileHandle(forWritingTo: url); defer { try? handle.close() }
        try handle.synchronize()
    }
    static func readPackage(_ url: URL, allowAssets: Bool = false) throws -> [String: Data] {
        try directory(url)
        let allowed: Set<String> = allowAssets ? ["project.json", "documents", "assets", ".DS_Store"] : ["project.json", "documents", ".DS_Store"]
        let children = try manager.contentsOfDirectory(atPath: url.path)
        guard children.allSatisfy(allowed.contains) else { throw LibraryError.invalidFile }
        let manifest = url.appendingPathComponent("project.json"), documents = url.appendingPathComponent("documents")
        try regular(manifest); try directory(documents)
        var result = ["project.json": try Data(contentsOf: manifest)]
        for file in try manager.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil) {
            if file.lastPathComponent == ".DS_Store" { continue }
            try regular(file)
            guard file.pathExtension == "txt", UUID(uuidString: file.deletingPathExtension().lastPathComponent) != nil else { throw LibraryError.invalidFile }
            result["documents/\(file.lastPathComponent)"] = try Data(contentsOf: file)
        }
        let project = try ProjectPackageCodec().decode(result)
        guard Set(result.keys) == Set(["project.json"] + project.documents.map { ProjectPackageCodec.textPath($0.id) }) else { throw LibraryError.invalidFile }
        if allowAssets && children.contains("assets") {
            let assets = url.appendingPathComponent("assets")
            try directory(assets)
            let names = try manager.contentsOfDirectory(atPath: assets.path).filter { $0 != ".DS_Store" }
            let expected = project.details.cover.map { [URL(fileURLWithPath: $0.relativePath).lastPathComponent] } ?? []
            guard Set(names) == Set(expected) else { throw LibraryError.invalidFile }
        }
        return result
    }
    static func writePackage(_ files: [String: Data], to url: URL) throws {
        guard !manager.fileExists(atPath: url.path) else { throw LibraryError.invalidFile }
        _ = try ProjectPackageCodec().decode(files)
        try directory(url.appendingPathComponent("documents"), create: true)
        for (path, data) in files { try write(data, to: url.appendingPathComponent(path)) }
    }
    static func verifyCover(_ cover: ProjectCover, assets: URL) throws {
        guard cover.isValid else { throw LibraryError.damagedCover }
        try directory(assets)
        let url = assets.appendingPathComponent("\(cover.id.uuidString.lowercased()).\(cover.fileExtension)")
        let (hash, count) = try fileDigest(url)
        guard hash == cover.sha256, count == cover.byteCount else { throw LibraryError.damagedCover }
    }
}

private final class LibraryFileLock {
    let descriptor: Int32
    init(_ url: URL) throws {
        descriptor = Darwin.open(url.path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw LibraryError.invalidFile }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else { Darwin.close(descriptor); throw LibraryError.busy }
    }
    deinit { flock(descriptor, LOCK_UN); Darwin.close(descriptor) }
}

extension LibraryFiles {
    static func locked<T>(root: URL, action: () throws -> T) throws -> T {
        try directory(root, create: true)
        let lock = try LibraryFileLock(root.appendingPathComponent("library.lock"))
        return try withExtendedLifetime(lock, action)
    }
}
