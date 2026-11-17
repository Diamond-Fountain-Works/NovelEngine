#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

struct EditorPaneView: View {
    let pane: EditorPane
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette
    @AppStorage("editor.fontSize") private var fontSize = 18.0
    @AppStorage("editor.serif") private var serif = true

    var body: some View {
        GeometryReader { geometry in
            if let document = project.document(pane.documentID) {
                VStack(spacing: 0) {
                    VStack(spacing: 14) {
                        TextField("未命名\(document.kind.title)", text: bindings.field(\.title, documentID: document.id))
                            .font(.system(size: geometry.size.height < 360 ? 22 : 27, weight: .semibold, design: .serif))
                            .textFieldStyle(.plain).accessibilityIdentifier("editor.title")
                            .simultaneousGesture(TapGesture().onEnded { session.activate(pane.id) })
                        if document.kind.isReference {
                            ReferenceSummaryBar(document: document, project: project, bindings: bindings, palette: palette,
                                prepareInput: { session.prepareAuxiliaryInput(in: pane.id) }) { id in
                                if let linked = project.document(id) { session.open(id, kind: linked.kind, in: pane.id) }
                            }
                        }
                        palette.rule.frame(height: 1)
                    }.frame(maxWidth: 680).padding(.horizontal, 24).padding(.top, geometry.size.height < 360 ? 12 : 30).padding(.bottom, 8)
                    MacTextEditor(text: bindings.field(\.body, documentID: document.id), fontSize: fontSize, serif: serif, palette: palette,
                                  focusToken: session.focusRequest?.paneID == pane.id ? session.focusRequest?.token : nil) { session.activate(pane.id) }
                        .id(document.id)
                        .overlay(alignment: .topLeading) {
                            if document.body.isEmpty {
                                Text("开始输入正文…").font(.system(size: fontSize, design: serif ? .serif : .default))
                                    .foregroundStyle(palette.secondary).padding(.top, 18).padding(.leading, max(24, (geometry.size.width - 680) / 2)).allowsHitTesting(false).accessibilityHidden(true)
                            }
                        }
                    HStack {
                        Text("\(document.statistics.characters) 字")
                        Text("\(document.statistics.paragraphs) 段")
                        Spacer()
                    }.font(.caption2).foregroundStyle(palette.secondary).padding(.horizontal, 17).frame(height: 28)
                        .overlay(alignment: .top) { palette.rule.frame(height: 1) }
                }.background(palette.paper).foregroundStyle(palette.text)
            }
        }.accessibilityElement(children: .contain).accessibilityLabel("编辑分栏")
    }
}
#endif
