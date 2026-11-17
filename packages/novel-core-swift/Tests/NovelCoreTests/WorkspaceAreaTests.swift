import XCTest
import NovelWorkspace

final class WorkspaceAreaTests: XCTestCase {
    func testSidebarAndEditorJoinUseTheSameSourceRule() throws {
        let doc = UUID()
        var layout = WorkspaceLayout(documentID: doc, includingManuscript: true)
        let sidebar = try XCTUnwrap(layout.root.panes.first { $0.content == .manuscript })
        let editor = layout.activePane
        let before = layout.snapshot
        XCTAssertTrue(layout.join(from: editor.id, toward: .left))
        XCTAssertEqual(layout.root.panes, [editor])
        layout.undo(); XCTAssertEqual(layout.snapshot, before)
        XCTAssertTrue(layout.join(from: sidebar.id, toward: .right))
        XCTAssertEqual(layout.root.panes, [sidebar])
        layout.undo(); XCTAssertEqual(layout.snapshot, before)
    }

    func testSidebarCanSplitAndSwitchTypeWithoutChangingDocumentReferences() throws {
        var layout = WorkspaceLayout(documentID: UUID(), includingManuscript: true)
        let editor = layout.activePane
        let sidebar = try XCTUnwrap(layout.root.panes.first { $0.content == .manuscript })
        layout.split(.down, in: sidebar.id)
        let newID = layout.activePaneID
        XCTAssertEqual(layout.activePane.content, .manuscript)
        XCTAssertEqual(layout.activePane.documentID, sidebar.documentID)
        layout.setContent(.inspector, in: newID)
        XCTAssertEqual(layout.activePane.content, .inspector)
        XCTAssertEqual(layout.root.panes.first { $0.id == editor.id }, editor)
        layout.undo()
        XCTAssertEqual(layout.activePane.content, .manuscript)
        XCTAssertEqual(layout.activePaneID, newID)
    }

    func testLegacyPaneDefaultsToEditorWithoutChangingIDs() throws {
        let id = UUID(), doc = UUID()
        let data = try JSONSerialization.data(withJSONObject: ["id": id.uuidString, "documentID": doc.uuidString])
        let pane = try JSONDecoder().decode(EditorPane.self, from: data)
        XCTAssertEqual(pane, EditorPane(id: id, documentID: doc))
    }

    func testDefaultLayoutRestorationHasItsOwnUndo() {
        var layout = WorkspaceLayout(documentID: UUID(), includingManuscript: true)
        layout.split(.down)
        let before = layout.snapshot, selected = layout.activePane.documentID
        layout.restoreWorkspace(documentID: selected)
        XCTAssertEqual(layout.root.panes.map(\.content), [.manuscript, .editor])
        XCTAssertEqual(layout.activePane.documentID, selected)
        layout.undo(); XCTAssertEqual(layout.snapshot, before)
    }

    func testPhysicalFramesCoverWindowWithoutOverlapAndIncludeDividers() {
        var layout = WorkspaceLayout(documentID: UUID(), includingManuscript: true)
        layout.split(.down); layout.split(.left)
        let bounds = WorkspaceRect(width: 1240, height: 800)
        let frames = layout.root.frames(in: bounds)
        let rects = frames.panes.map(\.rect) + frames.dividers.map(\.rect)
        XCTAssertEqual(rects.reduce(0) { $0 + $1.width * $1.height }, bounds.width * bounds.height, accuracy: 0.001)
        XCTAssertEqual(Set(frames.panes.map { $0.pane.id }), Set(layout.root.panes.map(\.id)))
        for (index, a) in rects.enumerated() {
            XCTAssertGreaterThanOrEqual(a.x, 0); XCTAssertGreaterThanOrEqual(a.y, 0)
            XCTAssertLessThanOrEqual(a.maxX, bounds.width + 0.001)
            XCTAssertLessThanOrEqual(a.maxY, bounds.height + 0.001)
            for b in rects.dropFirst(index + 1) {
                let overlap = max(0, min(a.maxX, b.maxX) - max(a.x, b.x)) * max(0, min(a.maxY, b.maxY) - max(a.y, b.y))
                XCTAssertEqual(overlap, 0, accuracy: 0.001)
            }
        }
    }
}
