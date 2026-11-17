#if os(macOS)
import SwiftUI
import NovelDomain

struct DocumentInspector: View {
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette
    let paneID: UUID
    @FocusState private var editing: Bool
    private var focusToken: UUID? { session.focusRequest?.paneID == paneID ? session.focusRequest?.token : nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let document = project.document(session.selectedDocumentID) {
                Text(document.title.isEmpty ? "未命名" : document.title).font(.headline).lineLimit(2)
                LabeledContent("字数", value: String(document.statistics.characters))
                LabeledContent("段落", value: String(document.statistics.paragraphs))
                Divider()
                Text("摘要").font(.caption).foregroundStyle(palette.secondary)
                TextEditor(text: bindings.field(\.synopsis, documentID: document.id)).font(.body)
                    .scrollContentBackground(.hidden).frame(minHeight: 80).focused($editing)
                    .accessibilityIdentifier("document.synopsis")
            }
            Spacer(minLength: 0)
        }
        .padding(18).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(palette.sidebar)
        .contentShape(Rectangle()).simultaneousGesture(TapGesture().onEnded { session.activate(paneID) })
        .onChange(of: editing) { if $0 { session.activate(paneID) } }
        .onAppear { if focusToken != nil { editing = true } }
        .onChange(of: focusToken) { if $0 != nil { editing = true } }
    }
}
#endif
