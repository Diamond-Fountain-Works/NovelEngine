import Foundation

public enum ProjectValidationError: Error, Equatable {
    case emptyProject, duplicateID, invalidParent, parentCycle, invalidReference, invalidEventDependency, eventCycle, invalidDetails
}

public extension NovelProject {
    /// Shared by editing and storage, so invalid relationships cannot enter a saved package.
    func validate() throws {
        guard Set(details.contributors.map(\.id)).count == details.contributors.count,
              details.cover?.isValid != false else { throw ProjectValidationError.invalidDetails }
        guard !documents.isEmpty else { throw ProjectValidationError.emptyProject }
        guard Set(documents.map(\.id)).count == documents.count else { throw ProjectValidationError.duplicateID }
        let lookup = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0) })
        for document in documents {
            if let parentID = document.parentID {
                guard document.kind.isReference, let parent = lookup[parentID], parent.kind == document.kind, parent.id != document.id else {
                    throw ProjectValidationError.invalidParent
                }
            }
            guard document.kind.isReference == (document.reference != nil) else { throw ProjectValidationError.invalidReference }
            guard let details = document.reference else { continue }
            for ids in [details.relatedIDs, details.participantIDs, details.prerequisiteIDs] {
                guard Set(ids).count == ids.count, ids.allSatisfy({ $0 != document.id && lookup[$0] != nil }) else {
                    throw ProjectValidationError.invalidReference
                }
            }
            if document.kind != .event {
                guard details.timeAnchor.isEmpty, details.participantIDs.isEmpty, details.prerequisiteIDs.isEmpty else {
                    throw ProjectValidationError.invalidEventDependency
                }
            }
            guard details.participantIDs.allSatisfy({ lookup[$0]?.kind == .character && lookup[$0]?.parentID == nil }),
                  details.prerequisiteIDs.allSatisfy({ lookup[$0]?.kind == .event }) else {
                throw ProjectValidationError.invalidEventDependency
            }
        }
        try Self.validateAcyclic(documents.map(\.id), edges: { lookup[$0]?.parentID.map { [$0] } ?? [] }, error: .parentCycle)
        try Self.validateAcyclic(documents.filter { $0.kind == .event }.map(\.id),
                                 edges: { lookup[$0]?.reference?.prerequisiteIDs ?? [] }, error: .eventCycle)
    }

    private static func validateAcyclic(_ ids: [UUID], edges: (UUID) -> [UUID], error: ProjectValidationError) throws {
        var visited = Set<UUID>(), visiting = Set<UUID>()
        func visit(_ id: UUID) throws {
            if visited.contains(id) { return }
            guard visiting.insert(id).inserted else { throw error }
            for next in edges(id) { try visit(next) }
            visiting.remove(id); visited.insert(id)
        }
        for id in ids { try visit(id) }
    }
}
