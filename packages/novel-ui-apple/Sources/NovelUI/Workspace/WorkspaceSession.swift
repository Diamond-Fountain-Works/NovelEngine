import Foundation
import SwiftUI
import NovelWorkspace
import NovelDomain

struct AreaFocusRequest: Equatable {
    let paneID: UUID
    let token = UUID()
}

@MainActor final class WorkspaceSession: ObservableObject {
    @Published private(set) var layout: WorkspaceLayout
    @Published var kind: WritingKind = .chapter
    @Published var search = ""
    @Published var focused = false
    @Published private(set) var focusRequest: AreaFocusRequest?
    private var sizes: [UUID: CGSize] = [:]
    private var documentKinds: [UUID: WritingKind]
    private var lastEditorID: UUID?
    private let preferences: UserDefaults
    private let preferenceKey: String

    var selectedDocumentID: UUID {
        layout.root.panes.first { $0.id == lastEditorID && $0.content == .editor }?.documentID
            ?? layout.root.panes.first { $0.content == .editor }?.documentID ?? layout.activePane.documentID
    }
    var showsManuscript: Bool { layout.root.panes.contains { $0.content == .manuscript } }
    var showsInspector: Bool { layout.root.panes.contains { $0.content == .inspector } }

    init(project: NovelProject, preferences: UserDefaults = .standard) {
        self.preferences = preferences; preferenceKey = "workspace.areas.\(project.id.uuidString)"
        documentKinds = Dictionary(uniqueKeysWithValues: project.documents.map { ($0.id, $0.kind) })
        let valid = Set(project.documents.map(\.id))
        if let data = preferences.data(forKey: preferenceKey),
           let snapshot = try? JSONDecoder().decode(WorkspaceSnapshot.self, from: data),
           let restored = WorkspaceLayout(restoring: snapshot, validDocumentIDs: valid) {
            layout = restored
        } else if let data = preferences.data(forKey: "workspace.\(project.id.uuidString)"),
                  let snapshot = try? JSONDecoder().decode(WorkspaceSnapshot.self, from: data),
                  WorkspaceLayout(restoring: snapshot, validDocumentIDs: valid) != nil {
            // Wrap the old editor-only layout once; never replace its pane IDs.
            let root = WorkspaceNode.split(WorkspaceBranch(axis: .horizontal, ratio: 0.22,
                first: .pane(EditorPane(documentID: project.documents[0].id, content: .manuscript)), second: snapshot.root))
            layout = WorkspaceLayout(restoring: WorkspaceSnapshot(root: root, activePaneID: snapshot.activePaneID), validDocumentIDs: valid)!
        } else {
            layout = WorkspaceLayout(documentID: project.documents[0].id, includingManuscript: true)
        }
        lastEditorID = layout.activePane.content == .editor ? layout.activePaneID : layout.root.panes.first { $0.content == .editor }?.id
        kind = documentKinds[selectedDocumentID] ?? .chapter
    }
    func register(_ documentID: UUID, kind: WritingKind) { documentKinds[documentID] = kind }
    func activate(_ paneID: UUID) {
        guard let pane = layout.root.panes.first(where: { $0.id == paneID }) else { return }
        if pane.content == .editor { lastEditorID = paneID; kind = documentKinds[pane.documentID] ?? kind }
        guard layout.activePaneID != paneID else { return }
        focusRequest = nil; layout.activate(paneID); save()
    }
    func open(_ documentID: UUID, kind: WritingKind? = nil) {
        if let kind { register(documentID, kind: kind) }
        let target = layout.root.panes.first { $0.id == lastEditorID && $0.content == .editor }
            ?? layout.root.panes.first { $0.content == .editor }
        if let target {
            layout.open(documentID, in: target.id); lastEditorID = target.id
        } else {
            // A document can still open after all editor views have been closed.
            layout.setContent(.editor, in: layout.activePaneID)
            layout.open(documentID); lastEditorID = layout.activePaneID
        }
        self.kind = documentKinds[documentID] ?? self.kind; requestFocus(); save()
    }
    func split(_ direction: SplitDirection, in paneID: UUID? = nil) {
        guard canSplit(direction, in: paneID) else { return }
        layout.split(direction, in: paneID); reconcileSelection(); requestFocus(); save()
    }
    func canSplit(_ direction: SplitDirection, in paneID: UUID? = nil) -> Bool {
        guard !focused, layout.root.panes.contains(where: { $0.id == (paneID ?? layout.activePaneID) }) else { return false }
        let size = sizes[paneID ?? layout.activePaneID] ?? .zero
        return direction.axis == .horizontal ? size.width >= 486 : size.height >= 366
    }
    func updateSize(_ size: CGSize, for paneID: UUID) {
        if sizes[paneID] != size { sizes[paneID] = size; objectWillChange.send() }
    }
    func setContent(_ content: WorkspaceContent, in paneID: UUID) {
        layout.setContent(content, in: paneID); reconcileSelection(); requestFocus(); save()
    }
    func join(from paneID: UUID, toward direction: SplitDirection) {
        if layout.join(from: paneID, toward: direction) { reconcileSelection(); requestFocus(); save() }
    }
    func close(_ paneID: UUID) {
        if layout.close(paneID) { reconcileSelection(); requestFocus(); save() }
    }
    func resize(_ branchID: UUID, ratio: Double) { layout.resize(branchID, ratio: ratio); save() }
    func toggleFocus(in paneID: UUID) {
        guard layout.root.panes.contains(where: { $0.id == paneID }) else { return }
        layout.activate(paneID); focused.toggle(); reconcileSelection(); requestFocus(); save()
    }
    func reset() { focused = false; layout.restoreWorkspace(documentID: selectedDocumentID); reconcileSelection(); requestFocus(); save() }
    func undo() { layout.undo(); reconcileSelection(); requestFocus(); save() }
    func toggleManuscript() { toggle(.manuscript, direction: .left) }
    func toggleInspector() { toggle(.inspector, direction: .right) }
    func canToggle(_ content: WorkspaceContent, direction: SplitDirection) -> Bool {
        let matching = layout.root.panes.filter { $0.content == content }
        if !matching.isEmpty { return matching.count < layout.root.panes.count }
        let target = layout.root.panes.first { $0.id == lastEditorID }?.id ?? layout.activePaneID
        return canSplit(direction, in: target)
    }
    private func toggle(_ content: WorkspaceContent, direction: SplitDirection) {
        guard canToggle(content, direction: direction) else { return }
        focused = false
        let existing = layout.root.panes.filter { $0.content == content }
        if !existing.isEmpty {
            layout.closeAll(content)
        } else {
            let target = layout.root.panes.first { $0.id == lastEditorID }?.id ?? layout.activePaneID
            layout.split(direction, in: target); layout.setContent(content, in: layout.activePaneID)
        }
        reconcileSelection(); requestFocus(); save()
    }
    private func reconcileSelection() {
        if layout.activePane.content == .editor { lastEditorID = layout.activePaneID }
        if !layout.root.panes.contains(where: { $0.id == lastEditorID && $0.content == .editor }) {
            lastEditorID = layout.root.panes.first { $0.content == .editor }?.id
        }
        kind = documentKinds[selectedDocumentID] ?? kind
        sizes = sizes.filter { id, _ in layout.root.panes.contains { $0.id == id } }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(layout.snapshot) { preferences.set(data, forKey: preferenceKey) }
    }
    private func requestFocus() { focusRequest = AreaFocusRequest(paneID: layout.activePaneID) }
}
