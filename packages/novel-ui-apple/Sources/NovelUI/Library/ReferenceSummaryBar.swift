#if os(macOS)
import SwiftUI
import NovelDomain

struct ReferenceSummaryBar: View {
    let document: WritingDocument
    let project: NovelProject
    let bindings: ProjectBindings
    let palette: NovelPalette
    let prepareInput: () -> Void
    let open: (UUID) -> Void
    @State private var showsDetails = false

    var body: some View {
        HStack(spacing: 8) {
            Picker("状态", selection: bindings.reference(\.status, documentID: document.id)) {
                ForEach(CanonStatus.allCases, id: \.self) { Text($0.title).tag($0) }
            }.labelsHidden().pickerStyle(.menu).fixedSize().accessibilityIdentifier("reference.status")
            if let details = document.reference, document.kind == .event, !details.code.isEmpty {
                Text(details.code).font(.caption).monospaced().lineLimit(1)
            }
            Spacer(minLength: 2)
            Button { prepareInput(); showsDetails = true } label: { Label("属性与关联", systemImage: "slider.horizontal.3") }
                .accessibilityIdentifier("reference.details")
                .sheet(isPresented: $showsDetails) {
                    ReferenceDetailsEditor(document: document, project: project, bindings: bindings, palette: palette,
                        open: { id in showsDetails = false; open(id) }, done: { showsDetails = false })
                        .id(document.id)
                }
        }.controlSize(.small).foregroundStyle(palette.secondary)
    }
}
#endif
