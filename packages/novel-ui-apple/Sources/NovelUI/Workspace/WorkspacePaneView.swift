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

    private var title: String {
        pane.content == .editor ? (project.document(pane.documentID)?.title.nilIfEmpty ?? "未命名") : pane.content.title
    }
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                WorkspaceAreaHeader(pane: pane, title: title, session: session, palette: palette, typography: { showsTypography = true })
                    .popover(isPresented: $showsTypography, arrowEdge: .top) {
                        EditorTypographyControls().frame(width: 260).padding(20)
                    }
                switch pane.content {
                case .editor:
                    EditorPaneView(pane: pane, project: $project, session: session, bindings: bindings, palette: palette)
                case .manuscript:
                    ManuscriptSidebar(project: $project, session: session, bindings: bindings, palette: palette, pane: pane)
                case .inspector:
                    DocumentInspector(project: $project, session: session, bindings: bindings, palette: palette, paneID: pane.id)
                }
            }
            .background(palette.paper).foregroundStyle(palette.text)
            .onAppear { session.updateSize(geometry.size, for: pane.id) }
            .onChange(of: geometry.size) { session.updateSize($0, for: pane.id) }
        }
        .accessibilityElement(children: .contain).accessibilityLabel("\(pane.content.title)区域")
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
private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }
#endif
