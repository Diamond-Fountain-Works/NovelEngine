#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

struct EditorDocumentPicker: View {
    let project: NovelProject
    let pane: EditorPane
    @ObservedObject var session: WorkspaceSession
    @State private var showsDocuments = false
    private var document: WritingDocument? { project.document(pane.documentID) }

    var body: some View {
        Button {
            session.prepareAuxiliaryInput(in: pane.id)
            showsDocuments = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: document?.kind.symbol ?? "doc.text")
                Text(document.map(title) ?? "未命名").lineLimit(1).truncationMode(.middle)
                Image(systemName: "chevron.down").font(.system(size: 9))
                Spacer(minLength: 0)
            }.contentShape(Rectangle())
        }
        .buttonStyle(.plain).help(document.map(title) ?? "选择文档")
        .accessibilityLabel("选择文档").accessibilityValue(document.map(title) ?? "未命名")
        .accessibilityIdentifier("editor.document.\(pane.id.uuidString)")
        .popover(isPresented: $showsDocuments, arrowEdge: .bottom) {
            EditorDocumentChoices(project: project, selectedID: pane.documentID) { selected in
                showsDocuments = false
                session.open(selected.id, kind: selected.kind, in: pane.id)
            }
        }
    }

    private func title(_ document: WritingDocument) -> String {
        document.title.isEmpty ? "未命名\(document.kind.title)" : document.title
    }
}

private struct EditorDocumentChoices: View {
    let project: NovelProject
    let selectedID: UUID
    let choose: (WritingDocument) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(WritingKind.allCases, id: \.self) { kind in
                    let documents = project.documents.filter { $0.kind == kind }
                    if !documents.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(kind.title, systemImage: kind.symbol).font(.caption).foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                            ForEach(documents) { document in
                                Button { choose(document) } label: {
                                    HStack(spacing: 8) {
                                        Text(document.title.isEmpty ? "未命名\(kind.title)" : document.title)
                                            .lineLimit(2).multilineTextAlignment(.leading)
                                        Spacer(minLength: 4)
                                        if document.id == selectedID { Image(systemName: "checkmark") }
                                    }.padding(.horizontal, 8).padding(.vertical, 7)
                                        .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityIdentifier("editor.choose.\(document.id.uuidString)")
                            }
                        }
                    }
                }
            }.padding(12)
        }.frame(width: 280, height: 340)
    }
}
#endif
