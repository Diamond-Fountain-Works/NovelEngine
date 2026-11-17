import Foundation
import NovelDomain

public enum ProjectEditingError: Error, Equatable { case documentNotFound, invalidOrder }

/// Applies explicit author edits without normalizing, trimming or rewriting prose.
public struct ProjectEditingService: Sendable {
    private let now: @Sendable () -> Date
    public init(now: @escaping @Sendable () -> Date = { Date() }) { self.now = now }

    @discardableResult public func add(_ kind: WritingKind, to project: inout NovelProject) -> UUID {
        let date = now()
        let number = project.documents.filter { $0.kind == kind }.count + 1
        let document = WritingDocument(kind: kind, title: kind == .chapter ? "第\(number)章" : "笔记 \(number)", createdAt: date)
        project.documents.append(document); project.updatedAt = date
        return document.id
    }
    public func update(_ id: UUID, in project: inout NovelProject, edit: (inout WritingDocument) -> Void) throws {
        guard let index = project.documents.firstIndex(where: { $0.id == id }) else { throw ProjectEditingError.documentNotFound }
        var updated = project.documents[index]
        edit(&updated)
        guard updated != project.documents[index] else { return }
        updated.updatedAt = now(); project.documents[index] = updated; project.updatedAt = updated.updatedAt
    }
    public func renameProject(_ title: String, in project: inout NovelProject) {
        guard title != project.title else { return }
        project.title = title; project.updatedAt = now()
    }
    public func reorder(_ ids: [UUID], in project: inout NovelProject) throws {
        guard ids.count == project.documents.count, Set(ids).count == ids.count, Set(ids) == Set(project.documents.map(\.id)) else { throw ProjectEditingError.invalidOrder }
        let lookup = Dictionary(uniqueKeysWithValues: project.documents.map { ($0.id, $0) })
        project.documents = ids.compactMap { lookup[$0] }; project.updatedAt = now()
    }
}
