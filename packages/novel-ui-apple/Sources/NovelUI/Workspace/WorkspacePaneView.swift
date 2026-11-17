#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

struct WorkspacePaneView: View {
    let pane: EditorPane
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette
    @State private var showsTypography = false

    var body: some View {
        VStack(spacing: 0) {
            WorkspaceAreaHeader(pane: pane, project: project, session: session, palette: palette,
                typography: { session.prepareAuxiliaryInput(in: pane.id); showsTypography = true })
                .popover(isPresented: $showsTypography, arrowEdge: .top) {
                    EditorTypographyControls().frame(width: 260).padding(20)
                }
            EditorPaneView(pane: pane, project: $project, session: session, bindings: bindings, palette: palette)
        }.background(palette.paper).foregroundStyle(palette.text)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(session.layout.primary.id == pane.id ? "主编辑区" : "辅助编辑区")
    }
}

private struct EditorTypographyControls: View {
    @AppStorage("editor.fontSize") private var fontSize = 18.0
    @AppStorage("editor.serif") private var serif = true
    var body: some View {
        Form {
            Picker("字体", selection: $serif) { Text("宋体").tag(true); Text("系统字体").tag(false) }.pickerStyle(.segmented)
            HStack { Text("字号"); Slider(value: $fontSize, in: 14...28, step: 1); Text("\(Int(fontSize))").monospacedDigit() }
        }
    }
}
#endif
