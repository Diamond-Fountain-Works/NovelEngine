#if os(macOS)
import SwiftUI
import NovelWorkspace

struct AreaContextActions: View {
    let pane: EditorPane
    @ObservedObject var session: WorkspaceSession
    var typography: (() -> Void)? = nil

    var body: some View {
        Button("文档信息") { session.inspect(pane.id) }
        if let typography { Button("排版", action: typography) }
        Button(session.focused ? "退出专注" : "专注") { session.toggleFocus(in: pane.id) }
    }
}
#endif
