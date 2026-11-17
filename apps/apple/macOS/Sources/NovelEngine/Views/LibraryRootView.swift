import SwiftUI
import AppKit
import NovelDomain
import NovelUI

struct LibraryRootView: View {
    @ObservedObject var library: LibraryController
    @Environment(\.colorScheme) private var scheme
    @AppStorage("appearance") private var appearance = NovelAppearance.system.rawValue
    @State private var selectedID: UUID?
    @State private var startsEditing = false
    @State private var showsNew = false
    @State private var errorMessage: String?
    private var palette: NovelPalette { NovelPalette(scheme) }
    private var selected: ManagedProjectSession? { selectedID.flatMap { library.sessions[$0] } }

    var body: some View {
        Group {
            if let selected {
                ProjectRouteView(session: selected, palette: palette, startsEditing: startsEditing) { selectedID = nil }
                    .id(selected.id)
            } else {
                BookshelfView(library: library, palette: palette, create: { showsNew = true }, importProject: importProject) { id, editing in
                    Task { do { startsEditing = editing; selectedID = try await library.open(id).id } catch { errorMessage = error.localizedDescription } }
                }
            }
        }.frame(minWidth: 760, minHeight: 520).tint(palette.accent)
            .preferredColorScheme((NovelAppearance(rawValue: appearance) ?? .system).colorScheme)
            .task { do { try await library.refresh() } catch { errorMessage = error.localizedDescription } }
            .focusedSceneValue(\.libraryActions, LibraryActions(new: { showsNew = true }, importProject: importProject,
                export: exportProject, save: save, canEdit: selected != nil, enabled: library.repository != nil))
            .sheet(isPresented: $showsNew) {
                NewProjectSheet { title in
                    Task {
                        do { startsEditing = false; selectedID = try await library.create(title: title).id; showsNew = false }
                        catch { showsNew = false; errorMessage = error.localizedDescription }
                    }
                } cancel: { showsNew = false }
            }
            .alert("操作失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("好") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .onOpenURL { url in importProject(url) }
    }
    private func importProject() { if let url = LibraryPanels.chooseProject() { importProject(url) } }
    private func importProject(_ url: URL) {
        Task { do { startsEditing = false; selectedID = try await library.importProject(from: url).id } catch { errorMessage = error.localizedDescription } }
    }
    private func save() {
        guard let selected else { return }
        Task { do { try await selected.flush() } catch { errorMessage = error.localizedDescription } }
    }
    private func exportProject() {
        guard let selected, let url = LibraryPanels.exportDestination(title: selected.project.title) else { return }
        Task { do { try await selected.export(to: url) } catch { errorMessage = error.localizedDescription } }
    }
}

private struct NewProjectSheet: View {
    let create: (String) -> Void
    let cancel: () -> Void
    @State private var title = ""
    @State private var creating = false
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("新建小说").font(.headline)
            TextField("小说名称", text: $title).focused($focused).accessibilityIdentifier("library.new.title")
            HStack {
                Spacer(); Button("取消", action: cancel).keyboardShortcut(.cancelAction)
                Button("创建") { creating = true; create(title) }.keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || creating)
                    .accessibilityIdentifier("library.new.create")
            }
        }.padding(24).frame(width: 360).onAppear { focused = true }
    }
}

private struct ProjectRouteView: View {
    @ObservedObject var session: ManagedProjectSession
    let palette: NovelPalette
    let back: () -> Void
    @State private var editing: Bool
    init(session: ManagedProjectSession, palette: NovelPalette, startsEditing: Bool, back: @escaping () -> Void) {
        self.session = session; self.palette = palette; self.back = back
        _editing = State(initialValue: startsEditing)
    }
    var body: some View {
        VStack(spacing: 0) {
            if case .failed(let message) = session.saveState {
                HStack {
                    Text(message).font(.callout)
                    Spacer(); Button("重试保存") { session.retry() }
                }.padding(12).foregroundStyle(.red).background(palette.chrome)
            }
            if editing {
                NativeWorkspace(project: Binding(get: { session.project }, set: { session.replace($0) }))
            } else { ProjectOverviewView(session: session, palette: palette) { editing = true } }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    Task { do { try await session.flush(); if editing { editing = false } else { back() } } catch {} }
                } label: { Label(editing ? "作品主页" : "作品库", systemImage: "chevron.left") }
                    .accessibilityIdentifier("library.back")
            }
            ToolbarItem(placement: .status) {
                Text(session.saveState.title).font(.caption).foregroundStyle(palette.secondary)
                    .accessibilityIdentifier("project.saveStatus")
            }
        }
        .alert("封面导入失败", isPresented: Binding(get: { session.coverError != nil }, set: { if !$0 { session.coverError = nil } })) {
            Button("好") { session.coverError = nil }
        } message: { Text(session.coverError ?? "") }
    }
}
