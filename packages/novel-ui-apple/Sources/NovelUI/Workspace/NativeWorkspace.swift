#if os(macOS)
import SwiftUI
import NovelDomain
import NovelWorkspace

public struct NativeWorkspace: View {
    @Binding private var project: NovelProject
    @StateObject private var session: WorkspaceSession
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearance") private var appearance = NovelAppearance.system.rawValue
    @State private var errorMessage: String?

    public init(project: Binding<NovelProject>) {
        _project = project; _session = StateObject(wrappedValue: WorkspaceSession(project: project.wrappedValue))
    }
    private var palette: NovelPalette { NovelPalette(colorScheme) }
    private var bindings: ProjectBindings { ProjectBindings(project: $project, reportError: { errorMessage = $0.localizedDescription }) }
    public var body: some View {
        NativeSplitNode(node: session.layout.root, project: $project, session: session, bindings: bindings, palette: palette)
            .frame(minWidth: 760, minHeight: 520).background(palette.paper).tint(palette.accent)
            .preferredColorScheme((NovelAppearance(rawValue: appearance) ?? .system).colorScheme)
            .toolbar { WorkspaceToolbar(session: session) }
            .focusedSceneValue(\.novelActions, NovelWorkspaceActions(newChapter: { add(.chapter) }, newNote: { add(.note) }, split: { session.split($0) }, canSplit: { session.canSplit($0) }, undoLayout: { session.undo() }, canUndoLayout: session.layout.canUndo, resetLayout: { session.reset() }))
            .alert("编辑失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("好") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
    }
    private func add(_ kind: WritingKind) { session.search = ""; session.open(bindings.add(kind), kind: kind) }
}
#endif
