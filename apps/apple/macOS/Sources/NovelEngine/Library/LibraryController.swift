import Foundation
import Combine
import NovelDomain
import NovelStorage

@MainActor final class LibraryController: ObservableObject {
    @Published private(set) var items: [StoredProject] = []
    @Published private(set) var sessions: [UUID: ManagedProjectSession] = [:]
    @Published private(set) var unreadableIDs: [String] = []
    let repository: ManagedProjectRepository?
    let storageURL: URL?
    let configurationError: String?

    init() {
        do {
            let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let url = try LibraryConfiguration.resolve(bundleID: Bundle.main.bundleIdentifier ?? "", qaRoot: Bundle.main.object(forInfoDictionaryKey: "NovelEngineQARoot") as? String, documents: documents)
            repository = ManagedProjectRepository(root: url); storageURL = url; configurationError = nil
        } catch { repository = nil; storageURL = nil; configurationError = error.localizedDescription }
    }
    init(repository: ManagedProjectRepository, root: URL) {
        self.repository = repository; storageURL = root; configurationError = nil
    }
    func refresh() async throws {
        guard let repository else { return }
        let catalog = try await repository.catalog(); items = catalog.projects; unreadableIDs = catalog.unreadableIDs
    }
    func create(title: String) async throws -> ManagedProjectSession {
        guard let repository else { throw LibraryConfigurationError.unexpectedQAOverride }
        let stored = try await repository.create(NovelProject(title: title))
        didSave(stored); return session(for: stored)
    }
    func open(_ id: UUID) async throws -> ManagedProjectSession {
        if let session = sessions[id] { return session }
        guard let repository else { throw LibraryConfigurationError.unexpectedQAOverride }
        return session(for: try await repository.load(id))
    }
    func importProject(from url: URL) async throws -> ManagedProjectSession {
        guard let repository else { throw LibraryConfigurationError.unexpectedQAOverride }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let stored = try await repository.importProject(from: url)
        didSave(stored); return session(for: stored)
    }
    func flushAll() async throws { for session in sessions.values { try await session.flush() } }
    private func session(for record: StoredProject) -> ManagedProjectSession {
        if let existing = sessions[record.project.id] { return existing }
        let session = ManagedProjectSession(record: record, repository: repository!) { [weak self] record in self?.didSave(record) }
        sessions[record.project.id] = session; return session
    }
    private func didSave(_ record: StoredProject) {
        items.removeAll { $0.project.id == record.project.id }; items.append(record)
        items.sort { $0.project.updatedAt > $1.project.updatedAt }
    }
}
