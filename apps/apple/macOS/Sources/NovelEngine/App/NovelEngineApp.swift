import SwiftUI
import AppKit
import NovelUI

@main struct NovelEngineApp: App {
    init() { NovelBrandFonts.register() }
    var body: some Scene {
        DocumentGroup(newDocument: NovelFileDocument()) { configuration in
            NativeWorkspace(project: configuration.$document.project)
        }
        .defaultSize(width: 1240, height: 800)
        .windowToolbarStyle(.unifiedCompact)
        .commands { NovelWorkspaceCommands() }

        Settings { NovelSettingsView() }
    }
}
