import Foundation

public struct DividerPlacement: Sendable, Identifiable {
    public let id: UUID
    public let axis: SplitAxis
    public let ratio: Double
    public let rect: WorkspaceRect
    public let extent: Double
}

public struct WorkspaceFrames: Sendable {
    public var panes: [PanePlacement] = []
    public var dividers: [DividerPlacement] = []
}

extension WorkspaceNode {
    /// Include the divider thickness, while keeping the UI's list of pane IDs stable.
    public func frames(in bounds: WorkspaceRect, divider: Double = 6) -> WorkspaceFrames {
        switch self {
        case .pane(let pane): return WorkspaceFrames(panes: [PanePlacement(pane: pane, rect: bounds)])
        case .split(let branch):
            let horizontal = branch.axis == .horizontal
            let thickness = min(max(0, divider), max(0, horizontal ? bounds.width : bounds.height))
            let extent = max(0, (horizontal ? bounds.width : bounds.height) - thickness)
            let first: WorkspaceRect, second: WorkspaceRect, edge: WorkspaceRect
            if horizontal {
                first = WorkspaceRect(x: bounds.x, y: bounds.y, width: extent * branch.ratio, height: bounds.height)
                edge = WorkspaceRect(x: first.maxX, y: bounds.y, width: thickness, height: bounds.height)
                second = WorkspaceRect(x: edge.maxX, y: bounds.y, width: extent * (1 - branch.ratio), height: bounds.height)
            } else {
                first = WorkspaceRect(x: bounds.x, y: bounds.y, width: bounds.width, height: extent * branch.ratio)
                edge = WorkspaceRect(x: bounds.x, y: first.maxY, width: bounds.width, height: thickness)
                second = WorkspaceRect(x: bounds.x, y: edge.maxY, width: bounds.width, height: extent * (1 - branch.ratio))
            }
            let a = branch.first.frames(in: first, divider: divider)
            let b = branch.second.frames(in: second, divider: divider)
            return WorkspaceFrames(panes: a.panes + b.panes,
                dividers: a.dividers + [DividerPlacement(id: branch.id, axis: branch.axis, ratio: branch.ratio, rect: edge, extent: extent)] + b.dividers)
        }
    }
}
