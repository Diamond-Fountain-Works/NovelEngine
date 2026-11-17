import Foundation
import Combine
import NovelDomain
import NovelStorage

enum ProjectSaveState: Equatable {
    case saved, pending, saving, failed(String)
    var title: String {
        switch self { case .saved: "已保存"; case .pending: "待保存"; case .saving: "保存中…"; case .failed: "保存失败" }
    }
}

@MainActor final class ManagedProjectSession: ObservableObject, Identifiable {
    let id: UUID
    let repository: ManagedProjectRepository
    @Published private(set) var project: NovelProject
    @Published private(set) var saveState = ProjectSaveState.saved
    @Published private(set) var importingCover = false
    @Published var coverError: String?
    private var revision: ProjectRevision
    private var serial = 0, savedSerial = 0
    private var writer: Task<Void, Never>?
    private var coverTask: Task<Void, Never>?
    private let didSave: (StoredProject) -> Void

    init(record: StoredProject, repository: ManagedProjectRepository, didSave: @escaping (StoredProject) -> Void = { _ in }) {
        project = record.project; revision = record.revision; id = record.project.id
        self.repository = repository; self.didSave = didSave
    }
    func replace(_ value: NovelProject) {
        guard value.id == id, value != project else { return }
        do { try value.validate() } catch { saveState = .failed(error.localizedDescription); return }
        project = value; project.updatedAt = Date(); serial += 1; saveState = .pending
        startWriter()
    }
    func edit(_ edit: (inout NovelProject) -> Void) { var changed = project; edit(&changed); replace(changed) }
    func flush() async throws {
        if let coverTask { await coverTask.value }
        startWriter()
        if let writer { await writer.value }
        if case .failed(let message) = saveState { throw NSError(domain: "NovelEngine.Save", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
    }
    func retry() { if serial != savedSerial { saveState = .pending; startWriter() } }
    func importCover(from url: URL) {
        guard coverTask == nil else { return }
        importingCover = true; coverError = nil
        coverTask = Task {
            defer { importingCover = false; coverTask = nil }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let ext = try await Task.detached { try CoverImages.fileExtension(at: url) }.value
                let cover = try await repository.addCover(from: url, fileExtension: ext, projectID: id)
                let copy = try await repository.coverURL(cover, projectID: id)
                _ = try await Task.detached { try CoverImages.thumbnail(at: copy) }.value
                edit { $0.details.cover = cover }
            } catch { coverError = error.localizedDescription }
        }
    }
    func export(to url: URL) async throws {
        if let coverTask { await coverTask.value }
        try await repository.exportProject(project, to: url)
    }
    private func startWriter() {
        guard writer == nil, serial != savedSerial else { return }
        writer = Task {
            try? await Task.sleep(for: .milliseconds(350))
            while serial != savedSerial {
                let target = serial, snapshot = project
                saveState = .saving
                do {
                    let result = try await repository.save(snapshot, expected: revision)
                    revision = result.revision; savedSerial = target; didSave(result)
                    saveState = serial == target ? .saved : .pending
                } catch { saveState = .failed(error.localizedDescription); break }
            }
            writer = nil
        }
    }
}
