import XCTest
import NovelDomain
import NovelApplication
import NovelStorage

final class ProjectTests: XCTestCase {
    let date = Date(timeIntervalSince1970: 1_700_000_000)

    func testNewProjectHasOneEmptyChapter() {
        let project = NovelProject()
        XCTAssertEqual(project.documents.count, 1)
        XCTAssertEqual(project.documents[0].body, "")
        XCTAssertEqual(project.statistics.characters, 0)
    }
    func testExplicitEditPreservesUnicodeWhitespaceAndLineEndings() throws {
        var project = NovelProject(createdAt: date)
        let text = "  中文 e\u{301} 👩🏽‍💻\r\n\n尾行\t\n"
        try ProjectEditingService().update(project.documents[0].id, in: &project) { $0.body = text }
        XCTAssertEqual(Array(project.documents[0].body.utf8), Array(text.utf8))
    }
    func testMissingDocumentDoesNotChangeOtherProse() {
        var project = NovelProject(createdAt: date); let original = project
        XCTAssertThrowsError(try ProjectEditingService().update(UUID(), in: &project) { $0.body = "changed" })
        XCTAssertEqual(project, original)
    }
    func testNoOpDoesNotChangeModificationDate() throws {
        var project = NovelProject(createdAt: date)
        let later = date.addingTimeInterval(60)
        try ProjectEditingService(now: { later }).update(project.documents[0].id, in: &project) { $0.body = "" }
        XCTAssertEqual(project.updatedAt, date)
    }
    func testAddNoteDoesNotDuplicateChapter() {
        var project = NovelProject(createdAt: date)
        let chapter = project.documents[0].id
        let note = ProjectEditingService().add(.note, to: &project)
        XCTAssertNotEqual(chapter, note)
        XCTAssertEqual(project.documents.filter { $0.kind == .chapter }.count, 1)
        XCTAssertEqual(project.document(note)?.kind, .note)
    }
    func testReorderRequiresExactPermutation() throws {
        var project = NovelProject(createdAt: date)
        let service = ProjectEditingService(); let second = service.add(.chapter, to: &project)
        let first = project.documents[0].id
        XCTAssertThrowsError(try service.reorder([first, first], in: &project))
        try service.reorder([second, first], in: &project)
        XCTAssertEqual(project.documents.map(\.id), [second, first])
    }
    func testUnicodeCharacterAndParagraphCounts() {
        XCTAssertEqual(TextStatistics("中 文\n\n👩🏽‍💻\tA"), TextStatistics(characters: 4, paragraphs: 2))
    }
    func testPackageRoundTripPreservesAllAuthorFieldsAndStableIDs() throws {
        let original = NovelProject(title: "作品", documents: [WritingDocument(kind: .chapter, title: "章一", body: "  中文\r\n\n🙂\t", synopsis: "摘要", createdAt: date), WritingDocument(kind: .note, title: "笔记", body: "另一个正文", createdAt: date)], createdAt: date)
        let codec = ProjectPackageCodec()
        let files = try codec.encode(original)
        XCTAssertEqual(try codec.decode(files), original)
        XCTAssertEqual(files.count, 3)
        XCTAssertTrue(files.keys.allSatisfy { !$0.hasPrefix("/") && !$0.contains("..") })
    }
    func testMissingBodyIsAnErrorRatherThanAnEmptyReplacement() throws {
        let project = NovelProject(createdAt: date); let codec = ProjectPackageCodec()
        var files = try codec.encode(project); files.removeValue(forKey: ProjectPackageCodec.textPath(project.documents[0].id))
        XCTAssertThrowsError(try codec.decode(files)) { XCTAssertEqual($0 as? ProjectFormatError, .missingText(project.documents[0].id)) }
    }
    func testCorruptedUTF8IsRejected() throws {
        let project = NovelProject(createdAt: date); let codec = ProjectPackageCodec()
        var files = try codec.encode(project); files[ProjectPackageCodec.textPath(project.documents[0].id)] = Data([0xff, 0xfe])
        XCTAssertThrowsError(try codec.decode(files))
    }
    func testFutureSchemaIsRejectedWithoutRewriting() {
        let data = Data(#"{"schemaVersion":99}"#.utf8)
        XCTAssertThrowsError(try ProjectPackageCodec().decode(["project.json": data])) { XCTAssertEqual($0 as? ProjectFormatError, .unsupportedVersion(99)) }
    }
    func testDuplicateDocumentIDIsRejected() {
        let doc = WritingDocument(kind: .chapter, title: "章", createdAt: date)
        XCTAssertThrowsError(try ProjectPackageCodec().encode(NovelProject(documents: [doc, doc])))
    }
    func testLargeChapterRoundTrip() throws {
        let text = String(repeating: "测试正文\n", count: 100_000)
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "长章", body: text)])
        let codec = ProjectPackageCodec()
        XCTAssertEqual(try codec.decode(codec.encode(project)).documents[0].body, text)
    }
}
