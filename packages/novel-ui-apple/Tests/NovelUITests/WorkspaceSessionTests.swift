import XCTest
import NovelDomain
import NovelWorkspace
@testable import NovelUI

final class WorkspaceSessionTests: XCTestCase {
    @MainActor func testLayoutActionsRequestFocusForTheActualResultArea() throws {
        let suite = "NovelEngine.WorkspaceTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let session = WorkspaceSession(project: NovelProject(), preferences: preferences)
        let original = session.layout.activePaneID
        session.updateSize(CGSize(width: 900, height: 700), for: original)
        session.split(.down)
        XCTAssertNotEqual(session.layout.activePaneID, original)
        XCTAssertEqual(session.focusRequest?.paneID, session.layout.activePaneID)
        session.activate(original)
        XCTAssertNil(session.focusRequest)
        session.join(from: original, toward: .down)
        XCTAssertEqual(session.focusRequest?.paneID, original)
        let sidebar = try XCTUnwrap(session.layout.root.panes.first { $0.content == .manuscript })
        session.toggleFocus(in: sidebar.id)
        XCTAssertTrue(session.focused)
        XCTAssertEqual(session.focusRequest?.paneID, sidebar.id)
        session.toggleFocus(in: sidebar.id)
        XCTAssertFalse(session.focused)
    }
    @MainActor func testHidingMultipleSidebarAreasIsOneUndoStep() throws {
        let suite = "NovelEngine.WorkspaceTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let session = WorkspaceSession(project: NovelProject(), preferences: preferences)
        let sidebar = try XCTUnwrap(session.layout.root.panes.first { $0.content == .manuscript })
        session.updateSize(CGSize(width: 250, height: 700), for: sidebar.id)
        session.split(.down, in: sidebar.id)
        let before = session.layout.snapshot
        XCTAssertEqual(session.layout.root.panes.filter { $0.content == .manuscript }.count, 2)
        session.toggleManuscript()
        XCTAssertFalse(session.showsManuscript)
        session.undo()
        XCTAssertEqual(session.layout.snapshot, before)
    }
    @MainActor func testFocusAndExplicitSplitRouteToTheCorrectDocument() throws {
        let suite = "NovelEngine.WorkspaceTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章节", body: "原文"), WritingDocument(kind: .note, title: "笔记", body: "笔记原文")])
        let session = WorkspaceSession(project: project, preferences: preferences)
        let left = session.layout.activePaneID
        session.updateSize(CGSize(width: 1000, height: 700), for: left)
        session.split(.right)
        let right = session.layout.activePaneID
        session.open(project.documents[1].id, kind: .note)
        session.updateSize(CGSize(width: 600, height: 700), for: right)
        session.activate(left)
        XCTAssertEqual(session.kind, .chapter)
        // Local controls must target their own pane even when another pane is active.
        session.split(.down, in: right)
        XCTAssertEqual(session.layout.root.panes.count, 4)
        XCTAssertEqual(session.layout.activePane.documentID, project.documents[1].id)
        XCTAssertEqual(session.kind, .note)
        XCTAssertEqual(session.layout.root.node(left), .pane(EditorPane(id: left, documentID: project.documents[0].id)))
        XCTAssertEqual(project.documents.map(\.body), ["原文", "笔记原文"])
        session.focused = true
        XCTAssertFalse(session.canSplit(.down, in: right))
    }

    @MainActor func testClosedViewAndLayoutUndoPersistWithoutChangingManuscript() throws {
        let suite = "NovelEngine.WorkspaceTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章节", body: "  原文🙂\n"), WritingDocument(kind: .note, title: "笔记", body: "不删除\n")])
        let session = WorkspaceSession(project: project, preferences: preferences)
        session.updateSize(CGSize(width: 1000, height: 700), for: session.layout.activePaneID)
        session.split(.down)
        session.open(project.documents[1].id, kind: .note)
        let before = session.layout.snapshot
        session.close(session.layout.activePaneID)
        XCTAssertEqual(session.layout.root.panes.count, 2)
        session.undo()
        XCTAssertEqual(session.layout.snapshot, before)
        let restored = WorkspaceSession(project: project, preferences: preferences)
        XCTAssertEqual(restored.layout.snapshot, before)
        XCTAssertEqual(restored.kind, .note)
        XCTAssertEqual(project.documents.map(\.body), ["  原文🙂\n", "不删除\n"])
    }

    @MainActor func testLegacyLayoutMigratesOnceAndKeepsClosedSidebarClosed() throws {
        let suite = "NovelEngine.WorkspaceTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let project = NovelProject()
        var old = WorkspaceLayout(documentID: project.documents[0].id)
        old.split(.down)
        preferences.set(try JSONEncoder().encode(old.snapshot), forKey: "workspace.\(project.id.uuidString)")
        let migrated = WorkspaceSession(project: project, preferences: preferences)
        XCTAssertEqual(Set(migrated.layout.root.panes.filter { $0.content == .editor }.map(\.id)), Set(old.root.panes.map(\.id)))
        let sidebar = try XCTUnwrap(migrated.layout.root.panes.first { $0.content == .manuscript })
        migrated.close(sidebar.id)
        let reopened = WorkspaceSession(project: project, preferences: preferences)
        XCTAssertFalse(reopened.showsManuscript)
        XCTAssertEqual(reopened.layout.snapshot, migrated.layout.snapshot)
        XCTAssertNotNil(preferences.data(forKey: "workspace.\(project.id.uuidString)"))
    }

    @MainActor func testSidebarSelectionTargetsLastEditorAndWorksAfterAllEditorsClose() throws {
        let suite = "NovelEngine.WorkspaceTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章节", body: "原文"), WritingDocument(kind: .note, title: "笔记")])
        let session = WorkspaceSession(project: project, preferences: preferences)
        let editor = session.layout.activePaneID
        let sidebar = try XCTUnwrap(session.layout.root.panes.first { $0.content == .manuscript })
        session.activate(sidebar.id)
        session.open(project.documents[1].id, kind: .note)
        XCTAssertEqual(session.layout.activePaneID, editor)
        XCTAssertEqual(session.selectedDocumentID, project.documents[1].id)
        XCTAssertEqual(session.layout.root.panes.first { $0.id == sidebar.id }?.content, .manuscript)
        session.close(editor)
        session.open(project.documents[0].id)
        XCTAssertEqual(session.layout.activePane.content, .editor)
        XCTAssertEqual(session.selectedDocumentID, project.documents[0].id)
        XCTAssertEqual(project.documents[0].body, "原文")
    }
}
