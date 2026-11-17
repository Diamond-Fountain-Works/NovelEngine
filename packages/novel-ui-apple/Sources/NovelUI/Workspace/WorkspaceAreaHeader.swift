#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

struct WorkspaceAreaHeader: View {
    let pane: EditorPane
    let project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let palette: NovelPalette
    let typography: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            EditorDocumentPicker(project: project, pane: pane, session: session)
                .frame(maxWidth: .infinity, alignment: .leading)
            if session.layout.auxiliary?.id == pane.id {
                Button { session.close(pane.id) } label: {
                    Image(systemName: "xmark").font(.system(size: 10)).frame(width: 24, height: 24)
                }.help("关闭分栏").accessibilityLabel("关闭分栏")
                    .accessibilityIdentifier("pane.close.\(pane.id.uuidString)")
            }
        }
        .font(.caption).buttonStyle(.plain).padding(.horizontal, 12).frame(height: 36)
        .background(palette.chrome)
        .overlay(alignment: .bottom) { palette.rule.frame(height: 1) }
        .overlay(alignment: .top) {
            if session.layout.activePaneID == pane.id { palette.accent.frame(height: 2) }
        }
        .contextMenu { AreaContextActions(pane: pane, session: session, typography: typography) }
    }
}
#endif
