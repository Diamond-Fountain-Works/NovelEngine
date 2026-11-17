import AppKit

@MainActor final class NovelAppDelegate: NSObject, NSApplicationDelegate {
    weak var library: LibraryController?
    private var terminating = false
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let library else { return .terminateNow }
        guard !terminating else { return .terminateLater }
        terminating = true
        Task {
            do { try await library.flushAll(); sender.reply(toApplicationShouldTerminate: true) }
            catch {
                terminating = false
                sender.reply(toApplicationShouldTerminate: false)
                let alert = NSAlert(); alert.messageText = "作品尚未保存"; alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: "返回编辑"); alert.runModal()
            }
        }
        return .terminateLater
    }
}
