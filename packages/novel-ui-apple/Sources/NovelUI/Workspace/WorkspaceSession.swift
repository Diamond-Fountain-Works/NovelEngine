import Foundation
import SwiftUI
import NovelWorkspace
import NovelDomain

struct AreaFocusRequest: Equatable {
    let paneID: UUID
    let token = UUID()
}

@MainActor final class WorkspaceSession: ObservableObject {
    @Published private(set) var layout: EditorWorkspaceLayout
    @Published private(set) var browser = LibraryBrowserState()
    @Published private(set) var showsManuscript = true
    @Published var focused = false
    @Published var showsInspector = false
    @Published private(set) var inspectedDocumentID: UUID?
    @Published private(set) var focusRequest: AreaFocusRequest?
    private var workspaceSize = CGSize.zero
    private var documentKinds: [UUID: WritingKind]
    private let preferences: UserDefaults
    private let preferenceKey: String
    private let browserPreferenceKey: String
    private let sidebarPreferenceKey: String

    var selectedDocumentID: UUID { layout.activePane.documentID }
    var kind: WritingKind { documentKinds[selectedDocumentID] ?? .chapter }

    init(project: NovelProject, preferences: UserDefaults = .standard) {
        self.preferences = preferences
        preferenceKey = "workspace.editors.\(project.id.uuidString)"
        browserPreferenceKey = "library.browser.\(project.id.uuidString)"
        sidebarPreferenceKey = "library.visible.\(project.id.uuidString)"
        documentKinds = Dictionary(uniqueKeysWithValues: project.documents.map { ($0.id, $0.kind) })
        let valid = Set(project.documents.map(\.id))
        let legacy = ["workspace.areas.\(project.id.uuidString)", "workspace.\(project.id.uuidString)"]
            .compactMap { key -> WorkspaceSnapshot? in
                guard let data = preferences.data(forKey: key),
                      let value = try? JSONDecoder().decode(WorkspaceSnapshot.self, from: data),
                      WorkspaceLayout(restoring: value, validDocumentIDs: valid) != nil else { return nil }
                return value
            }.first
        if let data = preferences.data(forKey: preferenceKey),
           let snapshot = try? JSONDecoder().decode(EditorWorkspaceSnapshot.self, from: data),
           let restored = EditorWorkspaceLayout(restoring: snapshot, validDocumentIDs: valid) {
            layout = restored
        } else if let legacy, let migrated = EditorWorkspaceLayout(migrating: legacy, validDocumentIDs: valid) {
            layout = migrated
        } else {
            layout = EditorWorkspaceLayout(documentID: project.documents[0].id)
        }
        browser = LibraryBrowserState(kind: documentKinds[layout.activePane.documentID] ?? .chapter)
        if let data = preferences.data(forKey: browserPreferenceKey),
           let restored = try? JSONDecoder().decode(LibraryBrowserState.self, from: data),
           [.chapter, .note].contains(restored.manuscriptKind) {
            browser = restored
        } else if let sidebar = legacy?.root.panes.first(where: { $0.content == .manuscript }),
                  let data = preferences.data(forKey: "library.browsers.\(project.id.uuidString)"),
                  let states = try? JSONDecoder().decode([UUID: LibraryBrowserState].self, from: data),
                  let restored = states[sidebar.id], [.chapter, .note].contains(restored.manuscriptKind) {
            browser = restored
        }
        showsManuscript = preferences.object(forKey: sidebarPreferenceKey) as? Bool ?? true
        save()
    }

    func setSection(_ section: LibrarySection) {
        browser.section = section; browser.search = ""; focusRequest = nil; save()
    }
    func setManuscriptKind(_ kind: WritingKind) {
        guard kind == .chapter || kind == .note else { return }
        browser.manuscriptKind = kind; browser.search = ""; focusRequest = nil; save()
    }
    func setSearch(_ text: String) { browser.search = text; focusRequest = nil }
    func register(_ documentID: UUID, kind: WritingKind) { documentKinds[documentID] = kind }
    func prepareAuxiliaryInput(in paneID: UUID) { activate(paneID); focusRequest = nil }
    func prepareLibraryInput() { focusRequest = nil }
    func activate(_ paneID: UUID) {
        guard layout.root.panes.contains(where: { $0.id == paneID }), layout.activePaneID != paneID else { return }
        focusRequest = nil; layout.activate(paneID); save()
    }
    func open(_ documentID: UUID, kind: WritingKind? = nil, in paneID: UUID? = nil) {
        if let kind { register(documentID, kind: kind) }
        guard documentKinds[documentID] != nil,
              paneID == nil || layout.root.panes.contains(where: { $0.id == paneID }) else { return }
        layout.open(documentID, in: paneID); requestFocus(); save()
    }
    func split(_ direction: SplitDirection) {
        guard canSplit(direction), layout.arrange(direction) else { return }
        requestFocus(); save()
    }
    func canSplit(_ direction: SplitDirection) -> Bool {
        guard !focused else { return false }
        return direction.axis == .horizontal ? workspaceSize.width >= 486 : workspaceSize.height >= 366
    }
    func updateWorkspaceSize(_ size: CGSize) {
        if workspaceSize != size { workspaceSize = size; objectWillChange.send() }
    }
    func close(_ paneID: UUID) {
        guard layout.auxiliary?.id == paneID, layout.closeAuxiliary() else { return }
        focused = false; requestFocus(); save()
    }
    func resize(_ branchID: UUID, ratio: Double) {
        guard branchID == layout.snapshot.splitID, ratio.isFinite else { return }
        let extent = layout.direction.axis == .horizontal ? workspaceSize.width : workspaceSize.height
        let minimum = layout.direction.axis == .horizontal ? 240.0 : 180.0
        let lower = min(0.5, minimum / max(1, extent - 6))
        layout.resize(min(1 - lower, max(lower, ratio))); save()
    }
    func toggleFocus(in paneID: UUID) {
        guard layout.root.panes.contains(where: { $0.id == paneID }) else { return }
        layout.activate(paneID); focused.toggle(); requestFocus(); save()
    }
    func inspect(_ paneID: UUID? = nil) {
        guard let pane = layout.root.panes.first(where: { $0.id == (paneID ?? layout.activePaneID) }) else { return }
        prepareAuxiliaryInput(in: pane.id); inspectedDocumentID = pane.documentID; showsInspector = true
    }
    func reset() {
        focused = false; showsManuscript = true
        _ = layout.closeAuxiliary(); requestFocus(); save()
    }
    func undo() { focused = false; layout.undo(); requestFocus(); save() }
    func toggleManuscript() { showsManuscript.toggle(); requestFocus(); save() }
    private func save() {
        if let data = try? JSONEncoder().encode(layout.snapshot) { preferences.set(data, forKey: preferenceKey) }
        if let data = try? JSONEncoder().encode(browser) { preferences.set(data, forKey: browserPreferenceKey) }
        preferences.set(showsManuscript, forKey: sidebarPreferenceKey)
    }
    private func requestFocus() { focusRequest = AreaFocusRequest(paneID: layout.activePaneID) }
}
