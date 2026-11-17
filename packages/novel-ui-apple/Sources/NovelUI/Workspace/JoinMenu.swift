import SwiftUI
import NovelWorkspace

struct JoinMenu: View {
    @ObservedObject var session: WorkspaceSession
    let paneID: UUID
    var body: some View {
        ForEach(session.layout.joinOptions(from: paneID), id: \.direction) { option in
            Button(option.title) { session.join(from: paneID, toward: option.direction) }
        }
    }
}

struct SplitMenu: View {
    @ObservedObject var session: WorkspaceSession
    var paneID: UUID?
    var body: some View {
        ForEach(SplitDirection.allCases, id: \.self) { direction in
            Button { session.split(direction, in: paneID) } label: {
                Label { Text(direction.title) } icon: { SplitDirectionIcon(direction: direction) }
            }.disabled(!session.canSplit(direction, in: paneID))
        }
    }
}
