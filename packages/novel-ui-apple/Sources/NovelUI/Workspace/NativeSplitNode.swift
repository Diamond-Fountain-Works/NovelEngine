#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

struct NativeSplitNode: View {
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette

    var body: some View {
        GeometryReader { geometry in
            let bounds = WorkspaceRect(width: geometry.size.width, height: geometry.size.height)
            let frames = session.layout.fittedRoot(in: bounds).frames(in: bounds)
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
                            actions: { _ in [] })
                            .frame(width: placement.rect.width, height: placement.rect.height)
                            .position(x: placement.rect.x + placement.rect.width / 2, y: placement.rect.y + placement.rect.height / 2)
                    }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear { session.updateWorkspaceSize(geometry.size) }
                .onChange(of: geometry.size) { session.updateWorkspaceSize($0) }
        }
    }
}
#endif
