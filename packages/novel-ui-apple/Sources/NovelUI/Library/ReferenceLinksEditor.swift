#if os(macOS)
import SwiftUI
import NovelDomain

struct ReferenceLinksEditor: View {
    let title: String
    let candidates: [WritingDocument]
    @Binding var selected: [UUID]
    var allowedIDs: Set<UUID>? = nil
    let open: (UUID) -> Void

    var body: some View {
        DisclosureGroup {
            if candidates.isEmpty { Text("暂无可关联文档").foregroundStyle(.secondary).font(.caption) }
            ForEach(candidates) { candidate in
                HStack {
                    Toggle(isOn: Binding(get: { selected.contains(candidate.id) }, set: { checked in
                        if checked { if !selected.contains(candidate.id) { selected.append(candidate.id) } }
                        else { selected.removeAll { $0 == candidate.id } }
                    })) {
                        Label(candidate.title.isEmpty ? "未命名" : candidate.title, systemImage: candidate.kind.symbol).lineLimit(1)
                    }.toggleStyle(.checkbox)
                        .disabled(!selected.contains(candidate.id) && allowedIDs?.contains(candidate.id) == false)
                        .help(allowedIDs?.contains(candidate.id) == false ? "会形成循环前置" : candidate.title)
                        .accessibilityIdentifier("reference.link.\(title).\(candidate.id.uuidString)")
                    if selected.contains(candidate.id) {
                        Button { open(candidate.id) } label: { Image(systemName: "arrow.up.right.square") }
                            .buttonStyle(.plain).help("打开\(candidate.title)").accessibilityLabel("打开\(candidate.title)")
                    }
                }.padding(.vertical, 3)
            }
        } label: { Text(title).font(.subheadline.weight(.medium)) }
    }
}
#endif
