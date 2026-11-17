import XCTest
import NovelWorkspace

final class EditorWorkspaceTests: XCTestCase {
    func testDirectionsCreateOneAuxiliaryThenMoveItWithoutChangingDocuments() throws {
        let first = UUID(), second = UUID()
        var layout = EditorWorkspaceLayout(documentID: first)
        let primary = layout.primary.id
        XCTAssertTrue(layout.arrange(.right))
        let auxiliary = try XCTUnwrap(layout.auxiliary?.id)
        layout.open(second)
        for direction in SplitDirection.allCases + SplitDirection.allCases.reversed() {
            _ = layout.arrange(direction)
            XCTAssertEqual(layout.root.panes.count, 2)
            XCTAssertEqual(layout.primary, EditorPane(id: primary, documentID: first))
            XCTAssertEqual(layout.auxiliary, EditorPane(id: auxiliary, documentID: second))
            guard case .split(let branch) = layout.root else { return XCTFail("Expected paired editors") }
            XCTAssertEqual(branch.axis, direction.axis)
            XCTAssertEqual(branch.first.id, direction.insertsFirst ? auxiliary : primary)
        }
    }

    func testDirectionButtonsDoNotDependOnActiveEditorAndSameDirectionIsNoOp() throws {
        var layout = EditorWorkspaceLayout(documentID: UUID())
        layout.arrange(.down)
        layout.activate(layout.primary.id)
        let before = layout.snapshot
        XCTAssertFalse(layout.arrange(.down))
        XCTAssertEqual(layout.snapshot, before)
        layout.arrange(.left)
        XCTAssertEqual(layout.activePaneID, before.activePaneID)
        XCTAssertEqual(layout.auxiliary, before.auxiliary)
        layout.undo()
        XCTAssertEqual(layout.snapshot, before)
        layout.undo()
        XCTAssertNil(layout.auxiliary)
    }

    func testCloseAndUndoKeepExactPaneIDsAndBothDocumentSelections() throws {
        var layout = EditorWorkspaceLayout(documentID: UUID())
        XCTAssertFalse(layout.closeAuxiliary())
        layout.arrange(.up); layout.open(UUID())
        let before = layout.snapshot
        XCTAssertTrue(layout.closeAuxiliary())
        XCTAssertEqual(layout.root.panes, [before.primary])
        XCTAssertEqual(layout.activePaneID, before.primary.id)
        layout.undo()
        XCTAssertEqual(layout.snapshot, before)
    }

    func testEditorSnapshotRoundTripAndInvalidPreferencesAreRejected() throws {
        let a = UUID(), b = UUID()
        var layout = EditorWorkspaceLayout(documentID: a)
        layout.arrange(.left); layout.open(b); layout.resize(0.4)
        let snapshot = try JSONDecoder().decode(EditorWorkspaceSnapshot.self, from: JSONEncoder().encode(layout.snapshot))
        XCTAssertEqual(EditorWorkspaceLayout(restoring: snapshot, validDocumentIDs: [a, b])?.snapshot, snapshot)
        XCTAssertNil(EditorWorkspaceLayout(restoring: snapshot, validDocumentIDs: [a]))
        var invalid = snapshot
        invalid.auxiliary = EditorPane(id: invalid.primary.id, documentID: b)
        XCTAssertNil(EditorWorkspaceLayout(restoring: invalid, validDocumentIDs: [a, b]))
        invalid = snapshot; invalid.primary.content = .manuscript
        XCTAssertNil(EditorWorkspaceLayout(restoring: invalid, validDocumentIDs: [a, b]))
        invalid = snapshot; invalid.primaryFraction = .nan
        XCTAssertNil(EditorWorkspaceLayout(restoring: invalid, validDocumentIDs: [a, b]))
    }

    func testLegacyLayoutRetainsFirstAndActiveEditorWithoutTouchingSourceSnapshot() throws {
        let documents = [UUID(), UUID(), UUID()]
        var legacy = WorkspaceLayout(documentID: documents[0], includingManuscript: true)
        let firstEditor = legacy.activePane
        legacy.split(.right); legacy.open(documents[1])
        legacy.split(.down); legacy.open(documents[2])
        let before = legacy.snapshot
        let migrated = try XCTUnwrap(EditorWorkspaceLayout(migrating: before, validDocumentIDs: Set(documents)))
        XCTAssertEqual(migrated.primary, firstEditor)
        XCTAssertEqual(migrated.auxiliary, legacy.activePane)
        XCTAssertEqual(migrated.activePaneID, legacy.activePaneID)
        XCTAssertEqual(migrated.root.panes.count, 2)
        XCTAssertTrue(migrated.root.panes.allSatisfy { $0.content == .editor })
        XCTAssertEqual(legacy.snapshot, before)
    }

    func testResizeAndWindowFittingAvoidOverlappingOrCrampedEditors() throws {
        var layout = EditorWorkspaceLayout(documentID: UUID())
        layout.arrange(.left); layout.resize(0.2)
        let before = layout.snapshot
        layout.resize(.nan)
        XCTAssertEqual(layout.snapshot, before)
        for direction in SplitDirection.allCases {
            layout.arrange(direction); layout.resize(0.15)
            let frames = layout.fittedRoot(in: WorkspaceRect(width: 498, height: 480))
                .frames(in: WorkspaceRect(width: 498, height: 480))
            for placement in frames.panes {
                if direction.axis == .horizontal { XCTAssertGreaterThanOrEqual(placement.rect.width, 240 - 0.001) }
                else { XCTAssertGreaterThanOrEqual(placement.rect.height, 180 - 0.001) }
            }
            XCTAssertEqual(frames.panes.count, 2)
        }
    }
}
