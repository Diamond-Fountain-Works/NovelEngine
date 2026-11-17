import SwiftUI
import AppKit

struct LibraryActions {
    let new: () -> Void
    let importProject: () -> Void
    let export: () -> Void
    let save: () -> Void
    let canEdit: Bool
    let enabled: Bool
}
private struct LibraryActionsKey: FocusedValueKey { typealias Value = LibraryActions }
extension FocusedValues {
    var libraryActions: LibraryActions? {
        get { self[LibraryActionsKey.self] }
        set { self[LibraryActionsKey.self] = newValue }
    }
}
struct LibraryCommands: Commands {
    @FocusedValue(\.libraryActions) private var actions
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("新建小说") { actions?.new() }.keyboardShortcut("n").disabled(actions?.enabled != true)
            Button("导入作品…") { actions?.importProject() }.keyboardShortcut("o").disabled(actions?.enabled != true)
        }
        CommandGroup(replacing: .saveItem) {
            Button("保存") { actions?.save() }.keyboardShortcut("s").disabled(actions?.canEdit != true)
            Button("导出作品…") { actions?.export() }.keyboardShortcut("s", modifiers: [.command, .shift]).disabled(actions?.canEdit != true)
        }
        CommandGroup(after: .saveItem) {
            Divider()
            Button("关闭窗口") { NSApp.keyWindow?.performClose(nil) }.keyboardShortcut("w")
        }
    }
}
