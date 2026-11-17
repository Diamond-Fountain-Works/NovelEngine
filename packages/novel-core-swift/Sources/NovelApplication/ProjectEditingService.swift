import Foundation
import NovelDomain

public enum ProjectEditingError: LocalizedError, Equatable {
    case documentNotFound, invalidOrder, invalidRelationship
    public var errorDescription: String? {
        switch self {
        case .documentNotFound: "找不到文档。"
        case .invalidOrder: "文档顺序无效。"
        case .invalidRelationship: "关联无效，请检查文档类型、层级或循环引用。"
        }
    }
}

/// Applies explicit author edits without normalizing, trimming or rewriting prose.
public struct ProjectEditingService: Sendable {
    private let now: @Sendable () -> Date
    public init(now: @escaping @Sendable () -> Date = { Date() }) { self.now = now }

    @discardableResult public func add(_ kind: WritingKind, to project: inout NovelProject) -> UUID {
        let date = now()
        let number = project.documents.filter { $0.kind == kind }.count + 1
        let title = kind == .chapter ? "第\(number)章" : "\(kind.title) \(number)"
        let document = WritingDocument(kind: kind, title: title, body: DocumentTemplates.body(for: kind), createdAt: date)
        project.documents.append(document); project.updatedAt = date
        return document.id
    }
    @discardableResult public func addChild(to parentID: UUID, in project: inout NovelProject) throws -> UUID {
        guard let parent = project.document(parentID) else { throw ProjectEditingError.documentNotFound }
        guard parent.kind.isReference else { throw ProjectEditingError.invalidRelationship }
        let date = now()
        let document = WritingDocument(kind: parent.kind, title: "未命名子文档", parentID: parentID, createdAt: date)
        var changed = project; changed.documents.append(document); changed.updatedAt = date
        do { try changed.validate() } catch { throw ProjectEditingError.invalidRelationship }
        project = changed; return document.id
    }
    public func update(_ id: UUID, in project: inout NovelProject, edit: (inout WritingDocument) -> Void) throws {
        guard let index = project.documents.firstIndex(where: { $0.id == id }) else { throw ProjectEditingError.documentNotFound }
        var updated = project.documents[index]
        edit(&updated)
        guard updated != project.documents[index] else { return }
        updated.updatedAt = now()
        var changed = project; changed.documents[index] = updated; changed.updatedAt = updated.updatedAt
        do { try changed.validate() } catch { throw ProjectEditingError.invalidRelationship }
        project = changed
    }
    public func renameProject(_ title: String, in project: inout NovelProject) {
        guard !title.utf8.elementsEqual(project.title.utf8) else { return }
        project.title = title; project.updatedAt = now()
    }
    public func reorder(_ ids: [UUID], in project: inout NovelProject) throws {
        guard ids.count == project.documents.count, Set(ids).count == ids.count, Set(ids) == Set(project.documents.map(\.id)) else { throw ProjectEditingError.invalidOrder }
        let lookup = Dictionary(uniqueKeysWithValues: project.documents.map { ($0.id, $0) })
        project.documents = ids.compactMap { lookup[$0] }; project.updatedAt = now()
    }
    public func move(_ id: UUID, by offset: Int, in project: inout NovelProject) throws {
        guard let document = project.document(id) else { throw ProjectEditingError.documentNotFound }
        let siblings = project.documents.filter { $0.kind == document.kind && $0.parentID == document.parentID }
        guard let index = siblings.firstIndex(where: { $0.id == id }), siblings.indices.contains(index + offset), abs(offset) == 1,
              let from = project.documents.firstIndex(where: { $0.id == id }),
              let to = project.documents.firstIndex(where: { $0.id == siblings[index + offset].id }) else { throw ProjectEditingError.invalidOrder }
        project.documents.swapAt(from, to); project.updatedAt = now()
    }
}
