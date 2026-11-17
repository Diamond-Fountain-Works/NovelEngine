import SwiftUI
import NovelDomain
import NovelUI

struct BookshelfView: View {
    @ObservedObject var library: LibraryController
    let palette: NovelPalette
    let create: () -> Void
    let importProject: () -> Void
    let open: (UUID, Bool) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline) {
                    Text("我的作品").font(.system(size: 28, weight: .semibold, design: .serif))
                    Spacer()
                    Button("导入作品", action: importProject).accessibilityIdentifier("library.import")
                    Button(action: create) { Label("新建小说", systemImage: "plus") }
                        .buttonStyle(.borderedProminent).accessibilityIdentifier("library.new")
                }
                if let error = library.configurationError {
                    Text(error).foregroundStyle(.red)
                } else if library.items.isEmpty && library.unreadableIDs.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "books.vertical").font(.system(size: 38, weight: .ultraLight)).foregroundStyle(palette.secondary)
                        Text("暂无作品").foregroundStyle(palette.secondary)
                    }.frame(maxWidth: .infinity).padding(.vertical, 100)
                        .accessibilityIdentifier("library.empty")
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 28)], alignment: .leading, spacing: 32) {
                        ForEach(library.items, id: \.project.id) { item in
                            VStack(alignment: .leading, spacing: 10) {
                              Button { open(item.project.id, false) } label: {
                                VStack(alignment: .leading, spacing: 9) {
                                    ProjectCoverView(project: item.project, repository: library.repository, palette: palette).frame(height: 240)
                                    Text(item.project.title.isEmpty ? "未命名小说" : item.project.title).font(.headline).lineLimit(2)
                                    if !item.project.details.author.isEmpty { Text(item.project.details.author).font(.subheadline).lineLimit(1) }
                                    HStack {
                                        Text(item.project.details.status.title)
                                        Spacer(minLength: 4)
                                        Text("\(item.project.manuscriptStatistics.characters) 字")
                                    }.font(.caption).foregroundStyle(palette.secondary)
                                    Text(item.project.updatedAt, style: .date).font(.caption2).foregroundStyle(palette.secondary)
                                }.foregroundStyle(palette.text).contentShape(Rectangle())
                              }.buttonStyle(.plain).accessibilityIdentifier("library.project.\(item.project.id.uuidString)")
                              Button("继续写作") { open(item.project.id, true) }
                                  .accessibilityIdentifier("library.resume.\(item.project.id.uuidString)")
                            }
                        }
                    }
                }
                if !library.unreadableIDs.isEmpty {
                    Text("\(library.unreadableIDs.count) 部作品无法读取，请检查作品目录。").font(.callout).foregroundStyle(.red)
                }
            }.padding(32).frame(maxWidth: 1120, alignment: .leading).frame(maxWidth: .infinity)
        }.background(palette.paper)
    }
}
