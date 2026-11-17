#if os(macOS)
import SwiftUI
import NovelDomain

struct LibraryModuleRail: View {
    let selection: LibrarySection
    let palette: NovelPalette
    let paneID: UUID
    let select: (LibrarySection) -> Void

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 4) {
                ForEach(LibrarySection.allCases, id: \.self) { section in
                    Button { select(section) } label: {
                        VStack(spacing: 4) {
                            Image(systemName: section.symbol).font(.system(size: 16))
                            Text(section.title).font(.system(size: 9, weight: .medium)).lineLimit(1)
                        }.frame(width: 42, height: 44)
                            .foregroundStyle(selection == section ? palette.accent : palette.secondary)
                            .background(selection == section ? palette.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 6))
                    }.buttonStyle(.plain).help(section.title).accessibilityLabel(section.title)
                        .accessibilityValue(selection == section ? "已选择" : "")
                        .accessibilityIdentifier("library.section.\(section.rawValue).\(paneID.uuidString)")
                }
            }.padding(.vertical, 9).padding(.horizontal, 3)
        }.scrollIndicators(.hidden).frame(width: 48).background(palette.chrome)
    }
}
#endif
