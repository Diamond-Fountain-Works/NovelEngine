import Foundation

public struct EditorWorkspaceSnapshot: Codable, Equatable, Sendable {
    public var primary: EditorPane
    public var auxiliary: EditorPane?
    public var direction: SplitDirection
    public var primaryFraction: Double
    public var splitID: UUID
    public var activePaneID: UUID

    public init(primary: EditorPane, auxiliary: EditorPane? = nil, direction: SplitDirection = .right,
                primaryFraction: Double = 0.5, splitID: UUID = UUID(), activePaneID: UUID? = nil) {
        self.primary = primary; self.auxiliary = auxiliary; self.direction = direction
        self.primaryFraction = primaryFraction; self.splitID = splitID
        self.activePaneID = activePaneID ?? primary.id
    }
}

/// The library is outside this layout. Direction changes move the same auxiliary
/// editor rather than recursively splitting the focused view.
public struct EditorWorkspaceLayout: Sendable {
    public private(set) var snapshot: EditorWorkspaceSnapshot
    private var history: [EditorWorkspaceSnapshot] = []

    public var primary: EditorPane { snapshot.primary }
    public var auxiliary: EditorPane? { snapshot.auxiliary }
    public var direction: SplitDirection { snapshot.direction }
    public var activePaneID: UUID { snapshot.activePaneID }
    public var activePane: EditorPane { auxiliary?.id == activePaneID ? auxiliary! : primary }
    public var canUndo: Bool { !history.isEmpty }
    public var root: WorkspaceNode { root(primaryFraction: snapshot.primaryFraction) }

    public init(documentID: UUID) {
        snapshot = EditorWorkspaceSnapshot(primary: EditorPane(documentID: documentID))
    }

    public init?(restoring snapshot: EditorWorkspaceSnapshot, validDocumentIDs: Set<UUID>) {
        let panes = [snapshot.primary] + (snapshot.auxiliary.map { [$0] } ?? [])
        guard panes.allSatisfy({ $0.content == .editor && validDocumentIDs.contains($0.documentID) }),
              Set(panes.map(\.id)).count == panes.count,
              !panes.contains(where: { $0.id == snapshot.splitID }),
              panes.contains(where: { $0.id == snapshot.activePaneID }),
              snapshot.primaryFraction.isFinite, (0.15...0.85).contains(snapshot.primaryFraction) else { return nil }
        self.snapshot = snapshot
    }

    /// Read old local layout preferences without altering the old keys or any
    /// project document. Retain the first editor and, when available, the active
    /// other editor. Surplus legacy views are not documents and are not deleted.
    public init?(migrating legacy: WorkspaceSnapshot, validDocumentIDs: Set<UUID>) {
        guard WorkspaceLayout(restoring: legacy, validDocumentIDs: validDocumentIDs) != nil else { return nil }
        let editors = legacy.root.panes.filter { $0.content == .editor }
        let primary = editors.first ?? EditorPane(documentID: legacy.root.panes[0].documentID)
        let auxiliary = editors.first { $0.id == legacy.activePaneID && $0.id != primary.id }
            ?? editors.first { $0.id != primary.id }
        var direction = SplitDirection.right
        if let auxiliary {
            let placements = legacy.root.placements()
            if let a = placements.first(where: { $0.pane.id == primary.id })?.rect,
               let b = placements.first(where: { $0.pane.id == auxiliary.id })?.rect {
                let dx = b.x + b.width / 2 - a.x - a.width / 2
                let dy = b.y + b.height / 2 - a.y - a.height / 2
                direction = abs(dx) >= abs(dy) ? (dx < 0 ? .left : .right) : (dy < 0 ? .up : .down)
            }
        }
        snapshot = EditorWorkspaceSnapshot(primary: primary, auxiliary: auxiliary, direction: direction,
            activePaneID: auxiliary?.id == legacy.activePaneID ? legacy.activePaneID : primary.id)
    }

    public mutating func activate(_ paneID: UUID) {
        guard root.panes.contains(where: { $0.id == paneID }) else { return }
        snapshot.activePaneID = paneID
    }

    public mutating func open(_ documentID: UUID, in paneID: UUID? = nil) {
        let target = paneID ?? activePaneID
        if target == primary.id { snapshot.primary.documentID = documentID }
        else if target == auxiliary?.id { snapshot.auxiliary?.documentID = documentID }
        else { return }
        snapshot.activePaneID = target
    }

    @discardableResult public mutating func arrange(_ direction: SplitDirection) -> Bool {
        guard auxiliary == nil || self.direction != direction else { return false }
        remember()
        if auxiliary == nil {
            snapshot.auxiliary = EditorPane(documentID: activePane.documentID)
            snapshot.activePaneID = snapshot.auxiliary!.id
        }
        if self.direction.axis != direction.axis { snapshot.primaryFraction = 0.5 }
        snapshot.direction = direction
        return true
    }

    @discardableResult public mutating func closeAuxiliary() -> Bool {
        guard auxiliary != nil else { return false }
        remember(); snapshot.auxiliary = nil; snapshot.activePaneID = primary.id
        return true
    }

    public mutating func resize(_ ratio: Double) {
        guard auxiliary != nil, ratio.isFinite else { return }
        let firstFraction = min(0.85, max(0.15, ratio))
        snapshot.primaryFraction = direction.insertsFirst ? 1 - firstFraction : firstFraction
    }

    public mutating func undo() {
        if let previous = history.popLast() { snapshot = previous }
    }

    /// Fit the saved proportion to the current window without rewriting it.
    public func fittedRoot(in bounds: WorkspaceRect) -> WorkspaceNode {
        guard auxiliary != nil else { return root }
        let extent = direction.axis == .horizontal ? bounds.width : bounds.height
        let minimum = direction.axis == .horizontal ? 240.0 : 180.0
        let lower = min(0.5, minimum / max(1, extent - 6))
        return root(primaryFraction: min(1 - lower, max(lower, snapshot.primaryFraction)))
    }

    private func root(primaryFraction: Double) -> WorkspaceNode {
        guard let auxiliary else { return .pane(primary) }
        return .split(WorkspaceBranch(id: snapshot.splitID, axis: direction.axis,
            ratio: direction.insertsFirst ? 1 - primaryFraction : primaryFraction,
            first: .pane(direction.insertsFirst ? auxiliary : primary),
            second: .pane(direction.insertsFirst ? primary : auxiliary)))
    }

    private mutating func remember() {
        history.append(snapshot)
        if history.count > 32 { history.removeFirst(history.count - 32) }
    }
}
