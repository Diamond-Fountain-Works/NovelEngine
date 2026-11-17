import Foundation
import NovelDomain

public struct ProjectRevision: Codable, Equatable, Sendable {
    public let generation: UUID
    public let digest: String
}

public struct StoredProject: Sendable {
    public let project: NovelProject
    public let revision: ProjectRevision
}

public struct ProjectCatalog: Sendable {
    public let projects: [StoredProject]
    public let unreadableIDs: [String]
}

/// One actor serializes local I/O; the file lock also protects separate processes.
/// Each commit publishes a complete snapshot through one atomic head-file write.
public actor ManagedProjectRepository {
    public let root: URL
    private struct Head: Codable { let revision: ProjectRevision; let previous: UUID? }
    private var projectsRoot: URL { root.appendingPathComponent("作品", isDirectory: true) }
    public init(root: URL) { self.root = root.standardizedFileURL }

    public func catalog() throws -> ProjectCatalog {
        try LibraryFiles.locked(root: root) {
            try LibraryFiles.directory(projectsRoot, create: true)
            var projects: [StoredProject] = [], unreadable: [String] = []
            for name in try LibraryFiles.manager.contentsOfDirectory(atPath: projectsRoot.path) {
                guard let id = UUID(uuidString: name) else { continue }
                do { projects.append(try read(id)) } catch { unreadable.append(name) }
            }
            projects.sort { $0.project.updatedAt == $1.project.updatedAt ? $0.project.id.uuidString < $1.project.id.uuidString : $0.project.updatedAt > $1.project.updatedAt }
            return ProjectCatalog(projects: projects, unreadableIDs: unreadable.sorted())
        }
    }
    public func load(_ id: UUID) throws -> StoredProject { try LibraryFiles.locked(root: root) { try read(id) } }
    public func create(_ project: NovelProject) throws -> StoredProject {
        try LibraryFiles.locked(root: root) {
            guard !LibraryFiles.manager.fileExists(atPath: folder(project.id).path) else { throw LibraryError.duplicateProject }
            return try commit(project, expected: nil)
        }
    }
    public func save(_ project: NovelProject, expected: ProjectRevision) throws -> StoredProject {
        try LibraryFiles.locked(root: root) { try commit(project, expected: expected) }
    }

    public func importProject(from source: URL) throws -> StoredProject {
        try LibraryFiles.locked(root: root) {
            let files = try LibraryFiles.readPackage(source, allowAssets: true)
            let project = try ProjectPackageCodec().decode(files)
            if LibraryFiles.manager.fileExists(atPath: folder(project.id).path) {
                let existing = try read(project.id)
                guard existing.project == project else { throw LibraryError.duplicateProject }
                return existing
            }
            if let cover = project.details.cover {
                let sourceAssets = source.appendingPathComponent("assets")
                try LibraryFiles.verifyCover(cover, assets: sourceAssets)
                let destination = assets(project.id)
                try LibraryFiles.directory(destination, create: true)
                try LibraryFiles.manager.copyItem(at: source.appendingPathComponent(cover.relativePath),
                    to: destination.appendingPathComponent(URL(fileURLWithPath: cover.relativePath).lastPathComponent))
            }
            return try commit(project, expected: nil)
        }
    }

    public func addCover(from source: URL, fileExtension: String, projectID: UUID) throws -> ProjectCover {
        try LibraryFiles.locked(root: root) {
            _ = try read(projectID)
            let id = UUID(), destination = assets(projectID)
            guard !fileExtension.isEmpty, fileExtension.count <= 12,
                  fileExtension.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else { throw LibraryError.damagedCover }
            try LibraryFiles.regular(source); try LibraryFiles.directory(destination, create: true)
            let target = destination.appendingPathComponent("\(id.uuidString.lowercased()).\(fileExtension)")
            try LibraryFiles.manager.copyItem(at: source, to: target)
            do {
                let (hash, count) = try LibraryFiles.fileDigest(target)
                let cover = ProjectCover(id: id, fileExtension: fileExtension, originalFilename: source.lastPathComponent, byteCount: count, sha256: hash)
                guard cover.isValid else { throw LibraryError.damagedCover }
                return cover
            } catch { try? LibraryFiles.manager.removeItem(at: target); throw error }
        }
    }
    public func coverURL(_ cover: ProjectCover, projectID: UUID) throws -> URL {
        try LibraryFiles.locked(root: root) {
            try LibraryFiles.verifyCover(cover, assets: assets(projectID))
            return folder(projectID).appendingPathComponent(cover.relativePath)
        }
    }

    public func exportProject(_ project: NovelProject, to destination: URL) throws {
        try LibraryFiles.locked(root: root) {
            let target = destination.standardizedFileURL.resolvingSymlinksInPath().path
            let library = root.resolvingSymlinksInPath().path
            guard destination.isFileURL, target != library, !target.hasPrefix(library + "/") else { throw LibraryError.invalidFile }
            let files = try ProjectPackageCodec().encode(project)
            if let cover = project.details.cover { try LibraryFiles.verifyCover(cover, assets: assets(project.id)) }
            let stage = destination.deletingLastPathComponent().appendingPathComponent("NovelEngine-Export-\(UUID().uuidString)", isDirectory: true)
            defer { try? LibraryFiles.manager.removeItem(at: stage) }
            try LibraryFiles.writePackage(files, to: stage)
            if let cover = project.details.cover {
                try LibraryFiles.directory(stage.appendingPathComponent("assets"), create: true)
                try LibraryFiles.manager.copyItem(at: folder(project.id).appendingPathComponent(cover.relativePath), to: stage.appendingPathComponent(cover.relativePath))
            }
            if LibraryFiles.manager.fileExists(atPath: destination.path) {
                try LibraryFiles.directory(destination)
                _ = try LibraryFiles.manager.replaceItemAt(destination, withItemAt: stage)
            } else { try LibraryFiles.manager.moveItem(at: stage, to: destination) }
        }
    }

    private func folder(_ id: UUID) -> URL { projectsRoot.appendingPathComponent(id.uuidString.lowercased(), isDirectory: true) }
    private func assets(_ id: UUID) -> URL { folder(id).appendingPathComponent("assets", isDirectory: true) }
    private func head(_ id: UUID) throws -> Head {
        let url = folder(id).appendingPathComponent("head.json")
        try LibraryFiles.directory(folder(id)); try LibraryFiles.regular(url)
        return try JSONDecoder().decode(Head.self, from: Data(contentsOf: url))
    }
    private func read(_ id: UUID) throws -> StoredProject {
        let current = try head(id), revisions = folder(id).appendingPathComponent("revisions")
        try LibraryFiles.directory(revisions)
        let files = try LibraryFiles.readPackage(revisions.appendingPathComponent(current.revision.generation.uuidString.lowercased()))
        guard LibraryFiles.digest(files) == current.revision.digest else { throw LibraryError.changedOnDisk }
        let project = try ProjectPackageCodec().decode(files)
        guard project.id == id else { throw LibraryError.invalidFile }
        if let cover = project.details.cover { try LibraryFiles.verifyCover(cover, assets: assets(id)) }
        return StoredProject(project: project, revision: current.revision)
    }
    private func commit(_ project: NovelProject, expected: ProjectRevision?) throws -> StoredProject {
        if let expected {
            guard try read(project.id).revision == expected else { throw LibraryError.changedOnDisk }
        } else if LibraryFiles.manager.fileExists(atPath: folder(project.id).appendingPathComponent("head.json").path) { throw LibraryError.duplicateProject }
        let files = try ProjectPackageCodec().encode(project)
        if let cover = project.details.cover { try LibraryFiles.verifyCover(cover, assets: assets(project.id)) }
        let revision = ProjectRevision(generation: UUID(), digest: LibraryFiles.digest(files))
        let revisions = folder(project.id).appendingPathComponent("revisions", isDirectory: true)
        try LibraryFiles.directory(projectsRoot, create: true)
        try LibraryFiles.directory(folder(project.id), create: true)
        try LibraryFiles.directory(revisions, create: true)
        let snapshot = revisions.appendingPathComponent(revision.generation.uuidString.lowercased(), isDirectory: true)
        try LibraryFiles.writePackage(files, to: snapshot)
        guard LibraryFiles.digest(try LibraryFiles.readPackage(snapshot)) == revision.digest else { throw LibraryError.invalidFile }
        let data = try JSONEncoder().encode(Head(revision: revision, previous: expected?.generation))
        try LibraryFiles.write(data, to: folder(project.id).appendingPathComponent("head.json"))
        // Only generated snapshots outside the current and previous commits are disposable.
        let keep = Set([revision.generation, expected?.generation].compactMap { $0 })
        for name in (try? LibraryFiles.manager.contentsOfDirectory(atPath: revisions.path)) ?? [] {
            if let id = UUID(uuidString: name), !keep.contains(id) {
                let old = revisions.appendingPathComponent(name)
                if (try? old.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true { try? LibraryFiles.manager.removeItem(at: old) }
            }
        }
        return StoredProject(project: project, revision: revision)
    }
}
