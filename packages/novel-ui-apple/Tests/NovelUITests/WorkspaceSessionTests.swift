import XCTest
import NovelDomain
import NovelWorkspace
@testable import NovelUI

final class WorkspaceSessionTests: XCTestCase {
    @MainActor private func preferences() throws -> (UserDefaults, String) {
        let suite = "NovelEngine.WorkspaceTests.\(UUID().uuidString)"
        return (try XCTUnwrap(UserDefaults(suiteName: suite)), suite)
    }

    @MainActor func testDirectionsMoveSameAuxiliaryAndPreserveActiveEditor() throws {
        let (defaults, suite) = try preferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章节", body: "原文"), WritingDocument(kind: .character, title: "人物")])
        let session = WorkspaceSession(project: project, preferences: defaults)
        let primary = session.layout.primary.id
        session.updateWorkspaceSize(CGSize(width: 1000, height: 700))
        session.split(.right)
        let auxiliary = try XCTUnwrap(session.layout.auxiliary?.id)
        session.open(project.documents[1].id, in: auxiliary)
        session.activate(primary)
        for direction in SplitDirection.allCases {
            session.split(direction)
            XCTAssertEqual(session.layout.root.panes.count, 2)
            XCTAssertEqual(session.layout.activePaneID, primary)
            XCTAssertEqual(session.layout.primary.documentID, project.documents[0].id)
            XCTAssertEqual(session.layout.auxiliary?.id, auxiliary)
            XCTAssertEqual(session.layout.auxiliary?.documentID, project.documents[1].id)
        }
        XCTAssertTrue(session.layout.root.panes.allSatisfy { $0.content == .editor })
        XCTAssertEqual(project.documents[0].body, "原文")
    }

    @MainActor func testOnlyAuxiliaryClosesAndUndoRestoresItsExactSelection() throws {
        let (defaults, suite) = try preferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章节", body: "  原文🙂\n"), WritingDocument(kind: .note, title: "笔记", body: "不删除\n")])
        let session = WorkspaceSession(project: project, preferences: defaults)
        session.updateWorkspaceSize(CGSize(width: 1000, height: 700))
        session.split(.down); session.open(project.documents[1].id)
        let before = session.layout.snapshot
        session.close(session.layout.primary.id)
        XCTAssertEqual(session.layout.snapshot, before)
        session.close(try XCTUnwrap(session.layout.auxiliary?.id))
        XCTAssertEqual(session.layout.root.panes.count, 1)
        XCTAssertEqual(session.focusRequest?.paneID, session.layout.primary.id)
        session.undo()
        XCTAssertEqual(session.layout.snapshot, before)
        let restored = WorkspaceSession(project: project, preferences: defaults)
        XCTAssertEqual(restored.layout.snapshot, before)
        XCTAssertEqual(restored.kind, .note)
        XCTAssertEqual(project.documents.map(\.body), ["  原文🙂\n", "不删除\n"])
    }

    @MainActor func testLegacyAreasMigrationPreservesKeysDocumentsAndChosenPaneIDs() throws {
        let (defaults, suite) = try preferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章节", body: "旧章\n"), WritingDocument(kind: .event, title: "事件")])
        var old = WorkspaceLayout(documentID: project.documents[0].id, includingManuscript: true)
        let primary = old.activePane
        old.split(.right); old.open(project.documents[1].id); old.split(.down)
        let oldData = try JSONEncoder().encode(old.snapshot)
        let oldKey = "workspace.areas.\(project.id.uuidString)"
        defaults.set(oldData, forKey: oldKey)
        let sidebar = try XCTUnwrap(old.root.panes.first { $0.content == .manuscript })
        var browser = LibraryBrowserState(kind: .character); browser.search = "不保存的搜索"
        let browserData = try JSONEncoder().encode([sidebar.id: browser])
        let browserKey = "library.browsers.\(project.id.uuidString)"
        defaults.set(browserData, forKey: browserKey)
        let migrated = WorkspaceSession(project: project, preferences: defaults)
        XCTAssertEqual(migrated.layout.primary, primary)
        XCTAssertEqual(migrated.layout.auxiliary, old.activePane)
        XCTAssertEqual(migrated.browser.section, .characters)
        XCTAssertEqual(migrated.browser.search, "")
        XCTAssertTrue(migrated.showsManuscript)
        XCTAssertEqual(defaults.data(forKey: oldKey), oldData)
        XCTAssertEqual(defaults.data(forKey: browserKey), browserData)
        let reopened = WorkspaceSession(project: project, preferences: defaults)
        XCTAssertEqual(reopened.layout.snapshot, migrated.layout.snapshot)
        XCTAssertEqual(project.documents[0].body, "旧章\n")
    }

    @MainActor func testOriginalEditorOnlyPreferencesRemainReadableAndUnmodified() throws {
        let (defaults, suite) = try preferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let project = NovelProject()
        var old = WorkspaceLayout(documentID: project.documents[0].id)
        old.split(.down)
        let data = try JSONEncoder().encode(old.snapshot)
        let key = "workspace.\(project.id.uuidString)"
        defaults.set(data, forKey: key)
        let session = WorkspaceSession(project: project, preferences: defaults)
        XCTAssertEqual(Set(session.layout.root.panes.map(\.id)), Set(old.root.panes.map(\.id)))
        XCTAssertEqual(session.layout.direction, .down)
        session.toggleManuscript()
        XCTAssertFalse(WorkspaceSession(project: project, preferences: defaults).showsManuscript)
        XCTAssertEqual(defaults.data(forKey: key), data)
    }

    @MainActor func testLibraryOpensInActiveEditorAndExplicitPickerOnlyChangesItsOwnPane() throws {
        let (defaults, suite) = try preferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章节"), WritingDocument(kind: .character, title: "人物"), WritingDocument(kind: .event, title: "事件")])
        let session = WorkspaceSession(project: project, preferences: defaults)
        session.updateWorkspaceSize(CGSize(width: 1000, height: 700)); session.split(.right)
        let auxiliary = try XCTUnwrap(session.layout.auxiliary?.id), primary = session.layout.primary.id
        session.setSection(.characters)
        session.open(project.documents[1].id)
        XCTAssertEqual(session.layout.auxiliary?.documentID, project.documents[1].id)
        XCTAssertEqual(session.layout.primary.documentID, project.documents[0].id)
        session.open(project.documents[2].id, in: primary)
        XCTAssertEqual(session.layout.primary.documentID, project.documents[2].id)
        XCTAssertEqual(session.layout.auxiliary?.documentID, project.documents[1].id)
        XCTAssertEqual(session.browser.section, .characters)
        session.activate(auxiliary)
        XCTAssertEqual(session.kind, .character)
    }

    @MainActor func testFocusInspectorAndNarrowWindowDoNotCreateExtraEditors() throws {
        let (defaults, suite) = try preferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let session = WorkspaceSession(project: NovelProject(), preferences: defaults)
        session.updateWorkspaceSize(CGSize(width: 480, height: 500))
        XCTAssertFalse(session.canSplit(.right)); XCTAssertTrue(session.canSplit(.down))
        session.split(.down)
        let snapshot = session.layout.snapshot
        session.inspect(session.layout.primary.id)
        XCTAssertEqual(session.inspectedDocumentID, session.layout.primary.documentID)
        XCTAssertTrue(session.showsInspector)
        XCTAssertEqual(session.layout.snapshot.primary, snapshot.primary)
        XCTAssertEqual(session.layout.snapshot.auxiliary, snapshot.auxiliary)
        session.toggleFocus(in: session.layout.primary.id)
        XCTAssertTrue(session.focused); XCTAssertFalse(session.canSplit(.down))
        session.toggleFocus(in: session.layout.primary.id)
        XCTAssertFalse(session.focused)
        session.reset()
        XCTAssertNil(session.layout.auxiliary); XCTAssertTrue(session.showsManuscript)
    }

    @MainActor func testUnknownDocumentOrPaneDoesNotChangeSelectionOrPreferences() throws {
        let (defaults, suite) = try preferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let project = NovelProject()
        let session = WorkspaceSession(project: project, preferences: defaults)
        let before = session.layout.snapshot
        session.open(UUID())
        session.open(project.documents[0].id, in: UUID())
        session.activate(UUID()); session.close(UUID())
        XCTAssertEqual(session.layout.snapshot, before)
        XCTAssertNil(session.focusRequest)
    }
}
