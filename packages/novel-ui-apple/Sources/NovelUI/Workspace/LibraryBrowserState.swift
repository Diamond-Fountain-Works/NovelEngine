import Foundation
import NovelDomain

struct LibraryBrowserState: Codable, Equatable {
    var section: LibrarySection = .manuscript
    var manuscriptKind: WritingKind = .chapter
    var search = ""
    var kind: WritingKind { section == .manuscript ? manuscriptKind : section.kind }

    init(kind: WritingKind = .chapter) {
        if !kind.isReference { manuscriptKind = kind; return }
        section = LibrarySection.allCases.first { $0.kind == kind } ?? .manuscript
    }
    // Search phrases are ephemeral; only navigation preferences are saved locally.
    private enum CodingKeys: String, CodingKey { case section, manuscriptKind }
}
