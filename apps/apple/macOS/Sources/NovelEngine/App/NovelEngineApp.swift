import SwiftUI
import AppKit
import NovelUI

@main struct NovelEngineApp: App {
    @StateObject private var library = LibraryController()
    @NSApplicationDelegateAdaptor(NovelAppDelegate.self) private var delegate
    init() { NovelBrandFonts.register() }
    var body: some Scene {
        WindowGroup("Novel Engine") {
            LibraryRootView(library: library).onAppear { delegate.library = library }
        }
        .defaultSize(width: 1240, height: 800)
        .windowToolbarStyle(.unifiedCompact)
        .commands { LibraryCommands(); NovelWorkspaceCommands() }

        Settings { NovelSettingsView() }
    }
}
