import SwiftUI

public struct NovelSettingsView: View {
    @AppStorage("appearance") private var appearance = NovelAppearance.system.rawValue
    @AppStorage("editor.fontSize") private var fontSize = 18.0
    @AppStorage("editor.serif") private var serif = true
    public init() {}
    public var body: some View {
        Form {
            Picker("外观", selection: $appearance) { ForEach(NovelAppearance.allCases) { Text($0.title).tag($0.rawValue) } }
            Picker("正文字体", selection: $serif) { Text("宋体").tag(true); Text("系统字体").tag(false) }
            HStack { Text("正文字号"); Slider(value: $fontSize, in: 14...28, step: 1); Text("\(Int(fontSize))").monospacedDigit() }
        }.padding(24).frame(width: 380).preferredColorScheme((NovelAppearance(rawValue: appearance) ?? .system).colorScheme)
    }
}
