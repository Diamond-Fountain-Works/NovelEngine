import XCTest
import SwiftUI
import NovelDomain
import NovelApplication
@testable import NovelUI

final class LibrarySessionTests: XCTestCase {
    @MainActor func testUnchangedMetadataDoesNotWriteOrMarkTheDocumentDirty() {
        var project = NovelProject(documents: [WritingDocument(kind: .character, title: "人物")])
        var writes = 0
        let bindings = ProjectBindings(project: Binding(get: { project }, set: { project = $0; writes += 1 }), reportError: { _ in XCTFail("Unexpected error") })
        let id = project.documents[0].id
        bindings.reference(\.tags, documentID: id).wrappedValue = []
        bindings.reference(\.code, documentID: id).wrappedValue = ""
        bindings.field(\.title, documentID: id).wrappedValue = "人物"
        XCTAssertEqual(writes, 0)
        bindings.reference(\.status, documentID: id).wrappedValue = .confirmed
        XCTAssertEqual(writes, 1)
    }

    @MainActor func testReferenceOnlyProjectStartsInItsActualLibrarySection() throws {
        let suite = "NovelEngine.LibraryTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .character, title: "人物")])
        let session = WorkspaceSession(project: project, preferences: preferences)
        XCTAssertEqual(session.browser.section, .characters)
    }
    @MainActor func testAuxiliaryInputCancelsPendingBodyFocusWithoutChangingDocument() throws {
        let suite = "NovelEngine.LibraryTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let project = NovelProject()
        let session = WorkspaceSession(project: project, preferences: preferences)
        session.open(project.documents[0].id)
        let pane = session.layout.activePaneID
        XCTAssertNotNil(session.focusRequest)
        let before = session.layout.snapshot
        session.prepareAuxiliaryInput(in: pane)
        XCTAssertNil(session.focusRequest)
        XCTAssertEqual(session.layout.snapshot, before)
    }
    @MainActor func testFixedLibraryKeepsItsSectionAndSearchAcrossEditorChanges() throws {
        let suite = "NovelEngine.LibraryTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let person = WritingDocument(kind: .character, title: "合成人物")
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章"), person])
        let session = WorkspaceSession(project: project, preferences: preferences)
        session.setSection(.characters); session.setSearch("私人搜索")
        session.updateWorkspaceSize(CGSize(width: 1000, height: 800)); session.split(.right)
        session.open(person.id)
        XCTAssertEqual(session.browser.section, .characters)
        XCTAssertEqual(session.browser.search, "私人搜索")
        let restored = WorkspaceSession(project: project, preferences: preferences)
        XCTAssertEqual(restored.browser.section, .characters)
        XCTAssertEqual(restored.browser.search, "")
        XCTAssertEqual(restored.layout.snapshot, session.layout.snapshot)
    }

    @MainActor func testRelatedDocumentOpensInItsSourceEditorAndKeepsOtherPane() throws {
        let suite = "NovelEngine.LibraryTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章"), WritingDocument(kind: .event, title: "事件")])
        let session = WorkspaceSession(project: project, preferences: preferences)
        let left = session.layout.activePaneID
        session.updateWorkspaceSize(CGSize(width: 1000, height: 700))
        session.split(.right)
        let right = session.layout.activePaneID
        session.open(project.documents[1].id, kind: .event, in: left)
        XCTAssertEqual(session.layout.activePaneID, left)
        XCTAssertEqual(session.layout.root.panes.first { $0.id == right }?.documentID, project.documents[0].id)
        XCTAssertEqual(session.focusRequest?.paneID, left)
        let before = session.layout.snapshot
        session.open(UUID())
        XCTAssertEqual(session.layout.snapshot, before)
    }

    @MainActor func testReferenceBindingRejectsBadLinkWithoutPartialMutation() throws {
        var project = NovelProject(documents: [WritingDocument(kind: .character, title: "人物", body: "  原文🙂\n")])
        var errors: [String] = []
        let bindings = ProjectBindings(project: Binding(get: { project }, set: { project = $0 }), reportError: { errors.append($0.localizedDescription) })
        let id = project.documents[0].id
        bindings.reference(\.status, documentID: id).wrappedValue = .confirmed
        XCTAssertEqual(project.document(id)?.reference?.status, .confirmed)
        XCTAssertEqual(project.document(id)?.body, "  原文🙂\n")
        let before = project
        bindings.reference(\.relatedIDs, documentID: id).wrappedValue = [UUID()]
        XCTAssertEqual(project, before)
        XCTAssertEqual(errors.count, 1)
        let child = try XCTUnwrap(bindings.addChild(to: id))
        XCTAssertEqual(project.document(child)?.parentID, id)
        XCTAssertTrue(errors.count == 1)
    }
}
