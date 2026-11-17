import Foundation

public enum CanonStatus: String, Codable, CaseIterable, Sendable {
    case undecided, confirmed
    public var title: String { self == .confirmed ? "已定案" : "待定" }
}

/// Author-managed metadata. References never copy or rewrite another document's prose.
public struct ReferenceDetails: Codable, Equatable, Sendable {
    public var status: CanonStatus
    public var code: String
    public var tags: [String]
    public var timeAnchor: String
    public var relatedIDs: [UUID]
    public var participantIDs: [UUID]
    public var prerequisiteIDs: [UUID]

    public init(status: CanonStatus = .undecided, code: String = "", tags: [String] = [], timeAnchor: String = "",
                relatedIDs: [UUID] = [], participantIDs: [UUID] = [], prerequisiteIDs: [UUID] = []) {
        self.status = status; self.code = code; self.tags = tags; self.timeAnchor = timeAnchor
        self.relatedIDs = relatedIDs; self.participantIDs = participantIDs; self.prerequisiteIDs = prerequisiteIDs
    }
    public var linkedIDs: [UUID] {
        var seen = Set<UUID>()
        return (relatedIDs + participantIDs + prerequisiteIDs).filter { seen.insert($0).inserted }
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.status == rhs.status && lhs.code.utf8.elementsEqual(rhs.code.utf8)
            && lhs.timeAnchor.utf8.elementsEqual(rhs.timeAnchor.utf8) && lhs.tags.count == rhs.tags.count
            && zip(lhs.tags, rhs.tags).allSatisfy { $0.0.utf8.elementsEqual($0.1.utf8) }
            && lhs.relatedIDs == rhs.relatedIDs && lhs.participantIDs == rhs.participantIDs && lhs.prerequisiteIDs == rhs.prerequisiteIDs
    }
}

public enum LibrarySection: String, Codable, CaseIterable, Sendable {
    case manuscript, characters, events, world, settings
    public var title: String {
        switch self {
        case .manuscript: "书稿"; case .characters: "人物"; case .events: "事件"
        case .world: "世界观"; case .settings: "设定"
        }
    }
    public var kind: WritingKind {
        switch self {
        case .manuscript: .chapter; case .characters: .character; case .events: .event
        case .world: .world; case .settings: .setting
        }
    }
    public var symbol: String { self == .manuscript ? "doc.text" : kind.symbol }
}
