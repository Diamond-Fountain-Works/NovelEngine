import Foundation
import NovelDomain

public struct LibraryNode: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let children: [LibraryNode]
}

public enum ProjectLibrary {
    /// A matching child keeps its ancestors visible. Story order comes from the author, never from event codes.
    public static func tree(in project: NovelProject, kind: WritingKind, query: String = "") -> [LibraryNode] {
        let documents = project.documents.filter { $0.kind == kind }
        let children = Dictionary(grouping: documents, by: \.parentID)
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        func nodes(_ parentID: UUID?) -> [LibraryNode] {
            (children[parentID] ?? []).compactMap { document in
                let descendants = nodes(document.id)
                let text = [document.title, document.reference?.code ?? ""] + (document.reference?.tags ?? [])
                let matches = needle.isEmpty || text.contains { $0.localizedCaseInsensitiveContains(needle) }
                return matches || !descendants.isEmpty ? LibraryNode(id: document.id, children: descendants) : nil
            }
        }
        return nodes(nil)
    }
    public static func incomingReferences(to id: UUID, in project: NovelProject) -> [WritingDocument] {
        project.documents.filter { $0.reference?.linkedIDs.contains(id) == true }
    }
    public static func availablePrerequisiteIDs(for eventID: UUID, in project: NovelProject) -> Set<UUID> {
        let events = project.documents.filter { $0.kind == .event }
        guard events.contains(where: { $0.id == eventID }) else { return [] }
        var following: [UUID: [UUID]] = [:]
        for event in events {
            for prerequisite in event.reference?.prerequisiteIDs ?? [] { following[prerequisite, default: []].append(event.id) }
        }
        var blocked = Set<UUID>(), pending = [eventID]
        while let id = pending.popLast() {
            if blocked.insert(id).inserted { pending.append(contentsOf: following[id] ?? []) }
        }
        return Set(events.map(\.id)).subtracting(blocked)
    }
}
