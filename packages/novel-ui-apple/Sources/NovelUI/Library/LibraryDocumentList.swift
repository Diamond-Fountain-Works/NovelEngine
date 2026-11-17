#if os(macOS)
import SwiftUI
import NovelDomain
import NovelApplication

private struct LibraryRow: Identifiable {
    let id: UUID
    let depth: Int
    let hasChildren: Bool
}

struct LibraryDocumentList: View {
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette
    @State private var expanded = Set<UUID>()
    private var browser: LibraryBrowserState { session.browser }
    private var rows: [LibraryRow] {
        func flatten(_ nodes: [LibraryNode], depth: Int) -> [LibraryRow] {
            nodes.flatMap { node in
                [LibraryRow(id: node.id, depth: depth, hasChildren: !node.children.isEmpty)] +
                ((expanded.contains(node.id) || !browser.search.isEmpty) ? flatten(node.children, depth: depth + 1) : [])
            }
        }
        return flatten(ProjectLibrary.tree(in: project, kind: browser.kind, query: browser.search), depth: 0)
    }
    var body: some View {
        List(selection: Binding(get: { Optional(session.selectedDocumentID) }, set: { if let id = $0 { open(id) } })) {
            if browser.kind.isReference {
                ForEach(rows) { row in documentRow(row).tag(row.id) }
            } else {
                ForEach(rows) { row in documentRow(row).tag(row.id) }
                    .onMove(perform: move).moveDisabled(!browser.search.isEmpty)
            }
            if rows.isEmpty { Text(browser.search.isEmpty ? "暂无\(browser.kind.title)" : "没有匹配结果").foregroundStyle(palette.secondary) }
        }.listStyle(.sidebar).scrollContentBackground(.hidden)
    }

    @ViewBuilder private func documentRow(_ row: LibraryRow) -> some View {
        if let document = project.document(row.id) {
            HStack(spacing: 6) {
                if row.hasChildren {
                    Button { if !expanded.insert(row.id).inserted { expanded.remove(row.id) } } label: {
                        Image(systemName: expanded.contains(row.id) || !browser.search.isEmpty ? "chevron.down" : "chevron.right").font(.system(size: 9, weight: .semibold)).frame(width: 12, height: 22)
                    }.buttonStyle(.plain).accessibilityLabel("展开或收起\(document.title)").accessibilityIdentifier("library.expand.\(row.id.uuidString)")
                } else if row.depth > 0 { Color.clear.frame(width: 12, height: 1) }
                Image(systemName: document.kind.symbol).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(document.title.isEmpty ? "未命名" : document.title).lineLimit(1)
                    if let details = document.reference {
                        Text(details.code.isEmpty ? details.status.title : "\(details.code) · \(details.status.title)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    } else { Text("\(document.statistics.characters) 字").font(.caption2).foregroundStyle(.secondary) }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.leading, CGFloat(row.depth) * 10).padding(.vertical, 3).help(document.title)
                .accessibilityIdentifier("document.\(document.id.uuidString)")
                .contextMenu {
                    Button("打开") { open(document.id) }
                    if document.kind.isReference {
                        Button("新建子文档") {
                            if let id = bindings.addChild(to: document.id) {
                                expanded.insert(document.id); session.open(id, kind: document.kind)
                            }
                        }
                    }
                    Divider()
                    Button("上移") { bindings.move(document.id, by: -1) }.disabled(!canMove(document, by: -1))
                    Button("下移") { bindings.move(document.id, by: 1) }.disabled(!canMove(document, by: 1))
                }
        }
    }
    private func open(_ id: UUID) {
        if let document = project.document(id) { session.open(id, kind: document.kind) }
    }
    private func canMove(_ document: WritingDocument, by offset: Int) -> Bool {
        let siblings = project.documents.filter { $0.kind == document.kind && $0.parentID == document.parentID }
        guard let index = siblings.firstIndex(where: { $0.id == document.id }) else { return false }
        return siblings.indices.contains(index + offset)
    }
    private func move(from source: IndexSet, to destination: Int) {
        guard browser.search.isEmpty else { return }
        var documents = project.documents.filter { $0.kind == browser.kind }
        documents.move(fromOffsets: source, toOffset: destination)
        var iterator = documents.makeIterator()
        let ids = project.documents.map { $0.kind == browser.kind ? iterator.next()!.id : $0.id }
        var changed = project
        do { try ProjectEditingService().reorder(ids, in: &changed); project = changed }
        catch { bindings.reportError(error) }
    }
}
#endif
