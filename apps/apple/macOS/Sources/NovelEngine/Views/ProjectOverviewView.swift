import SwiftUI
import AppKit
import NovelDomain
import NovelUI

struct ProjectOverviewView: View {
    @ObservedObject var session: ManagedProjectSession
    let palette: NovelPalette
    let write: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top, spacing: 30) {
                    VStack(spacing: 12) {
                        ProjectCoverView(project: session.project, repository: session.repository, palette: palette).frame(width: 160)
                        Button(session.project.details.cover == nil ? "选择封面" : "更换封面") {
                            if let url = LibraryPanels.chooseCover() { session.importCover(from: url) }
                        }.disabled(session.importingCover).accessibilityIdentifier("project.cover.choose")
                        if session.importingCover { ProgressView().controlSize(.small) }
                        if session.project.details.cover != nil {
                            Button("移除封面") { session.edit { $0.details.cover = nil } }.buttonStyle(.plain).foregroundStyle(palette.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        TextField("小说名称", text: field(\.title)).font(.system(size: 28, weight: .semibold, design: .serif))
                            .textFieldStyle(.plain).accessibilityIdentifier("project.name")
                        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 14) {
                            GridRow {
                                Text("作者 / 笔名").frame(width: 84, alignment: .leading)
                                TextField("作者 / 笔名", text: details(\.author)).labelsHidden().accessibilityIdentifier("project.author")
                            }
                            GridRow {
                                Text("类型")
                                TextField("类型", text: details(\.genre)).labelsHidden().accessibilityIdentifier("project.genre")
                            }
                            GridRow {
                                Text("标签")
                                TextField("标签", text: details(\.tags)).labelsHidden().accessibilityIdentifier("project.tags")
                            }
                            GridRow {
                                Text("写作状态")
                                Picker("写作状态", selection: details(\.status)) {
                                    ForEach(NovelWritingStatus.allCases, id: \.self) { Text($0.title).tag($0) }
                                }.labelsHidden().accessibilityIdentifier("project.status")
                            }
                        }.textFieldStyle(.roundedBorder)
                        HStack(spacing: 14) {
                            Text("\(session.project.documents.filter { $0.kind == .chapter }.count) 章")
                            Text("\(session.project.manuscriptStatistics.characters) 字")
                        }.font(.caption).foregroundStyle(palette.secondary)
                        Button("继续写作", action: write).buttonStyle(.borderedProminent).accessibilityIdentifier("project.continue")
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                palette.rule.frame(height: 1)
                VStack(alignment: .leading, spacing: 10) {
                    Text("简介").font(.headline)
                    TextEditor(text: details(\.synopsis)).font(.body).scrollContentBackground(.hidden)
                        .padding(8).frame(height: 220).background(palette.chrome)
                        .overlay(Rectangle().strokeBorder(palette.rule, lineWidth: 1))
                        .accessibilityIdentifier("project.synopsis")
                }
                ContributorEditor(contributors: details(\.contributors), palette: palette)
            }.padding(32).frame(maxWidth: 960, alignment: .leading).frame(maxWidth: .infinity)
        }.background(palette.paper).foregroundStyle(palette.text)
    }
    private func field<T>(_ key: WritableKeyPath<NovelProject, T>) -> Binding<T> {
        Binding(get: { session.project[keyPath: key] }, set: { value in session.edit { $0[keyPath: key] = value } })
    }
    private func details<T>(_ key: WritableKeyPath<ProjectDetails, T>) -> Binding<T> {
        Binding(get: { session.project.details[keyPath: key] }, set: { value in session.edit { $0.details[keyPath: key] = value } })
    }
}

private struct ContributorEditor: View {
    @Binding var contributors: [Contributor]
    let palette: NovelPalette
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("合作者").font(.headline)
                Spacer()
                Button { contributors.append(Contributor()) } label: { Label("添加合作者", systemImage: "plus") }
                    .accessibilityIdentifier("project.contributor.add")
            }
            if !contributors.isEmpty {
                HStack(spacing: 12) {
                    Text("姓名 / 笔名").frame(maxWidth: .infinity, alignment: .leading)
                    Text("分工").frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear.frame(width: 16, height: 1)
                }.font(.caption).foregroundStyle(palette.secondary)
            }
            ForEach($contributors) { $person in
                HStack(spacing: 12) {
                    TextField("姓名 / 笔名", text: $person.name).accessibilityIdentifier("project.contributor.name.\(person.id.uuidString)")
                    TextField("分工", text: $person.role).accessibilityIdentifier("project.contributor.role.\(person.id.uuidString)")
                    Button { contributors.removeAll { $0.id == person.id } } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.plain).help("移除合作者").accessibilityLabel("移除合作者")
                }
            }
        }
    }
}
