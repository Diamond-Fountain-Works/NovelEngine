import Foundation

public enum WritingKind: String, Codable, CaseIterable, Sendable {
    case chapter, note
    public var title: String { self == .chapter ? "章节" : "笔记" }
}

public struct WritingDocument: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var kind: WritingKind
    public var title: String
    public var body: String
    public var synopsis: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), kind: WritingKind, title: String, body: String = "", synopsis: String = "", createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id; self.kind = kind; self.title = title; self.body = body
        self.synopsis = synopsis; self.createdAt = createdAt; self.updatedAt = updatedAt ?? createdAt
    }
    public var statistics: TextStatistics { TextStatistics(body) }
}

public struct NovelProject: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var documents: [WritingDocument]
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String = "未命名小说", documents: [WritingDocument]? = nil, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id; self.title = title; self.createdAt = createdAt; self.updatedAt = updatedAt ?? createdAt
        self.documents = documents ?? [WritingDocument(kind: .chapter, title: "第一章", createdAt: createdAt)]
    }
    public func document(_ id: UUID) -> WritingDocument? { documents.first { $0.id == id } }
    public var statistics: TextStatistics { TextStatistics(characters: documents.reduce(0) { $0 + $1.statistics.characters }, paragraphs: documents.reduce(0) { $0 + $1.statistics.paragraphs }) }
}
