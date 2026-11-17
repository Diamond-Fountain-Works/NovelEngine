#if os(macOS)
import SwiftUI
import NovelDomain

struct ManuscriptSidebar: View {
    @Binding var project: NovelProject
    @ObservedObject var session: WorkspaceSession
    let bindings: ProjectBindings
    let palette: NovelPalette
    private enum Field { case projectTitle, search }
    @FocusState private var editing: Field?
    private var browser: LibraryBrowserState { session.browser }
    private var documents: [WritingDocument] { project.documents.filter { $0.kind == browser.kind } }

    var body: some View {
        HStack(spacing: 0) {
            LibraryModuleRail(selection: browser.section, palette: palette, paneID: project.id) { session.setSection($0) }
            palette.rule.frame(width: 1)
            VStack(spacing: 10) {
                TextField("小说名称", text: bindings.projectTitle).textFieldStyle(.plain).font(.headline)
                    .accessibilityIdentifier("project.title").focused($editing, equals: .projectTitle)
                    .padding(.horizontal, 12).padding(.top, 16)
                if browser.section == .manuscript {
                    Picker("文档类型", selection: Binding(get: { browser.manuscriptKind }, set: { session.setManuscriptKind($0) })) {
                        Text("章节").tag(WritingKind.chapter); Text("笔记").tag(WritingKind.note)
                    }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 10)
                } else {
                    Text(browser.section.title).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12)
                }
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(palette.secondary)
                    TextField("搜索\(browser.kind.title)", text: Binding(get: { browser.search }, set: { session.setSearch($0) }))
                        .textFieldStyle(.plain).accessibilityIdentifier("sidebar.search").focused($editing, equals: .search)
                    Button { session.setSearch(""); session.open(bindings.add(browser.kind), kind: browser.kind) } label: { Image(systemName: "plus") }
                        .buttonStyle(.plain).help("新建\(browser.kind.title)").accessibilityLabel("新建\(browser.kind.title)").accessibilityIdentifier("sidebar.add")
                }.padding(8).background(palette.paper, in: RoundedRectangle(cornerRadius: 6)).padding(.horizontal, 10)
                LibraryDocumentList(project: $project, session: session, bindings: bindings, palette: palette)
                HStack(spacing: 4) {
                    Text("\(documents.count) 项")
                    Spacer(minLength: 2)
                    Text("\(documents.reduce(0) { $0 + $1.statistics.characters }) 字")
                }.font(.caption2).foregroundStyle(palette.secondary).padding(10).overlay(alignment: .top) { palette.rule.frame(height: 1) }
            }.frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(palette.sidebar)
        .onChange(of: editing) { if $0 != nil { session.prepareLibraryInput() } }
        .accessibilityElement(children: .contain).accessibilityLabel("资料导航")
    }
}
#endif
