import XCTest
import NovelWorkspace

final class WorkspaceTests: XCTestCase {
    func testFourDirectionsUseCorrectOrderAndSharedDocument() {
        for direction in SplitDirection.allCases {
            let document = UUID(); var layout = WorkspaceLayout(documentID: document)
            let oldID = layout.activePaneID; layout.split(direction)
            guard case .split(let branch) = layout.root else { return XCTFail() }
            XCTAssertEqual(branch.axis, direction.axis)
            XCTAssertEqual(branch.first.id == oldID, !direction.insertsFirst)
            XCTAssertEqual(Set(layout.root.panes.map(\.documentID)), [document])
        }
    }
    func testNestedJoinAndUndoPreserveExactTreeAndDocumentReferences() {
        var layout = WorkspaceLayout(documentID: UUID())
        layout.split(.right); let other = UUID(); layout.open(other); layout.split(.down)
        let before = layout.snapshot
        XCTAssertTrue(layout.join(from: layout.activePaneID, toward: .up))
        XCTAssertEqual(layout.root.panes.count, 2)
        XCTAssertEqual(layout.activePane.documentID, other)
        layout.undo(); XCTAssertEqual(layout.snapshot, before)
    }
    func testInvalidJoinDoesNotChangeLayout() {
        var layout = WorkspaceLayout(documentID: UUID()); layout.split(.right)
        let before = layout.snapshot
        XCTAssertFalse(layout.join(from: layout.activePaneID, toward: .up))
        XCTAssertEqual(layout.snapshot, before)
    }
    func testJoinExpandsSourceTowardNeighbourInAllFourDirections() {
        for direction in SplitDirection.allCases {
            let sourceDocument = UUID(); var layout = WorkspaceLayout(documentID: sourceDocument)
            let source = layout.activePaneID
            layout.split(direction); layout.open(UUID())
            XCTAssertTrue(layout.join(from: source, toward: direction))
            XCTAssertEqual(layout.root.panes.count, 1)
            XCTAssertEqual(layout.activePaneID, source)
            XCTAssertEqual(layout.activePane.documentID, sourceDocument)
        }
    }
    func testResizeClampsAndRejectsNaN() {
        var layout = WorkspaceLayout(documentID: UUID()); layout.split(.right)
        layout.resize(layout.root.id, ratio: 4)
        guard case .split(let branch) = layout.root else { return XCTFail() }
        XCTAssertEqual(branch.ratio, 0.85)
        let before = layout.snapshot; layout.resize(layout.root.id, ratio: .nan)
        XCTAssertEqual(layout.snapshot, before)
    }
    func testResetKeepsActiveDocumentAndUndoRestoresLayout() {
        var layout = WorkspaceLayout(documentID: UUID()); layout.split(.left)
        let before = layout.snapshot; let id = layout.activePaneID
        layout.reset(); XCTAssertEqual(layout.root.panes.count, 1); XCTAssertEqual(layout.activePaneID, id)
        layout.undo(); XCTAssertEqual(layout.snapshot, before)
    }
    func testLayoutSnapshotRoundTripAndStaleDocumentRejection() throws {
        let doc = UUID(); var layout = WorkspaceLayout(documentID: doc); layout.split(.down)
        let snapshot = try JSONDecoder().decode(WorkspaceSnapshot.self, from: JSONEncoder().encode(layout.snapshot))
        XCTAssertEqual(WorkspaceLayout(restoring: snapshot, validDocumentIDs: [doc])?.snapshot, snapshot)
        XCTAssertNil(WorkspaceLayout(restoring: snapshot, validDocumentIDs: [UUID()]))
    }
    func testPaneIDsRemainUniqueAfterUndoAndSplit() {
        var layout = WorkspaceLayout(documentID: UUID()); layout.split(.right); layout.undo(); layout.split(.left)
        XCTAssertEqual(Set(layout.root.panes.map(\.id)).count, 2)
    }
    func testSplitTargetsExplicitInactivePane() {
        var layout = WorkspaceLayout(documentID: UUID())
        let left = layout.activePaneID
        layout.split(.right); let right = layout.activePaneID
        layout.split(.down, in: left)
        XCTAssertEqual(layout.root.panes.count, 3)
        XCTAssertNotEqual(layout.activePaneID, right)
        XCTAssertEqual(layout.root.placements().first { $0.pane.id == right }?.rect, WorkspaceRect(x: 0.5, y: 0, width: 0.5, height: 1))
    }
    func testCrossBranchJoinPreservesOtherAreasAndSourceIdentity() {
        var (layout, ids) = grid()
        let before = layout.root.placements()
        let topLeft = ids[0], topRight = ids[1]
        XCTAssertTrue(layout.join(from: topLeft, toward: .right))
        XCTAssertEqual(Set(layout.root.panes.map(\.id)), Set(ids.filter { $0 != topRight }))
        let after = layout.root.placements()
        XCTAssertEqual(after.first { $0.pane.id == topLeft }?.rect, WorkspaceRect(x: 0, y: 0, width: 1, height: 0.5))
        for id in ids.suffix(2) {
            XCTAssertEqual(after.first { $0.pane.id == id }?.rect, before.first { $0.pane.id == id }?.rect)
        }
        XCTAssertNotNil(WorkspaceLayout(restoring: layout.snapshot, validDocumentIDs: Set(layout.root.panes.map(\.documentID))))
    }
    func testBoundaryMenuUsesPointerRowRatherThanActiveGroup() {
        var (layout, ids) = grid()
        layout.activate(ids[3])
        let upper = layout.boundaryJoins(layout.root.id, fraction: 0.25)
        let lower = layout.boundaryJoins(layout.root.id, fraction: 0.75)
        XCTAssertEqual(upper.map(\.sourceID), [ids[0], ids[1]])
        XCTAssertEqual(lower.map(\.sourceID), [ids[2], ids[3]])
        XCTAssertEqual(upper.map(\.direction), [.right, .left])
        XCTAssertTrue(layout.join(from: upper[0].sourceID, toward: upper[0].direction))
        XCTAssertEqual(layout.root.panes.count, 3)
        XCTAssertTrue(layout.root.panes.contains { $0.id == ids[3] })
    }
    func testUnequalEdgeDoesNotOfferWholeSubtreeDeletion() {
        var layout = WorkspaceLayout(documentID: UUID()); let left = layout.activePaneID
        layout.split(.right); layout.split(.down)
        let original = layout.snapshot
        XCTAssertTrue(layout.joinOptions(from: left).isEmpty)
        XCTAssertTrue(layout.boundaryJoins(layout.root.id, fraction: 0.25).isEmpty)
        XCTAssertFalse(layout.join(from: left, toward: .right))
        XCTAssertEqual(layout.snapshot, original)
    }
    func testCloseRemovesOnePaneAndUndoRestoresEverything() {
        var (layout, ids) = grid(); layout.activate(ids[0]); let original = layout.snapshot
        XCTAssertTrue(layout.close(ids[0]))
        XCTAssertEqual(layout.root.panes.count, 3)
        XCTAssertEqual(Set(layout.root.panes.map(\.id)), Set(ids.dropFirst()))
        XCTAssertTrue(layout.root.panes.contains { $0.id == layout.activePaneID })
        layout.undo(); XCTAssertEqual(layout.snapshot, original)
    }
    func testLastAndMissingPaneCannotBeClosed() {
        var layout = WorkspaceLayout(documentID: UUID()); let original = layout.snapshot
        XCTAssertFalse(layout.close(layout.activePaneID)); XCTAssertFalse(layout.close(UUID()))
        XCTAssertEqual(layout.snapshot, original); XCTAssertFalse(layout.canUndo)
    }
    func testBoundaryRejectsNonFiniteCoordinates() {
        var layout = WorkspaceLayout(documentID: UUID()); layout.split(.right)
        XCTAssertNil(layout.boundarySource(layout.root.id, fraction: .nan))
        XCTAssertTrue(layout.boundaryJoins(layout.root.id, fraction: .infinity).isEmpty)
    }
    private func grid() -> (WorkspaceLayout, [UUID]) {
        var layout = WorkspaceLayout(documentID: UUID()); let topLeft = layout.activePaneID
        layout.split(.right); let topRight = layout.activePaneID; layout.open(UUID())
        layout.activate(topLeft); layout.split(.down); let bottomLeft = layout.activePaneID; layout.open(UUID())
        layout.activate(topRight); layout.split(.down); let bottomRight = layout.activePaneID; layout.open(UUID())
        return (layout, [topLeft, topRight, bottomLeft, bottomRight])
    }

}
