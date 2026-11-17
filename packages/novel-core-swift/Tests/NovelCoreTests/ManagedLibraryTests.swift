import XCTest
import Foundation
import NovelDomain
import NovelStorage

final class ManagedLibraryTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)
    private func root() throws -> URL {
        let base = ProcessInfo.processInfo.environment["NOVELENGINE_TEST_ROOT"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Codex/NovelEngine-Tests", isDirectory: true)
        let url = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testMetadataAndUnlimitedSynopsisRoundTripWithoutChangingProse() throws {
        let synopsis = String(repeating: "简介原文  e\u{301}🙂\r\n", count: 50_000)
        let details = ProjectDetails(author: "笔名", contributors: [Contributor(name: "共同作者", role: "设定")], genre: "长篇", tags: "原创，故事", synopsis: synopsis)
        let project = NovelProject(documents: [WritingDocument(kind: .chapter, title: "章", body: "  正文\t\n", createdAt: date)], details: details, createdAt: date)
        let files = try ProjectPackageCodec().encode(project)
        let header = try XCTUnwrap(JSONSerialization.jsonObject(with: files["project.json"]!) as? [String: Any])
        XCTAssertEqual(header["schemaVersion"] as? Int, 3)
        XCTAssertEqual(try ProjectPackageCodec().decode(files), project)
        XCTAssertEqual(Array(try ProjectPackageCodec().decode(files).details.synopsis.utf8), Array(synopsis.utf8))
    }

    func testCreateSaveReopenAndOnlyTwoVerifiedSnapshotsRemain() async throws {
        let root = try root(), repository = ManagedProjectRepository(root: root)
        var project = NovelProject(title: "原书名", createdAt: date)
        var stored = try await repository.create(project)
        for index in 0..<8 {
            project.title = "改名 \(index)"; project.documents[0].body = "原文 \(index)\n  🙂"
            stored = try await repository.save(project, expected: stored.revision)
        }
        let reopened = try await ManagedProjectRepository(root: root).load(project.id)
        XCTAssertEqual(reopened.project, project)
        XCTAssertEqual(reopened.revision, stored.revision)
        let folder = root.appendingPathComponent("作品/\(project.id.uuidString.lowercased())/revisions")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path).count, 2)
    }

    func testStaleWriterCannotOverwriteAnotherCommit() async throws {
        let url = try root(), a = ManagedProjectRepository(root: url), b = ManagedProjectRepository(root: url)
        let stored = try await a.create(NovelProject(createdAt: date))
        var first = stored.project; first.documents[0].body = "先保存的原文"
        _ = try await a.save(first, expected: stored.revision)
        var stale = stored.project; stale.documents[0].body = "另一窗口的草稿"
        do { _ = try await b.save(stale, expected: stored.revision); XCTFail("Stale save accepted") }
        catch { XCTAssertEqual(error as? LibraryError, .changedOnDisk) }
        let loaded = try await a.load(first.id)
        XCTAssertEqual(loaded.project.documents[0].body, "先保存的原文")
    }

    func testUnpublishedCrashSnapshotDoesNotReplaceCurrentProject() async throws {
        let url = try root(), repository = ManagedProjectRepository(root: url)
        let stored = try await repository.create(NovelProject(createdAt: date))
        let orphan = url.appendingPathComponent("作品/\(stored.project.id.uuidString.lowercased())/revisions/\(UUID().uuidString.lowercased())")
        try FileManager.default.createDirectory(at: orphan, withIntermediateDirectories: true)
        try Data("incomplete".utf8).write(to: orphan.appendingPathComponent("project.json"))
        let restored = try await ManagedProjectRepository(root: url).load(stored.project.id)
        XCTAssertEqual(restored.revision, stored.revision)
        XCTAssertEqual(restored.project, stored.project)
    }

    func testDirectDiskEditIsDetectedAndNotSilentlyOverwritten() async throws {
        let url = try root(), repository = ManagedProjectRepository(root: url)
        let stored = try await repository.create(NovelProject(createdAt: date))
        let text = url.appendingPathComponent("作品/\(stored.project.id.uuidString.lowercased())/revisions/\(stored.revision.generation.uuidString.lowercased())/\(ProjectPackageCodec.textPath(stored.project.documents[0].id))")
        try Data("外部编辑保留".utf8).write(to: text)
        do { _ = try await repository.save(stored.project, expected: stored.revision); XCTFail("Overwrote external edits") }
        catch { XCTAssertEqual(error as? LibraryError, .changedOnDisk) }
        XCTAssertEqual(try String(contentsOf: text, encoding: .utf8), "外部编辑保留")
    }

    func testImportAndExportPreserveIDsReferencesAndOriginalPackage() async throws {
        let url = try root(), a = ManagedProjectRepository(root: url.appendingPathComponent("A")), b = ManagedProjectRepository(root: url.appendingPathComponent("B"))
        let person = WritingDocument(kind: .character, title: "人物", body: "  原文🙂\n", createdAt: date)
        let event = WritingDocument(kind: .event, title: "事件", reference: ReferenceDetails(participantIDs: [person.id]), createdAt: date)
        let project = NovelProject(documents: [person, event], details: ProjectDetails(author: "作者", synopsis: "简介"), createdAt: date)
        _ = try await a.create(project)
        let file = url.appendingPathComponent("作品.ne")
        try await a.exportProject(project, to: file)
        let before = try Data(contentsOf: file.appendingPathComponent("project.json"))
        let imported = try await b.importProject(from: file)
        XCTAssertEqual(imported.project, project)
        XCTAssertEqual(try Data(contentsOf: file.appendingPathComponent("project.json")), before)
        let duplicate = try await b.importProject(from: file)
        XCTAssertEqual(duplicate.revision, imported.revision)
        var changed = project; changed.details.synopsis = "导出后的新简介"
        try await a.exportProject(changed, to: file)
        do { _ = try await b.importProject(from: file); XCTFail("Different project silently overwrote library") }
        catch { XCTAssertEqual(error as? LibraryError, .duplicateProject) }
    }

    func testOriginalCoverBytesSurviveRestartAndExport() async throws {
        let url = try root(), a = ManagedProjectRepository(root: url.appendingPathComponent("A")), b = ManagedProjectRepository(root: url.appendingPathComponent("B"))
        var stored = try await a.create(NovelProject(createdAt: date))
        let bytes = Data((0..<170_000).map { UInt8($0 % 251) }), source = url.appendingPathComponent("synthetic-original.bin")
        try bytes.write(to: source)
        let cover = try await a.addCover(from: source, fileExtension: "png", projectID: stored.project.id)
        var project = stored.project; project.details.cover = cover
        stored = try await a.save(project, expected: stored.revision)
        let export = url.appendingPathComponent("封面.ne")
        try await a.exportProject(stored.project, to: export)
        XCTAssertEqual(try Data(contentsOf: export.appendingPathComponent(cover.relativePath)), bytes)
        let imported = try await b.importProject(from: export)
        let path = try await b.coverURL(cover, projectID: imported.project.id)
        XCTAssertEqual(try Data(contentsOf: path), bytes)
        let reopened = try await ManagedProjectRepository(root: url.appendingPathComponent("B")).load(project.id)
        XCTAssertEqual(reopened.project.details.cover, cover)
        try Data([9]).write(to: export.appendingPathComponent("assets/undeclared.png"))
        let third = ManagedProjectRepository(root: url.appendingPathComponent("C"))
        do { _ = try await third.importProject(from: export); XCTFail("Silently discarded undeclared media") }
        catch { XCTAssertEqual(error as? LibraryError, .invalidFile) }
    }

    func testCorruptCoverAndSymlinkAreRejected() async throws {
        let url = try root(), repository = ManagedProjectRepository(root: url.appendingPathComponent("library"))
        let stored = try await repository.create(NovelProject(createdAt: date))
        let source = url.appendingPathComponent("source.png"), link = url.appendingPathComponent("link.png")
        try Data([1, 2, 3]).write(to: source)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: source)
        do { _ = try await repository.addCover(from: link, fileExtension: "png", projectID: stored.project.id); XCTFail("Accepted symlink") } catch {}
        let cover = try await repository.addCover(from: source, fileExtension: "png", projectID: stored.project.id)
        var project = stored.project; project.details.cover = cover
        _ = try await repository.save(project, expected: stored.revision)
        let path = try await repository.coverURL(cover, projectID: project.id)
        try Data([4, 5, 6]).write(to: path)
        do { _ = try await repository.load(project.id); XCTFail("Accepted damaged cover") }
        catch { XCTAssertEqual(error as? LibraryError, .damagedCover) }
    }

    func testCatalogReportsBadProjectWithoutHidingHealthyProject() async throws {
        let url = try root(), repository = ManagedProjectRepository(root: url)
        let project = NovelProject(createdAt: date)
        _ = try await repository.create(project)
        let broken = UUID().uuidString.lowercased()
        try FileManager.default.createDirectory(at: url.appendingPathComponent("作品/\(broken)"), withIntermediateDirectories: true)
        let catalog = try await repository.catalog()
        XCTAssertEqual(catalog.projects.map(\.project.id), [project.id])
        XCTAssertEqual(catalog.unreadableIDs, [broken])
    }
}
