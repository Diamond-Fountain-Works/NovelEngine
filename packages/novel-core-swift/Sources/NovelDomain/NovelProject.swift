import Foundation

public enum WritingKind: String, Codable, CaseIterable, Sendable {
    case chapter, note, character, event, world, setting
    public var title: String {
        switch self {
        case .chapter: "章节"; case .note: "笔记"; case .character: "人物"
        case .event: "事件"; case .world: "世界观"; case .setting: "设定"
        }
    }
    public var symbol: String {
        switch self {
        case .chapter: "doc.text"; case .note: "note.text"; case .character: "person.crop.rectangle"
        case .event: "point.3.connected.trianglepath.dotted"; case .world: "globe"; case .setting: "books.vertical"
        }
    }
    public var isReference: Bool { self != .chapter && self != .note }
}

public struct WritingDocument: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var kind: WritingKind
    public var title: String
    public var body: String
    public var synopsis: String
    public var parentID: UUID?
    public var reference: ReferenceDetails?
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), kind: WritingKind, title: String, body: String = "", synopsis: String = "", parentID: UUID? = nil, reference: ReferenceDetails? = nil, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id; self.kind = kind; self.title = title; self.body = body
        self.synopsis = synopsis; self.createdAt = createdAt; self.updatedAt = updatedAt ?? createdAt
        self.parentID = parentID; self.reference = kind.isReference ? (reference ?? ReferenceDetails()) : reference
    }
    public var statistics: TextStatistics { TextStatistics(body) }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.kind == rhs.kind && lhs.title.utf8.elementsEqual(rhs.title.utf8)
            && lhs.body.utf8.elementsEqual(rhs.body.utf8) && lhs.synopsis.utf8.elementsEqual(rhs.synopsis.utf8)
            && lhs.parentID == rhs.parentID && lhs.reference == rhs.reference
            && lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt
    }
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
    public var manuscriptStatistics: TextStatistics {
        let chapters = documents.filter { $0.kind == .chapter }
        return TextStatistics(characters: chapters.reduce(0) { $0 + $1.statistics.characters }, paragraphs: chapters.reduce(0) { $0 + $1.statistics.paragraphs })
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title.utf8.elementsEqual(rhs.title.utf8) && lhs.documents == rhs.documents
            && lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt
    }
}
