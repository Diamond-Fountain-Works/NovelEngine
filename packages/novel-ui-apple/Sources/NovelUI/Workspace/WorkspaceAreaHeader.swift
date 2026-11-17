#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

struct WorkspaceAreaHeader: View {
    let pane: EditorPane
    let title: String
    @ObservedObject var session: WorkspaceSession
    let palette: NovelPalette
    let typography: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            Menu {
                ForEach(WorkspaceContent.allCases, id: \.self) { content in
                    Button { session.setContent(content, in: pane.id) } label: {
                        Label(content.title, systemImage: content.symbol)
                    }
                }
            } label: { Image(systemName: pane.content.symbol) }
                .menuStyle(.borderlessButton).fixedSize().help("区域类型")
                .accessibilityLabel("区域类型").accessibilityIdentifier("area.type.\(pane.id.uuidString)")
            Text(title).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle()).onTapGesture { session.activate(pane.id) }
            Button { session.split(.right, in: pane.id) } label: { Image(systemName: "rectangle.split.2x1") }
                .disabled(!session.canSplit(.right, in: pane.id)).help("向右分栏").accessibilityLabel("向右分栏")
                .accessibilityIdentifier("pane.split.\(pane.id.uuidString)")
            Button { session.split(.down, in: pane.id) } label: { Image(systemName: "rectangle.split.1x2") }
                .disabled(!session.canSplit(.down, in: pane.id)).help("向下分栏").accessibilityLabel("向下分栏")
                .accessibilityIdentifier("pane.split.down.\(pane.id.uuidString)")
            Menu { actions } label: { Image(systemName: "ellipsis") }
                .menuStyle(.borderlessButton).fixedSize().help("区域操作").accessibilityLabel("区域操作")
                .accessibilityIdentifier("pane.actions.\(pane.id.uuidString)")
            Button { session.close(pane.id) } label: { Image(systemName: "xmark").font(.system(size: 9)) }
                .disabled(session.layout.root.panes.count == 1).help("关闭区域").accessibilityLabel("关闭区域")
                .accessibilityIdentifier("pane.close.\(pane.id.uuidString)")
        }
        .font(.caption).buttonStyle(.plain).padding(.horizontal, 10).frame(height: 35)
        .background(palette.chrome)
        .overlay(alignment: .bottom) { palette.rule.frame(height: 1) }
        .overlay(alignment: .top) {
            if session.layout.activePaneID == pane.id { palette.accent.frame(height: 2) }
        }
        .contextMenu { actions }
    }
    private var actions: some View {
        AreaContextActions(pane: pane, session: session, typography: pane.content == .editor ? typography : nil)
    }
}
#endif
