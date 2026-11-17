#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

struct NativeSplitNode: View {
    let node: WorkspaceNode
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette

    var body: some View {
        GeometryReader { geometry in
            let bounds = WorkspaceRect(width: geometry.size.width, height: geometry.size.height)
            let frames = node.frames(in: bounds)
            ZStack(alignment: .topLeading) {
                ForEach(frames.panes, id: \.pane.id) { placement in
                    let visible = !session.focused || placement.pane.id == session.layout.activePaneID
                    let rect = session.focused ? bounds : placement.rect
                    WorkspacePaneView(pane: placement.pane, project: $project, session: session, bindings: bindings, palette: palette)
                        .frame(width: visible ? rect.width : 0, height: visible ? rect.height : 0)
                        .clipped().position(x: rect.x + rect.width / 2, y: rect.y + rect.height / 2)
                        .opacity(visible ? 1 : 0).allowsHitTesting(visible).accessibilityHidden(!visible)
                }
                if !session.focused {
                    ForEach(frames.dividers) { placement in
                        AreaDivider(axis: placement.axis, ratio: placement.ratio, extent: placement.extent,
                            identifier: "workspace.divider.\(placement.id.uuidString)", palette: palette,
                            resize: { session.resize(placement.id, ratio: $0) },
                            actions: { menuActions(branchID: placement.id, fraction: $0) })
                            .frame(width: placement.rect.width, height: placement.rect.height)
                            .position(x: placement.rect.x + placement.rect.width / 2, y: placement.rect.y + placement.rect.height / 2)
                    }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    private func menuActions(branchID: UUID, fraction: Double) -> [AreaDividerAction] {
        guard let source = session.layout.boundarySource(branchID, fraction: fraction) else { return [] }
        var items = SplitDirection.allCases.map { direction in
            AreaDividerAction(title: direction.title, enabled: session.canSplit(direction, in: source.id), perform: { session.split(direction, in: source.id) })
        }
        let joins = session.layout.boundaryJoins(branchID, fraction: fraction)
        if !joins.isEmpty {
            items.append(AreaDividerAction(title: "", enabled: false, perform: {}))
            items += joins.map { join in
                AreaDividerAction(title: join.title, enabled: true, perform: { session.join(from: join.sourceID, toward: join.direction) })
            }
        }
        return items
    }
}
#endif
