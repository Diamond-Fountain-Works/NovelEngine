import Foundation
import NovelDomain

public enum ProjectFormatError: LocalizedError, Equatable {
    case missingManifest, unsupportedVersion(Int), invalidManifest, missingText(UUID), invalidUTF8(UUID)
    public var errorDescription: String? {
        switch self {
        case .missingManifest: "作品缺少 project.json。"
        case .unsupportedVersion(let version): "此作品使用格式 \(version)，当前支持格式 1。"
        case .invalidManifest: "作品目录损坏，无法读取。"
        case .missingText(let id): "章节正文缺失：\(id)。"
        case .invalidUTF8(let id): "章节不是有效的 UTF-8 文本：\(id)。"
        }
    }
}

/// Platform-neutral archive entries. Native document coordination lives in the Mac adapter.
public struct ProjectPackageCodec: Sendable {
    private struct Manifest: Codable {
        let schemaVersion: Int
        let projectId: UUID
        let title: String
        let createdAt: Date
        let updatedAt: Date
        let documents: [Entry]
    }
    private struct Entry: Codable {
        let id: UUID
        let kind: WritingKind
        let title: String
        let synopsis: String
        let createdAt: Date
        let updatedAt: Date
    }
    public init() {}
    public static func textPath(_ id: UUID) -> String { "documents/\(id.uuidString.lowercased()).txt" }

    public func encode(_ project: NovelProject) throws -> [String: Data] {
        guard !project.documents.isEmpty, Set(project.documents.map(\.id)).count == project.documents.count else { throw ProjectFormatError.invalidManifest }
        let manifest = Manifest(schemaVersion: 1, projectId: project.id, title: project.title, createdAt: project.createdAt, updatedAt: project.updatedAt, documents: project.documents.map { Entry(id: $0.id, kind: $0.kind, title: $0.title, synopsis: $0.synopsis, createdAt: $0.createdAt, updatedAt: $0.updatedAt) })
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var files = ["project.json": try encoder.encode(manifest)]
        for document in project.documents { files[Self.textPath(document.id)] = Data(document.body.utf8) }
        return files
    }
    public func decode(_ files: [String: Data]) throws -> NovelProject {
        guard let data = files["project.json"] else { throw ProjectFormatError.missingManifest }
        // Inspect the version before attempting to interpret a future schema.
        guard let header = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let version = header["schemaVersion"] as? Int else { throw ProjectFormatError.invalidManifest }
        guard version == 1 else { throw ProjectFormatError.unsupportedVersion(version) }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        guard let manifest = try? decoder.decode(Manifest.self, from: data), !manifest.documents.isEmpty, Set(manifest.documents.map(\.id)).count == manifest.documents.count else { throw ProjectFormatError.invalidManifest }
        let documents = try manifest.documents.map { entry -> WritingDocument in
            guard let body = files[Self.textPath(entry.id)] else { throw ProjectFormatError.missingText(entry.id) }
            guard let text = String(data: body, encoding: .utf8) else { throw ProjectFormatError.invalidUTF8(entry.id) }
            return WritingDocument(id: entry.id, kind: entry.kind, title: entry.title, body: text, synopsis: entry.synopsis, createdAt: entry.createdAt, updatedAt: entry.updatedAt)
        }
        return NovelProject(id: manifest.projectId, title: manifest.title, documents: documents, createdAt: manifest.createdAt, updatedAt: manifest.updatedAt)
    }
}
