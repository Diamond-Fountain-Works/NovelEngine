#if os(macOS)
import SwiftUI
import NovelDomain
import NovelApplication
import NovelWorkspace

struct ManuscriptSidebar: View {
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette
    let pane: EditorPane
    private enum Field { case projectTitle, search }
    @FocusState private var editing: Field?
    private var focusToken: UUID? { session.focusRequest?.paneID == pane.id ? session.focusRequest?.token : nil }

    private var documents: [WritingDocument] {
        project.documents.filter { $0.kind == session.kind && (session.search.isEmpty || $0.title.localizedCaseInsensitiveContains(session.search)) }
    }
    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 9) {
                TextField("小说名称", text: bindings.projectTitle).textFieldStyle(.plain).font(.title3.bold()).accessibilityIdentifier("project.title").focused($editing, equals: .projectTitle)
            }.padding(.horizontal, 18).padding(.top, 20)
            Picker("文档类型", selection: $session.kind) {
                ForEach(WritingKind.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 13)
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(palette.secondary)
                TextField("搜索\(session.kind.title)", text: $session.search).textFieldStyle(.plain).accessibilityIdentifier("sidebar.search").focused($editing, equals: .search)
                Button { let id = bindings.add(session.kind); session.open(id, kind: session.kind) } label: { Image(systemName: "plus") }
                    .buttonStyle(.plain).help("新建\(session.kind.title)").accessibilityIdentifier("sidebar.add")
            }.padding(9).background(palette.paper, in: RoundedRectangle(cornerRadius: 6)).padding(.horizontal, 13)
            List(selection: Binding(get: { Optional(session.selectedDocumentID) }, set: { if let id = $0 { session.open(id, kind: session.kind) } })) {
                ForEach(documents) { document in
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(document.title.isEmpty ? "未命名" : document.title).lineLimit(1)
                            Text("\(document.statistics.characters) 字").font(.caption2).foregroundStyle(.secondary)
                        }.padding(.vertical, 4)
                    } icon: { Image(systemName: document.kind == .chapter ? "doc.text" : "note.text") }
                        .tag(document.id).accessibilityIdentifier("document.\(document.id.uuidString)")
                }.onMove(perform: move).moveDisabled(!session.search.isEmpty)
                if documents.isEmpty { Text(session.search.isEmpty ? "暂无\(session.kind.title)" : "没有匹配结果").foregroundStyle(palette.secondary) }
            }.listStyle(.sidebar).scrollContentBackground(.hidden)
            HStack {
                Text("\(project.documents.filter { $0.kind == .chapter }.count) 章")
                Spacer()
                Text("\(project.statistics.characters) 字")
            }.font(.caption2).foregroundStyle(palette.secondary).padding(13).overlay(alignment: .top) { palette.rule.frame(height: 1) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(palette.sidebar)
        .contentShape(Rectangle()).simultaneousGesture(TapGesture().onEnded { session.activate(pane.id) })
        .onChange(of: editing) { if $0 != nil { session.activate(pane.id) } }
        .onAppear { if focusToken != nil { editing = .search } }
        .onChange(of: focusToken) { if $0 != nil { editing = .search } }
        .contextMenu { AreaContextActions(pane: pane, session: session) }
    }
    private func move(from source: IndexSet, to destination: Int) {
        var ordered = documents; ordered.move(fromOffsets: source, toOffset: destination)
        var iterator = ordered.makeIterator()
        let ids = project.documents.map { $0.kind == session.kind ? iterator.next()!.id : $0.id }
        var changed = project
        do { try ProjectEditingService().reorder(ids, in: &changed); project = changed }
        catch { bindings.reportError(error) }
    }
}
#endif
