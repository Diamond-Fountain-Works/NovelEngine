#if os(macOS)
import SwiftUI
import NovelWorkspace

struct AreaContextActions: View {
    let pane: EditorPane
    @ObservedObject var session: WorkspaceSession
    var typography: (() -> Void)? = nil

    var body: some View {
        SplitMenu(session: session, paneID: pane.id)
        if !session.layout.joinOptions(from: pane.id).isEmpty {
            Divider()
            JoinMenu(session: session, paneID: pane.id)
        }
        Divider()
        if let typography { Button("排版", action: typography) }
        Button(session.focused ? "退出专注" : "专注") {
            session.toggleFocus(in: pane.id)
        }
        Button("关闭区域") { session.close(pane.id) }
            .disabled(session.layout.root.panes.count == 1)
    }
}
#endif
