import XCTest
import Foundation
import NovelDomain
import NovelStorage
import CoreGraphics
import ImageIO
@testable import NovelEngine

final class ManagedSessionTests: XCTestCase {
    private func root() throws -> URL {
        let base = ProcessInfo.processInfo.environment["NOVELENGINE_TEST_ROOT"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Codex/NovelEngine-Tests")
        let root = base.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        return root
    }

    @MainActor func testImmediateFlushPersistsNewestOfRapidQueuedEdits() async throws {
        let url = try root(), repository = ManagedProjectRepository(root: url)
        let stored = try await repository.create(NovelProject())
        let session = ManagedProjectSession(record: stored, repository: repository)
        for i in 0..<80 { session.edit { $0.documents[0].body = "第\(i)次编辑\n原文  🙂" } }
        XCTAssertEqual(session.saveState, .pending)
        try await session.flush()
        XCTAssertEqual(session.saveState, .saved)
        let disk = try await repository.load(session.id)
        XCTAssertEqual(disk.project.documents[0].body, "第79次编辑\n原文  🙂")
        session.edit { $0.details.synopsis = String(repeating: "简介🙂\n", count: 20_000) }
        try await session.flush()
        let reopened = try await ManagedProjectRepository(root: url).load(session.id)
        XCTAssertTrue(reopened.project.details.synopsis.utf8.elementsEqual(session.project.details.synopsis.utf8))
    }

    @MainActor func testSaveFailureKeepsDraftAndDoesNotReportSaved() async throws {
        let url = try root(), repository = ManagedProjectRepository(root: url)
        let stored = try await repository.create(NovelProject())
        let a = ManagedProjectSession(record: stored, repository: repository)
        let b = ManagedProjectSession(record: stored, repository: ManagedProjectRepository(root: url))
        a.edit { $0.documents[0].body = "磁盘版本" }; try await a.flush()
        b.edit { $0.documents[0].body = "未覆盖的草稿" }
        do { try await b.flush(); XCTFail("Stale draft reported saved") } catch {}
        guard case .failed = b.saveState else { return XCTFail("Missing failure state") }
        XCTAssertEqual(b.project.documents[0].body, "未覆盖的草稿")
        let export = url.deletingLastPathComponent().appendingPathComponent("\(UUID().uuidString).ne")
        defer { try? FileManager.default.removeItem(at: export) }
        try await b.export(to: export)
        let other = ManagedProjectRepository(root: url.appendingPathComponent("other"))
        let recovered = try await other.importProject(from: export)
        XCTAssertEqual(recovered.project.documents[0].body, "未覆盖的草稿")
        let original = try await repository.load(a.id)
        XCTAssertEqual(original.project.documents[0].body, "磁盘版本")
    }

    @MainActor func testOneManagedSessionPerProjectAndRestartRetainsMetadata() async throws {
        let url = try root(), repository = ManagedProjectRepository(root: url)
        let controller = LibraryController(repository: repository, root: url)
        let session = try await controller.create(title: "测试书名")
        let same = try await controller.open(session.id)
        XCTAssertTrue(session === same)
        session.edit { $0.details.author = "测试作者"; $0.details.contributors = [Contributor(name: "测试合作者", role: "校对")] }
        try await controller.flushAll()
        let reopened = LibraryController(repository: ManagedProjectRepository(root: url), root: url)
        try await reopened.refresh()
        XCTAssertEqual(reopened.items.count, 1)
        let book = try await reopened.open(session.id)
        XCTAssertEqual(book.project.details.author, "测试作者")
        XCTAssertEqual(book.project.details.contributors.first?.role, "校对")
    }

    func testQAConfigurationFailsClosedWithoutIsolatedRoot() throws {
        let docs = URL(fileURLWithPath: "/example/Documents")
        XCTAssertThrowsError(try LibraryConfiguration.resolve(bundleID: "com.example.qa", qaRoot: nil, documents: docs))
        XCTAssertThrowsError(try LibraryConfiguration.resolve(bundleID: "com.example.qa", qaRoot: "/example/Documents/Novel Engine", documents: docs))
        XCTAssertThrowsError(try LibraryConfiguration.resolve(bundleID: "com.example.qa", qaRoot: "/example/Documents/Novel Engine/subdir", documents: docs))
        XCTAssertThrowsError(try LibraryConfiguration.resolve(bundleID: "com.example.qa", qaRoot: "/example/Documents", documents: docs))
        XCTAssertThrowsError(try LibraryConfiguration.resolve(bundleID: "com.example", qaRoot: "/example/QA", documents: docs))
        let qa = try LibraryConfiguration.resolve(bundleID: "com.example.qa", qaRoot: "/example/QA", documents: docs)
        XCTAssertEqual(qa.path, "/example/QA")
        let normal = try LibraryConfiguration.resolve(bundleID: "com.example", qaRoot: nil, documents: docs)
        XCTAssertEqual(normal.path, "/example/Documents/Novel Engine")
    }

    func testInvalidImageDoesNotProduceFakeThumbnailOrSilentlyCompressOriginal() throws {
        let folder = try root(), url = folder.appendingPathComponent("invalid.png")
        let data = Data("not a picture".utf8); try data.write(to: url)
        XCTAssertThrowsError(try CoverImages.fileExtension(at: url))
        XCTAssertThrowsError(try CoverImages.thumbnail(at: url))
        XCTAssertEqual(try Data(contentsOf: url), data)
    }

    func testValidCoverThumbnailLeavesOriginalImageBytesAndDimensionsIntact() throws {
        let folder = try root(), url = folder.appendingPathComponent("cover.png")
        let color = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(CGContext(data: nil, width: 900, height: 1350, bitsPerComponent: 8, bytesPerRow: 0, space: color, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray: 0.6, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 900, height: 1350))
        let original = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, original, nil); XCTAssertTrue(CGImageDestinationFinalize(destination))
        let bytes = try Data(contentsOf: url)
        XCTAssertEqual(try CoverImages.fileExtension(at: url), "png")
        let preview = try CoverImages.thumbnail(at: url)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(preview as CFData, nil))
        let thumbnail = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertLessThanOrEqual(max(thumbnail.width, thumbnail.height), 640)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let reread = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let full = try XCTUnwrap(CGImageSourceCreateImageAtIndex(reread, 0, nil))
        XCTAssertEqual(full.width, 900); XCTAssertEqual(full.height, 1350)
    }

    @MainActor func testLegacyFileIsImportedWithoutChangingItsSource() async throws {
        let folder = try root(), source = folder.appendingPathComponent("旧作品.novelengine")
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "旧章", body: "原文  🙂\n", createdAt: Date(timeIntervalSince1970: 1_700_000_000))], createdAt: Date(timeIntervalSince1970: 1_700_000_000))
        try NovelFileDocument(project: project).packageWrapper().write(to: source, options: .atomic, originalContentsURL: nil)
        let manifest = try Data(contentsOf: source.appendingPathComponent("project.json"))
        let repository = ManagedProjectRepository(root: folder.appendingPathComponent("library"))
        let imported = try await repository.importProject(from: source)
        XCTAssertEqual(imported.project, project)
        XCTAssertEqual(try Data(contentsOf: source.appendingPathComponent("project.json")), manifest)
        XCTAssertEqual(try NovelFileDocument(fileWrapper: FileWrapper(url: source, options: .immediate)).project, project)
    }
}
