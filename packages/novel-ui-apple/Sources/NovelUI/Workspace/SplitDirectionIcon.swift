import SwiftUI
import NovelWorkspace

struct SplitDirectionIcon: View {
    let direction: SplitDirection
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(x: 1, y: 2, width: size.width - 2, height: size.height - 4)
            context.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .foreground, lineWidth: 1)
            let inset = rect.insetBy(dx: 3, dy: 3)
            var selected = inset
            if direction.axis == .horizontal {
                selected.size.width = max(1, (inset.width - 2) / 2)
                if direction == .right { selected.origin.x = inset.maxX - selected.width }
            } else {
                selected.size.height = max(1, (inset.height - 2) / 2)
                if direction == .down { selected.origin.y = inset.maxY - selected.height }
            }
            context.fill(Path(selected), with: .foreground)
        }.frame(width: 19, height: 20).accessibilityHidden(true)
    }
}
