import XCTest
import NovelDomain
import NovelApplication
import NovelStorage

final class ReferenceLibraryTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)
    func testPrerequisiteOptionsExcludeTransitiveDescendants() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService()
        let first = service.add(.event, to: &project), second = service.add(.event, to: &project)
        let third = service.add(.event, to: &project), independent = service.add(.event, to: &project)
        try service.update(second, in: &project) { $0.reference?.prerequisiteIDs = [first] }
        try service.update(third, in: &project) { $0.reference?.prerequisiteIDs = [second] }
        XCTAssertEqual(ProjectLibrary.availablePrerequisiteIDs(for: first, in: project), [independent])
        XCTAssertEqual(ProjectLibrary.availablePrerequisiteIDs(for: second, in: project), [first, independent])
        XCTAssertTrue(ProjectLibrary.availablePrerequisiteIDs(for: project.documents[0].id, in: project).isEmpty)
    }
    func testCharacterSubdocumentIsNotASeparateEventParticipant() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService()
        let person = service.add(.character, to: &project)
        let child = try service.addChild(to: person, in: &project)
        let event = service.add(.event, to: &project)
        let before = project
        XCTAssertThrowsError(try service.update(event, in: &project) { $0.reference?.participantIDs = [child] })
        XCTAssertEqual(project, before)
        try service.update(event, in: &project) { $0.reference?.participantIDs = [person] }
    }
    func testExplicitUnicodeNormalizationEditIsNotDiscardedAsANoOp() throws {
        var project = NovelProject(title: "e\u{301}", documents: [WritingDocument(kind: .character, title: "e\u{301}", body: "e\u{301}", createdAt: date)], createdAt: date)
        let id = project.documents[0].id
        let service = ProjectEditingService()
        try service.update(id, in: &project) { $0.title = "é"; $0.body = "é"; $0.reference?.code = "é" }
        service.renameProject("é", in: &project)
        XCTAssertEqual(Array(project.documents[0].body.utf8), Array("é".utf8))
        XCTAssertEqual(Array(project.documents[0].title.utf8), Array("é".utf8))
        XCTAssertEqual(Array(project.title.utf8), Array("é".utf8))
        try service.update(id, in: &project) { $0.reference?.code = "e\u{301}" }
        XCTAssertEqual(Array(project.documents[0].reference!.code.utf8), Array("e\u{301}".utf8))
    }

    func testEveryModuleCreatesTypedEmptyTemplatesWithoutFiction() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService(now: { Date(timeIntervalSince1970: 1_700_000_001) })
        for kind in WritingKind.allCases {
            let id = service.add(kind, to: &project)
            let document = try XCTUnwrap(project.document(id))
            XCTAssertEqual(document.kind, kind)
            XCTAssertEqual(document.reference != nil, kind.isReference)
            XCTAssertEqual(document.body, DocumentTemplates.body(for: kind))
            XCTAssertEqual(document.reference?.status, kind.isReference ? .undecided : nil)
        }
        try project.validate()
        XCTAssertEqual(LibrarySection.allCases.count, 5)
        XCTAssertEqual(project.documents.filter { $0.kind == .character }.count, 1)
    }

    func testSubdocumentsKeepIndependentProseAndStableParent() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService(); let person = service.add(.character, to: &project)
        let child = try service.addChild(to: person, in: &project)
        let text = "  独立原文 e\u{301}\r\n🙂\t"
        let original = project.document(person)
        try service.update(child, in: &project) { $0.body = text }
        XCTAssertEqual(project.document(person), original)
        XCTAssertEqual(project.document(child)?.parentID, person)
        XCTAssertEqual(project.document(child)?.kind, .character)
        XCTAssertEqual(project.document(child)?.body, text)
        XCTAssertThrowsError(try service.addChild(to: project.documents[0].id, in: &project))
    }

    func testEditingBadParentOrCycleIsAtomic() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService(); let root = service.add(.character, to: &project)
        let child = try service.addChild(to: root, in: &project)
        let before = project
        let chapterID = project.documents[0].id
        XCTAssertThrowsError(try service.update(root, in: &project) { $0.parentID = child })
        XCTAssertEqual(project, before)
        XCTAssertThrowsError(try service.update(child, in: &project) { $0.parentID = chapterID })
        XCTAssertEqual(project, before)
    }

    func testEventParticipantsAndDependenciesUseIDsRatherThanCopiedProse() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService(); let person = service.add(.character, to: &project)
        let first = service.add(.event, to: &project), second = service.add(.event, to: &project)
        let original = project.document(person)
        try service.update(second, in: &project) {
            $0.reference = ReferenceDetails(status: .confirmed, code: "E-002", tags: ["主线"], timeAnchor: "T+3 月", participantIDs: [person], prerequisiteIDs: [first])
        }
        XCTAssertEqual(project.document(person), original)
        XCTAssertEqual(ProjectLibrary.incomingReferences(to: first, in: project).map(\.id), [second])
        let before = project
        XCTAssertThrowsError(try service.update(first, in: &project) { $0.reference?.prerequisiteIDs = [second] })
        XCTAssertEqual(project, before)
        XCTAssertThrowsError(try service.update(second, in: &project) { $0.reference?.participantIDs = [first] })
        XCTAssertEqual(project, before)
        XCTAssertThrowsError(try service.update(second, in: &project) { $0.reference?.relatedIDs = [UUID()] })
        XCTAssertEqual(project, before)
    }

    func testLibrarySearchRetainsParentsAndFindsCodeAndTags() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService(); let root = service.add(.character, to: &project)
        let child = try service.addChild(to: root, in: &project)
        try service.update(child, in: &project) { $0.title = "关系笔记"; $0.reference?.tags = ["北方"]; $0.reference?.code = "P-02" }
        for query in ["关系", "北方", "p-02"] {
            let tree = ProjectLibrary.tree(in: project, kind: .character, query: query)
            XCTAssertEqual(tree.map(\.id), [root]); XCTAssertEqual(tree.first?.children.map(\.id), [child])
        }
        XCTAssertTrue(ProjectLibrary.tree(in: project, kind: .character, query: "不存在").isEmpty)
    }

    func testStoryOrderDoesNotFollowEventCodesAndSiblingMoveKeepsChildren() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService(); let first = service.add(.event, to: &project), second = service.add(.event, to: &project)
        let child = try service.addChild(to: first, in: &project)
        try service.update(first, in: &project) { $0.reference?.code = "E-100" }
        try service.update(second, in: &project) { $0.reference?.code = "E-001" }
        XCTAssertEqual(ProjectLibrary.tree(in: project, kind: .event).map(\.id), [first, second])
        try service.move(second, by: -1, in: &project)
        let tree = ProjectLibrary.tree(in: project, kind: .event)
        XCTAssertEqual(tree.map(\.id), [second, first]); XCTAssertEqual(tree.last?.children.map(\.id), [child])
    }

    func testReferenceContentDoesNotInflateManuscriptWordCount() {
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章", body: "正文"), WritingDocument(kind: .note, title: "笔记", body: "备忘"), WritingDocument(kind: .character, title: "人物", body: "人物资料")])
        XCTAssertEqual(project.manuscriptStatistics.characters, 2)
        XCTAssertEqual(project.statistics.characters, 8)
    }

    func testFormatTwoRoundTripRetainsLinksHierarchyMetadataAndOriginalBytes() throws {
        let person = WritingDocument(kind: .character, title: "合成人物", body: "  e\u{301}\r\n🙂\t", createdAt: date)
        let child = WritingDocument(kind: .character, title: "关系", parentID: person.id, createdAt: date)
        let event = WritingDocument(kind: .event, title: "合成事件", reference: ReferenceDetails(status: .confirmed, code: "E-001", timeAnchor: "T+1 月", relatedIDs: [child.id], participantIDs: [person.id]), createdAt: date)
        let project = NovelProject(documents: [person, child, event], createdAt: date)
        let codec = ProjectPackageCodec(); let files = try codec.encode(project)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: files["project.json"]!) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 2)
        XCTAssertEqual(try codec.decode(files), project)
        XCTAssertEqual(files[ProjectPackageCodec.textPath(person.id)], Data(person.body.utf8))
    }

    func testLegacyFormatOneDoesNotChangeIdentityTextOrRequireNewMetadata() throws {
        let manifest = Data(#"{"schemaVersion":1,"projectId":"00000000-0000-0000-0000-000000000001","title":"旧作品","createdAt":"2023-11-14T22:13:20Z","updatedAt":"2023-11-14T22:13:20Z","documents":[{"id":"00000000-0000-0000-0000-000000000002","kind":"chapter","title":"原章","synopsis":"原摘要","createdAt":"2023-11-14T22:13:20Z","updatedAt":"2023-11-14T22:13:20Z"}]}"#.utf8)
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let original = Data("  原文\r\n🙂\t".utf8)
        let codec = ProjectPackageCodec()
        let project = try codec.decode(["project.json": manifest, ProjectPackageCodec.textPath(id): original])
        XCTAssertEqual(project.documents[0].id, id); XCTAssertNil(project.documents[0].reference)
        let files = try codec.encode(project)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: files["project.json"]!) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 1)
        XCTAssertEqual(files[ProjectPackageCodec.textPath(id)], original)
    }

    func testForgedFormatOneAndBrokenReferencesAreRejected() throws {
        let person = WritingDocument(kind: .character, title: "人物", createdAt: date)
        let codec = ProjectPackageCodec(); var files = try codec.encode(NovelProject(documents: [person], createdAt: date))
        var manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: files["project.json"]!) as? [String: Any])
        manifest["schemaVersion"] = 1
        files["project.json"] = try JSONSerialization.data(withJSONObject: manifest)
        XCTAssertThrowsError(try codec.decode(files))
        var invalid = person; invalid.reference?.relatedIDs = [UUID()]
        XCTAssertThrowsError(try codec.encode(NovelProject(documents: [invalid])))
        var missing = person; missing.reference = nil
        XCTAssertThrowsError(try codec.encode(NovelProject(documents: [missing])))
    }
}
