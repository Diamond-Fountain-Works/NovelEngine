#if os(macOS)
import SwiftUI
import NovelWorkspace

struct NovelWorkspaceActions {
    var newChapter: () -> Void
    var newNote: () -> Void
    var split: (SplitDirection) -> Void
    var canSplit: (SplitDirection) -> Bool
    var undoLayout: () -> Void
    var canUndoLayout: Bool
    var resetLayout: () -> Void
}
private struct NovelActionsKey: FocusedValueKey { typealias Value = NovelWorkspaceActions }
extension FocusedValues {
    var novelActions: NovelWorkspaceActions? {
        get { self[NovelActionsKey.self] }
        set { self[NovelActionsKey.self] = newValue }
    }
}
public struct NovelWorkspaceCommands: Commands {
    @FocusedValue(\.novelActions) private var actions
    public init() {}
    public var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("新建章节") { actions?.newChapter() }.keyboardShortcut("n", modifiers: [.command, .shift]).disabled(actions == nil)
            Button("新建笔记") { actions?.newNote() }.keyboardShortcut("n", modifiers: [.command, .option]).disabled(actions == nil)
        }
        CommandMenu("分栏") {
            ForEach(SplitDirection.allCases, id: \.self) { direction in
                Button(direction.title) { actions?.split(direction) }.disabled(actions?.canSplit(direction) != true)
            }
            Divider()
            Button("撤销布局") { actions?.undoLayout() }.disabled(actions?.canUndoLayout != true)
            Button("恢复默认布局") { actions?.resetLayout() }.disabled(actions == nil)
        }
    }
}
#endif
