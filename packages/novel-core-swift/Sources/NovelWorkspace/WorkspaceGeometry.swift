import Foundation

public struct WorkspaceRect: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
    public init(x: Double = 0, y: Double = 0, width: Double = 1, height: Double = 1) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    func union(_ other: Self) -> Self {
        Self(x: min(x, other.x), y: min(y, other.y), width: max(maxX, other.maxX) - min(x, other.x), height: max(maxY, other.maxY) - min(y, other.y))
    }
    func matches(_ other: Self) -> Bool {
        near(x, other.x) && near(y, other.y) && near(width, other.width) && near(height, other.height)
    }
}

public struct PanePlacement: Equatable, Sendable {
    public let pane: EditorPane
    public let rect: WorkspaceRect
}

public struct PaneJoin: Equatable, Sendable {
    public let sourceID: UUID
    public let targetID: UUID
    public let direction: SplitDirection
    public var title: String {
        switch direction { case .left: "Join Left"; case .right: "Join Right"; case .up: "Join Up"; case .down: "Join Down" }
    }
}

private func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.0000001 }

extension WorkspaceNode {
    func frame(of nodeID: UUID, in rect: WorkspaceRect = WorkspaceRect()) -> WorkspaceRect? {
        if id == nodeID { return rect }
        guard case .split(let branch) = self else { return nil }
        let first: WorkspaceRect, second: WorkspaceRect
        if branch.axis == .horizontal {
            first = WorkspaceRect(x: rect.x, y: rect.y, width: rect.width * branch.ratio, height: rect.height)
            second = WorkspaceRect(x: first.maxX, y: rect.y, width: rect.width - first.width, height: rect.height)
        } else {
            first = WorkspaceRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height * branch.ratio)
            second = WorkspaceRect(x: rect.x, y: first.maxY, width: rect.width, height: rect.height - first.height)
        }
        return branch.first.frame(of: nodeID, in: first) ?? branch.second.frame(of: nodeID, in: second)
    }
    func boundarySource(_ branchID: UUID, fraction: Double) -> EditorPane? {
        guard fraction.isFinite, case .split(let branch) = node(branchID), let rect = frame(of: branchID) else { return nil }
        let fraction = min(0.9999999, max(0.0000001, fraction))
        return placements().first { item in
            if branch.axis == .horizontal {
                let y = rect.y + rect.height * fraction
                return near(item.rect.maxX, rect.x + rect.width * branch.ratio) && y >= item.rect.y && y < item.rect.maxY
            }
            let x = rect.x + rect.width * fraction
            return near(item.rect.maxY, rect.y + rect.height * branch.ratio) && x >= item.rect.x && x < item.rect.maxX
        }?.pane
    }
    func boundaryJoins(_ branchID: UUID, fraction: Double) -> [PaneJoin] {
        guard case .split(let branch) = node(branchID), let source = boundarySource(branchID, fraction: fraction) else { return [] }
        let forward: SplitDirection = branch.axis == .horizontal ? .right : .down
        let backward: SplitDirection = branch.axis == .horizontal ? .left : .up
        guard let join = joinTarget(from: source.id, toward: forward), joining(join) != nil,
              let reverse = joinTarget(from: join.targetID, toward: backward), joining(reverse) != nil else { return [] }
        return [join, reverse]
    }
    public func placements(in rect: WorkspaceRect = WorkspaceRect()) -> [PanePlacement] {
        switch self {
        case .pane(let pane): return [PanePlacement(pane: pane, rect: rect)]
        case .split(let branch):
            let first: WorkspaceRect, second: WorkspaceRect
            if branch.axis == .horizontal {
                let width = rect.width * branch.ratio
                first = WorkspaceRect(x: rect.x, y: rect.y, width: width, height: rect.height)
                second = WorkspaceRect(x: rect.x + width, y: rect.y, width: rect.width - width, height: rect.height)
            } else {
                let height = rect.height * branch.ratio
                first = WorkspaceRect(x: rect.x, y: rect.y, width: rect.width, height: height)
                second = WorkspaceRect(x: rect.x, y: rect.y + height, width: rect.width, height: rect.height - height)
            }
            return branch.first.placements(in: first) + branch.second.placements(in: second)
        }
    }

    func joinTarget(from sourceID: UUID, toward direction: SplitDirection) -> PaneJoin? {
        let all = placements()
        guard let source = all.first(where: { $0.pane.id == sourceID }) else { return nil }
        let a = source.rect
        guard let target = all.first(where: { candidate in
            guard candidate.pane.id != sourceID else { return false }
            let b = candidate.rect
            switch direction {
            case .left: return near(a.x, b.maxX) && near(a.y, b.y) && near(a.height, b.height)
            case .right: return near(a.maxX, b.x) && near(a.y, b.y) && near(a.height, b.height)
            case .up: return near(a.y, b.maxY) && near(a.x, b.x) && near(a.width, b.width)
            case .down: return near(a.maxY, b.y) && near(a.x, b.x) && near(a.width, b.width)
            }
        }) else { return nil }
        return PaneJoin(sourceID: sourceID, targetID: target.pane.id, direction: direction)
    }

    func joining(_ join: PaneJoin) -> Self? {
        guard joinTarget(from: join.sourceID, toward: join.direction) == join else { return nil }
        guard let source = panes.first(where: { $0.id == join.sourceID }) else { return nil }
        // The common case keeps every unrelated branch and view identity unchanged.
        if let parent = parent(of: join.sourceID), parent.first.panes.count == 1, parent.second.panes.count == 1,
           parent.first.panes.contains(where: { $0.id == join.targetID }) || parent.second.panes.contains(where: { $0.id == join.targetID }) {
            return replacing(parent.id, with: .pane(source))
        }
        let all = placements()
        guard let a = all.first(where: { $0.pane.id == join.sourceID }), let b = all.first(where: { $0.pane.id == join.targetID }) else { return nil }
        let merged = all.filter { $0.pane.id != join.targetID }.map {
            $0.pane.id == join.sourceID ? PanePlacement(pane: $0.pane, rect: a.rect.union(b.rect)) : $0
        }
        return Self.retile(merged, bounds: WorkspaceRect())
    }

    /// Retile a rectangular union, preserving all other pane IDs and their geometry.
    /// If the floorplan cannot be represented by this split tree, no join is offered.
    private static func retile(_ tiles: [PanePlacement], bounds: WorkspaceRect) -> Self? {
        if tiles.count == 1 { return tiles[0].rect.matches(bounds) ? .pane(tiles[0].pane) : nil }
        for axis in [SplitAxis.horizontal, .vertical] {
            let cuts = Set(tiles.map { axis == .horizontal ? $0.rect.maxX : $0.rect.maxY }).sorted()
            let start = axis == .horizontal ? bounds.x : bounds.y
            let length = axis == .horizontal ? bounds.width : bounds.height
            for cut in cuts {
                let ratio = (cut - start) / length
                guard (0.15...0.85).contains(ratio) else { continue }
                let first = tiles.filter { (axis == .horizontal ? $0.rect.maxX : $0.rect.maxY) <= cut + 0.0000001 }
                let second = tiles.filter { (axis == .horizontal ? $0.rect.x : $0.rect.y) >= cut - 0.0000001 }
                guard !first.isEmpty, !second.isEmpty, first.count + second.count == tiles.count else { continue }
                let firstRect: WorkspaceRect, secondRect: WorkspaceRect
                if axis == .horizontal {
                    firstRect = WorkspaceRect(x: bounds.x, y: bounds.y, width: cut - bounds.x, height: bounds.height)
                    secondRect = WorkspaceRect(x: cut, y: bounds.y, width: bounds.maxX - cut, height: bounds.height)
                } else {
                    firstRect = WorkspaceRect(x: bounds.x, y: bounds.y, width: bounds.width, height: cut - bounds.y)
                    secondRect = WorkspaceRect(x: bounds.x, y: cut, width: bounds.width, height: bounds.maxY - cut)
                }
                if let left = retile(first, bounds: firstRect), let right = retile(second, bounds: secondRect) {
                    return .split(WorkspaceBranch(axis: axis, ratio: ratio, first: left, second: right))
                }
            }
        }
        return nil
    }

    func removingPane(_ paneID: UUID) -> Self? {
        switch self {
        case .pane(let pane): return pane.id == paneID ? nil : self
        case .split(var branch):
            let first = branch.first.removingPane(paneID), second = branch.second.removingPane(paneID)
            guard let first else { return second }
            guard let second else { return first }
            branch.first = first; branch.second = second
            return .split(branch)
        }
    }
}
