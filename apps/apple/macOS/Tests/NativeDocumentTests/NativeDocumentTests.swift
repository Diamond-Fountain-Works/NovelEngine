import XCTest
import Foundation
import NovelDomain
@testable import NovelEngine

final class NativeDocumentTests: XCTestCase {
    func testReferencePackageRoundTripPreservesHierarchyAndLinks() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let person = WritingDocument(kind: .character, title: "合成人物", body: "  资料原文\r\n🙂\t", createdAt: date)
        let child = WritingDocument(kind: .character, title: "关系", parentID: person.id, createdAt: date)
        let event = WritingDocument(kind: .event, title: "合成事件", reference: ReferenceDetails(status: .confirmed, code: "E-01", timeAnchor: "T+2 月", participantIDs: [person.id]), createdAt: date)
        let project = NovelProject(documents: [person, child, event], createdAt: date)
        let root = ProcessInfo.processInfo.environment["NOVELENGINE_TEST_ROOT"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Codex/NovelEngine-资料模块-2026-11-17/DisposableTests", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appendingPathComponent("\(UUID().uuidString).novelengine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: url) }
        try NovelFileDocument(project: project).packageWrapper().write(to: url, options: .atomic, originalContentsURL: nil)
        XCTAssertEqual(try NovelFileDocument(fileWrapper: FileWrapper(url: url, options: .immediate)).project, project)
    }
    func testFileWrapperRoundTripPreservesChineseAndNotes() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章", body: "原文\n🙂", createdAt: date), WritingDocument(kind: .note, title: "笔记", body: "保留", createdAt: date)], createdAt: date)
        let wrapper = try NovelFileDocument(project: project).packageWrapper()
        XCTAssertEqual(try NovelFileDocument(fileWrapper: wrapper).project, project)
    }
    func testRealDiskSaveAndReopen() throws {
        let root = ProcessInfo.processInfo.environment["NOVELENGINE_TEST_ROOT"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Codex/NovelEngine-原生开发-2026-11-16/DisposableTests", isDirectory: true)
        let url = root.appendingPathComponent("\(UUID().uuidString).novelengine", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url) }
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "存档测试", body: "  原文\r\n\t第二行\n")])
        let document = NovelFileDocument(project: project)
        try document.packageWrapper().write(to: url, options: .atomic, originalContentsURL: nil)
        let reopened = try NovelFileDocument(fileWrapper: FileWrapper(url: url, options: .immediate))
        XCTAssertEqual(reopened.project.id, project.id)
        XCTAssertEqual(Array(reopened.project.documents[0].body.utf8), Array(project.documents[0].body.utf8))
    }
    func testSymbolicLinkCannotSupplyChapterText() throws {
        let project = NovelProject()
        let wrapper = try NovelFileDocument(project: project).packageWrapper()
        let texts = wrapper.fileWrappers!["documents"]!
        let name = "\(project.documents[0].id.uuidString.lowercased()).txt"
        texts.removeFileWrapper(texts.fileWrappers![name]!)
        let link = FileWrapper(symbolicLinkWithDestinationURL: URL(fileURLWithPath: "/private/blocked.txt"))
        link.preferredFilename = name; texts.addFileWrapper(link)
        XCTAssertThrowsError(try NovelFileDocument(fileWrapper: wrapper))
    }
    func testMalformedPackageIsNotReplacedWithNewProject() {
        XCTAssertThrowsError(try NovelFileDocument(fileWrapper: FileWrapper(directoryWithFileWrappers: [:])))
    }
}
