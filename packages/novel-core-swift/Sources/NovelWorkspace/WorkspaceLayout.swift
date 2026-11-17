import Foundation

public struct WorkspaceSnapshot: Codable, Equatable, Sendable {
    public let root: WorkspaceNode
    public let activePaneID: UUID
    public init(root: WorkspaceNode, activePaneID: UUID) { self.root = root; self.activePaneID = activePaneID }
}

public struct WorkspaceLayout: Sendable {
    public private(set) var root: WorkspaceNode
    public private(set) var activePaneID: UUID
    private var history: [WorkspaceSnapshot] = []
    public var snapshot: WorkspaceSnapshot { WorkspaceSnapshot(root: root, activePaneID: activePaneID) }
    public var canUndo: Bool { !history.isEmpty }
    public var activePane: EditorPane { root.panes.first { $0.id == activePaneID } ?? root.panes[0] }
    public init(documentID: UUID, includingManuscript: Bool = false) {
        let pane = EditorPane(documentID: documentID)
        root = includingManuscript ? .split(WorkspaceBranch(axis: .horizontal, ratio: 0.22,
            first: .pane(EditorPane(documentID: documentID, content: .manuscript)), second: .pane(pane))) : .pane(pane)
        activePaneID = pane.id
    }
    public init?(restoring snapshot: WorkspaceSnapshot, validDocumentIDs: Set<UUID>) {
        let ids = snapshot.root.allIDs
        guard Set(ids).count == ids.count, snapshot.root.validRatios,
              snapshot.root.panes.contains(where: { $0.id == snapshot.activePaneID }),
              snapshot.root.panes.allSatisfy({ validDocumentIDs.contains($0.documentID) }) else { return nil }
        root = snapshot.root; activePaneID = snapshot.activePaneID
    }
    public mutating func activate(_ id: UUID) {
        if root.panes.contains(where: { $0.id == id }) { activePaneID = id }
    }
    public mutating func open(_ documentID: UUID, in paneID: UUID? = nil) {
        let id = paneID ?? activePaneID
        guard let pane = root.panes.first(where: { $0.id == id }) else { return }
        root = root.replacing(id, with: .pane(EditorPane(id: pane.id, documentID: documentID, content: pane.content)))
        activePaneID = id
    }
    public mutating func split(_ direction: SplitDirection, in paneID: UUID? = nil) {
        guard let old = root.panes.first(where: { $0.id == (paneID ?? activePaneID) }) else { return }
        remember()
        let new = EditorPane(documentID: old.documentID, content: old.content)
        let branch = WorkspaceBranch(axis: direction.axis, first: .pane(direction.insertsFirst ? new : old), second: .pane(direction.insertsFirst ? old : new))
        root = root.replacing(old.id, with: .split(branch)); activePaneID = new.id
    }
    public mutating func setContent(_ content: WorkspaceContent, in paneID: UUID) {
        guard var pane = root.panes.first(where: { $0.id == paneID }), pane.content != content else { return }
        remember(); pane.content = content
        root = root.replacing(paneID, with: .pane(pane)); activePaneID = paneID
    }
    public mutating func restoreWorkspace(documentID: UUID) {
        remember()
        let restored = Self(documentID: documentID, includingManuscript: true)
        root = restored.root; activePaneID = restored.activePaneID
    }
    public func joinOptions(from paneID: UUID) -> [PaneJoin] {
        [SplitDirection.right, .left, .down, .up].compactMap { direction in
            guard let join = root.joinTarget(from: paneID, toward: direction), root.joining(join) != nil else { return nil }
            return join
        }
    }
    public func boundaryJoins(_ branchID: UUID, fraction: Double) -> [PaneJoin] { root.boundaryJoins(branchID, fraction: fraction) }
    public func boundarySource(_ branchID: UUID, fraction: Double) -> EditorPane? { root.boundarySource(branchID, fraction: fraction) }
    /// The source editor expands toward its neighbour; only that neighbour closes.
    @discardableResult public mutating func join(from paneID: UUID, toward direction: SplitDirection) -> Bool {
        guard let join = root.joinTarget(from: paneID, toward: direction), let joined = root.joining(join) else { return false }
        remember()
        root = joined; activePaneID = paneID
        return true
    }
    @discardableResult public mutating func close(_ paneID: UUID) -> Bool {
        let panes = root.panes
        guard panes.count > 1, let index = panes.firstIndex(where: { $0.id == paneID }), let remaining = root.removingPane(paneID) else { return false }
        remember(); root = remaining
        if activePaneID == paneID { activePaneID = root.panes[min(index, root.panes.count - 1)].id }
        return true
    }
    @discardableResult public mutating func closeAll(_ content: WorkspaceContent) -> Bool {
        let targets = root.panes.filter { $0.content == content }
        guard !targets.isEmpty, targets.count < root.panes.count else { return false }
        remember()
        for pane in targets {
            if let remaining = root.removingPane(pane.id) { root = remaining }
        }
        if !root.panes.contains(where: { $0.id == activePaneID }) { activePaneID = root.panes[0].id }
        return true
    }
    public mutating func resize(_ branchID: UUID, ratio: Double) {
        guard ratio.isFinite, case .split(var branch) = root.node(branchID) else { return }
        branch.ratio = min(0.85, max(0.15, ratio)); root = root.replacing(branchID, with: .split(branch))
    }
    public mutating func reset() {
        guard root.panes.count > 1 else { return }
        remember(); root = .pane(activePane)
    }
    public mutating func undo() {
        guard let previous = history.popLast() else { return }
        root = previous.root; activePaneID = previous.activePaneID
    }
    private mutating func remember() {
        history.append(snapshot)
        if history.count > 32 { history.removeFirst(history.count - 32) }
    }
}
