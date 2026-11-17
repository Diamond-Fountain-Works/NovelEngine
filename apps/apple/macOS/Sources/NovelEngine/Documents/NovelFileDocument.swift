import Foundation
import SwiftUI
import UniformTypeIdentifiers
import NovelDomain
import NovelStorage

extension UTType {
    static let novelEngineProject = UTType(exportedAs: "com.diamondfountain.novelengine.project", conformingTo: .package)
}

struct NovelFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.novelEngineProject] }
    var project: NovelProject
    init(project: NovelProject = NovelProject()) { self.project = project }
    init(configuration: ReadConfiguration) throws { try self.init(fileWrapper: configuration.file) }
    init(fileWrapper wrapper: FileWrapper) throws {
        guard wrapper.isDirectory, let root = wrapper.fileWrappers,
              let manifest = root["project.json"], manifest.isRegularFile, let manifestData = manifest.regularFileContents,
              let texts = root["documents"], texts.isDirectory, let contents = texts.fileWrappers,
              root.keys.allSatisfy({ ["project.json", "documents", ".DS_Store"].contains($0) }) else { throw ProjectFormatError.invalidManifest }
        var files = ["project.json": manifestData]
        for (name, file) in contents {
            guard file.isRegularFile, let data = file.regularFileContents else { throw ProjectFormatError.invalidManifest }
            files["documents/\(name)"] = data
        }
        project = try ProjectPackageCodec().decode(files)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { try packageWrapper() }
    func packageWrapper() throws -> FileWrapper {
        let files = try ProjectPackageCodec().encode(project)
        var texts: [String: FileWrapper] = [:]
        for document in project.documents {
            let name = "\(document.id.uuidString.lowercased()).txt"
            texts[name] = FileWrapper(regularFileWithContents: files["documents/\(name)"]!)
        }
        return FileWrapper(directoryWithFileWrappers: [
            "project.json": FileWrapper(regularFileWithContents: files["project.json"]!),
            "documents": FileWrapper(directoryWithFileWrappers: texts)
        ])
    }
}
