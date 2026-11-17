import SwiftUI
import NovelDomain
import NovelApplication

@MainActor struct ProjectBindings {
    var project: Binding<NovelProject>
    var reportError: (Error) -> Void
    private let service = ProjectEditingService()

    func field(_ keyPath: WritableKeyPath<WritingDocument, String>, documentID: UUID) -> Binding<String> {
        Binding(get: { project.wrappedValue.document(documentID)?[keyPath: keyPath] ?? "" }, set: { text in
            var changed = project.wrappedValue
            do {
                try service.update(documentID, in: &changed) { $0[keyPath: keyPath] = text }
                commit(changed)
            } catch { reportError(error) }
        })
    }
    var projectTitle: Binding<String> {
        Binding(get: { project.wrappedValue.title }, set: { title in
            var changed = project.wrappedValue; service.renameProject(title, in: &changed); commit(changed)
        })
    }
    func add(_ kind: WritingKind) -> UUID {
        var changed = project.wrappedValue
        let id = service.add(kind, to: &changed); project.wrappedValue = changed; return id
    }
    func addChild(to parentID: UUID) -> UUID? {
        var changed = project.wrappedValue
        do {
            let id = try service.addChild(to: parentID, in: &changed); project.wrappedValue = changed; return id
        } catch { reportError(error); return nil }
    }
    func reference<Value>(_ keyPath: WritableKeyPath<ReferenceDetails, Value>, documentID: UUID) -> Binding<Value> {
        Binding(get: { (project.wrappedValue.document(documentID)?.reference ?? ReferenceDetails())[keyPath: keyPath] }, set: { value in
            var changed = project.wrappedValue
            do {
                try service.update(documentID, in: &changed) { $0.reference?[keyPath: keyPath] = value }
                commit(changed)
            } catch { reportError(error) }
        })
    }
    func move(_ id: UUID, by offset: Int) {
        var changed = project.wrappedValue
        do { try service.move(id, by: offset, in: &changed); project.wrappedValue = changed }
        catch { reportError(error) }
    }
    private func commit(_ changed: NovelProject) {
        if changed != project.wrappedValue { project.wrappedValue = changed }
    }
}
