#if os(macOS)
import SwiftUI
import NovelWorkspace

struct WorkspaceToolbar: ToolbarContent {
    @ObservedObject var session: WorkspaceSession
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button { session.toggleManuscript() } label: { Image(systemName: "sidebar.left") }
                .help("资料栏").accessibilityLabel("资料栏").accessibilityIdentifier("workspace.manuscript")
        }
        ToolbarItemGroup(placement: .primaryAction) {
            ForEach(SplitDirection.allCases, id: \.self) { direction in
                Button { session.split(direction) } label: { SplitDirectionIcon(direction: direction) }
                    .disabled(!session.canSplit(direction))
                    .foregroundStyle(session.layout.auxiliary != nil && session.layout.direction == direction ? Color.accentColor : Color.primary)
                    .help(direction.title).accessibilityLabel(direction.title)
                    .accessibilityIdentifier("split.\(direction.rawValue)")
            }
            Menu {
                Button("撤销布局") { session.undo() }.disabled(!session.layout.canUndo)
                Button("恢复默认布局") { session.reset() }
            } label: { Image(systemName: "ellipsis") }
                .help("布局操作").accessibilityLabel("布局操作").accessibilityIdentifier("workspace.layout")
            Button { session.inspect() } label: { Image(systemName: "sidebar.right") }
                .help("文档信息").accessibilityLabel("文档信息").accessibilityIdentifier("workspace.inspector")
        }
    }
}
#endif
