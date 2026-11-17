import Foundation

public enum SplitAxis: String, Codable, Sendable { case horizontal, vertical }
public enum SplitDirection: String, CaseIterable, Codable, Sendable {
    case left, right, up, down
    public var axis: SplitAxis { self == .left || self == .right ? .horizontal : .vertical }
    public var insertsFirst: Bool { self == .left || self == .up }
    public var title: String {
        switch self { case .left: "向左分栏"; case .right: "向右分栏"; case .up: "向上分栏"; case .down: "向下分栏" }
    }
}

public enum WorkspaceContent: String, Codable, CaseIterable, Sendable {
    case manuscript, editor, inspector
    public var title: String {
        switch self { case .manuscript: "书稿"; case .editor: "正文"; case .inspector: "章节信息" }
    }
    public var symbol: String {
        switch self { case .manuscript: "list.bullet.rectangle"; case .editor: "doc.text"; case .inspector: "info.circle" }
    }
}

public struct EditorPane: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public var documentID: UUID
    public var content: WorkspaceContent
    public init(id: UUID = UUID(), documentID: UUID, content: WorkspaceContent = .editor) {
        self.id = id; self.documentID = documentID; self.content = content
    }
    private enum CodingKeys: String, CodingKey { case id, documentID, content }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        documentID = try values.decode(UUID.self, forKey: .documentID)
        content = try values.decodeIfPresent(WorkspaceContent.self, forKey: .content) ?? .editor
    }
}
public struct WorkspaceBranch: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let axis: SplitAxis
    public var ratio: Double
    public var first: WorkspaceNode
    public var second: WorkspaceNode
    public init(id: UUID = UUID(), axis: SplitAxis, ratio: Double = 0.5, first: WorkspaceNode, second: WorkspaceNode) {
        self.id = id; self.axis = axis; self.ratio = ratio; self.first = first; self.second = second
    }
}
public indirect enum WorkspaceNode: Codable, Equatable, Sendable, Identifiable {
    case pane(EditorPane)
    case split(WorkspaceBranch)

    public var id: UUID { switch self { case .pane(let pane): pane.id; case .split(let branch): branch.id } }
    public var panes: [EditorPane] {
        switch self { case .pane(let pane): [pane]; case .split(let branch): branch.first.panes + branch.second.panes }
    }
    public func node(_ id: UUID) -> Self? {
        if self.id == id { return self }
        if case .split(let branch) = self { return branch.first.node(id) ?? branch.second.node(id) }
        return nil
    }
    public func parent(of id: UUID) -> WorkspaceBranch? {
        guard case .split(let branch) = self else { return nil }
        if branch.first.id == id || branch.second.id == id { return branch }
        return branch.first.parent(of: id) ?? branch.second.parent(of: id)
    }
    func replacing(_ id: UUID, with replacement: Self) -> Self {
        if self.id == id { return replacement }
        guard case .split(var branch) = self else { return self }
        branch.first = branch.first.replacing(id, with: replacement)
        branch.second = branch.second.replacing(id, with: replacement)
        return .split(branch)
    }
    var validRatios: Bool {
        guard case .split(let branch) = self else { return true }
        return branch.ratio.isFinite && (0.15...0.85).contains(branch.ratio) && branch.first.validRatios && branch.second.validRatios
    }
    var allIDs: [UUID] {
        guard case .split(let branch) = self else { return [id] }
        return [id] + branch.first.allIDs + branch.second.allIDs
    }
}
