import AppKit
import UniformTypeIdentifiers

@MainActor enum LibraryPanels {
    static func chooseProject() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "导入作品"; panel.prompt = "导入"
        panel.allowedContentTypes = [.novelEngineProject]
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }
    static func chooseCover() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "选择封面"; panel.prompt = "选择"
        panel.allowedContentTypes = [.image]; panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url : nil
    }
    static func exportDestination(title: String) -> URL? {
        let panel = NSSavePanel()
        panel.title = "导出作品"; panel.prompt = "导出"; panel.allowedContentTypes = [.novelEngineProject]
        panel.canCreateDirectories = true
        let name = title.components(separatedBy: CharacterSet(charactersIn: "/:\0")).joined(separator: " ")
        panel.nameFieldStringValue = (name.isEmpty ? "未命名小说" : name) + ".ne"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
