import SwiftUI
import AppKit
import NovelDomain
import NovelStorage
import NovelUI

struct ProjectCoverView: View {
    let project: NovelProject
    let repository: ManagedProjectRepository?
    let palette: NovelPalette
    @State private var image: NSImage?
    var body: some View {
        ZStack {
            palette.sidebar
            if let image { Image(nsImage: image).resizable().scaledToFill() }
            else { Image(systemName: "book.closed").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(palette.secondary) }
        }.aspectRatio(2 / 3, contentMode: .fit).clipped()
            .overlay(Rectangle().strokeBorder(palette.rule, lineWidth: 1))
            .accessibilityLabel(project.details.cover == nil ? "未设置封面" : "作品封面")
            .task(id: project.details.cover?.id) {
                image = nil
                guard let cover = project.details.cover, let repository else { return }
                do {
                    let url = try await repository.coverURL(cover, projectID: project.id)
                    let bytes = try await Task.detached { try CoverImages.thumbnail(at: url) }.value
                    if !Task.isCancelled { image = NSImage(data: bytes) }
                } catch { image = nil }
            }
    }
}
