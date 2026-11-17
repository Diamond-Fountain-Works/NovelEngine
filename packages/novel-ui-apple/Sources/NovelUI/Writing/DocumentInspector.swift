#if os(macOS)
import SwiftUI
import NovelDomain

struct DocumentInspector: View {
    @Binding var project: NovelProject
    let bindings: ProjectBindings
    let palette: NovelPalette
    let documentID: UUID
    let done: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("文档信息").font(.headline)
                    if let document = project.document(documentID) {
                        Text(document.title.isEmpty ? "未命名" : document.title).lineLimit(2)
                        LabeledContent("字数", value: String(document.statistics.characters))
                        LabeledContent("段落", value: String(document.statistics.paragraphs))
                        Divider()
                        Text("摘要").font(.caption).foregroundStyle(palette.secondary)
                        TextEditor(text: bindings.field(\.synopsis, documentID: document.id)).font(.body)
                            .scrollContentBackground(.hidden).frame(minHeight: 120)
                            .accessibilityIdentifier("document.synopsis")
                    }
                }.padding(20)
            }
            HStack { Spacer(); Button("完成", action: done).keyboardShortcut(.defaultAction).accessibilityIdentifier("document.info.done") }
                .padding(16).overlay(alignment: .top) { palette.rule.frame(height: 1) }
        }.frame(width: 380, height: 360).background(palette.paper).foregroundStyle(palette.text)
    }
}
#endif
