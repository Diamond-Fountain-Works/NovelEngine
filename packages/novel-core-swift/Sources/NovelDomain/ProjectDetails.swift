import Foundation

public enum NovelWritingStatus: String, Codable, CaseIterable, Sendable {
    case planning, writing, completed
    public var title: String { switch self { case .planning: "构思中"; case .writing: "写作中"; case .completed: "已完稿" } }
}

public struct Contributor: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var role: String
    public init(id: UUID = UUID(), name: String = "", role: String = "") { self.id = id; self.name = name; self.role = role }
    public static func == (a: Self, b: Self) -> Bool {
        a.id == b.id && a.name.utf8.elementsEqual(b.name.utf8) && a.role.utf8.elementsEqual(b.role.utf8)
    }
}

public struct ProjectCover: Codable, Equatable, Sendable {
    public let id: UUID
    public let fileExtension: String
    public let originalFilename: String
    public let byteCount: Int64
    public let sha256: String
    public var relativePath: String { "assets/\(id.uuidString.lowercased()).\(fileExtension)" }
    public init(id: UUID = UUID(), fileExtension: String, originalFilename: String, byteCount: Int64, sha256: String) {
        self.id = id; self.fileExtension = fileExtension; self.originalFilename = originalFilename
        self.byteCount = byteCount; self.sha256 = sha256
    }
    public var isValid: Bool {
        !fileExtension.isEmpty && fileExtension.count <= 12 && fileExtension.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) }
            && byteCount > 0 && sha256.count == 64 && sha256.allSatisfy { "0123456789abcdef".contains($0) }
    }
}

public struct ProjectDetails: Codable, Equatable, Sendable {
    public var author: String
    public var contributors: [Contributor]
    public var genre: String
    public var tags: String
    public var synopsis: String
    public var status: NovelWritingStatus
    public var cover: ProjectCover?
    public init(author: String = "", contributors: [Contributor] = [], genre: String = "", tags: String = "",
                synopsis: String = "", status: NovelWritingStatus = .writing, cover: ProjectCover? = nil) {
        self.author = author; self.contributors = contributors; self.genre = genre; self.tags = tags
        self.synopsis = synopsis; self.status = status; self.cover = cover
    }
    public static func == (a: Self, b: Self) -> Bool {
        a.author.utf8.elementsEqual(b.author.utf8) && a.genre.utf8.elementsEqual(b.genre.utf8)
            && a.tags.utf8.elementsEqual(b.tags.utf8) && a.synopsis.utf8.elementsEqual(b.synopsis.utf8)
            && a.contributors == b.contributors && a.status == b.status && a.cover == b.cover
    }
}
