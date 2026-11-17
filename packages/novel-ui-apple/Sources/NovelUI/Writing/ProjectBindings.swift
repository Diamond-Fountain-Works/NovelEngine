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
                project.wrappedValue = changed
            } catch { reportError(error) }
        })
    }
    var projectTitle: Binding<String> {
        Binding(get: { project.wrappedValue.title }, set: { title in
            var changed = project.wrappedValue; service.renameProject(title, in: &changed); project.wrappedValue = changed
        })
    }
    func add(_ kind: WritingKind) -> UUID {
        var changed = project.wrappedValue
        let id = service.add(kind, to: &changed); project.wrappedValue = changed; return id
    }
}
