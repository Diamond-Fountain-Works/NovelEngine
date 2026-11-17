#if os(macOS)
import SwiftUI
import NovelDomain
import NovelApplication

struct ReferenceDetailsEditor: View {
    let document: WritingDocument
    let project: NovelProject
    let bindings: ProjectBindings
    let palette: NovelPalette
    let open: (UUID) -> Void
    let done: () -> Void
    @State private var tags = ""
    private enum Field { case code, time, tags }
    @FocusState private var focused: Field?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(document.kind.title)属性").font(.headline)
                Spacer()
                Button("完成") { saveTags(); done() }.keyboardShortcut(.defaultAction).accessibilityIdentifier("reference.done")
            }.padding(16)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LabeledContent("标识") {
                        TextField("", text: bindings.reference(\.code, documentID: document.id))
                            .focused($focused, equals: .code).accessibilityLabel("标识").accessibilityIdentifier("reference.code")
                    }
                    if document.kind == .event {
                        LabeledContent("故事时间") {
                            TextField("", text: bindings.reference(\.timeAnchor, documentID: document.id))
                                .focused($focused, equals: .time).accessibilityLabel("故事时间").accessibilityIdentifier("reference.time")
                        }
                    }
                    LabeledContent("标签") {
                        TextField("逗号分隔", text: $tags).onSubmit(saveTags).focused($focused, equals: .tags)
                            .accessibilityLabel("标签，用逗号分隔").accessibilityIdentifier("reference.tags")
                    }
                    if let parentID = document.parentID, let parent = project.document(parentID) {
                        Text("上级文档").font(.caption).foregroundStyle(palette.secondary)
                        Button(parent.title.isEmpty ? "未命名" : parent.title) { open(parentID) }.buttonStyle(.link)
                    }
                    if document.kind == .event {
                        ReferenceLinksEditor(title: "参与人物", candidates: project.documents.filter { $0.kind == .character && $0.parentID == nil },
                            selected: bindings.reference(\.participantIDs, documentID: document.id), open: open)
                        ReferenceLinksEditor(title: "前置事件", candidates: project.documents.filter { $0.kind == .event && $0.id != document.id },
                            selected: bindings.reference(\.prerequisiteIDs, documentID: document.id),
                            allowedIDs: ProjectLibrary.availablePrerequisiteIDs(for: document.id, in: project), open: open)
                    }
                    ReferenceLinksEditor(title: "关联资料", candidates: project.documents.filter { $0.id != document.id },
                        selected: bindings.reference(\.relatedIDs, documentID: document.id), open: open)
                    let incoming = ProjectLibrary.incomingReferences(to: document.id, in: project)
                    if !incoming.isEmpty {
                        Divider()
                        Text("引用此文档").font(.caption).foregroundStyle(palette.secondary)
                        ForEach(incoming) { source in Button(source.title.isEmpty ? "未命名" : source.title) { open(source.id) }.buttonStyle(.link) }
                    }
                }.textFieldStyle(.roundedBorder).padding(16)
            }
        }.frame(width: 420, height: 430).controlSize(.regular).background(palette.paper).foregroundStyle(palette.text)
            .defaultFocus($focused, .code)
            .onAppear { tags = document.reference?.tags.joined(separator: ", ") ?? ""; focused = .code }
            .onDisappear(perform: saveTags)
    }
    private func saveTags() {
        var seen = Set<String>()
        let values = tags.components(separatedBy: CharacterSet(charactersIn: ",，"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty && seen.insert($0).inserted }
        bindings.reference(\.tags, documentID: document.id).wrappedValue = values
    }
}
#endif
