#if os(macOS)
import AppKit
import SwiftUI
import NovelWorkspace

@MainActor struct AreaDividerAction {
    let title: String
    let enabled: Bool
    let perform: () -> Void
}

/// AppKit supplies the exact right-click position, native menu dispatch and tracking.
/// Geometry and the join decision remain in the platform-neutral layout model.
@MainActor struct AreaDivider: NSViewRepresentable {
    let axis: SplitAxis
    let ratio: Double
    let extent: CGFloat
    let identifier: String
    let palette: NovelPalette
    let resize: (Double) -> Void
    let actions: (Double) -> [AreaDividerAction]
    func makeNSView(context: Context) -> AreaDividerView { let view = AreaDividerView(); configure(view); return view }
    func updateNSView(_ view: AreaDividerView, context: Context) { configure(view) }
    private func configure(_ view: AreaDividerView) {
        view.axis = axis; view.ratio = ratio; view.extent = extent
        view.fill = NSColor(palette.rule); view.focus = NSColor(palette.accent)
        view.resize = resize; view.actions = actions
        view.setAccessibilityElement(true); view.setAccessibilityRole(.splitter)
        view.setAccessibilityLabel(axis == .horizontal ? "调整左右分栏" : "调整上下分栏")
        view.setAccessibilityIdentifier(identifier); view.setAccessibilityValue(NSNumber(value: ratio * 100))
        view.needsDisplay = true
    }
}

@MainActor final class AreaDividerView: NSView {
    var axis = SplitAxis.horizontal
    var ratio = 0.5
    var extent: CGFloat = 1
    var fill = NSColor.separatorColor
    var focus = NSColor.controlAccentColor
    var resize: (Double) -> Void = { _ in }
    var actions: (Double) -> [AreaDividerAction] = { _ in [] }
    private var dragStart: NSPoint?
    private var startRatio = 0.5
    private var menuHandlers: [() -> Void] = []
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: axis == .horizontal ? .resizeLeftRight : .resizeUpDown) }
    override func draw(_ dirtyRect: NSRect) {
        fill.setFill(); bounds.fill()
        if window?.firstResponder === self { focus.setStroke(); NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke() }
    }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self); needsDisplay = true
        if event.clickCount == 2 { resize(0.5); return }
        dragStart = event.locationInWindow; startRatio = ratio
    }
    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, extent > 0 else { return }
        let delta = axis == .horizontal ? event.locationInWindow.x - start.x : start.y - event.locationInWindow.y
        resize(startRatio + delta / extent)
    }
    override func mouseUp(with event: NSEvent) { dragStart = nil }
    override func keyDown(with event: NSEvent) {
        switch (axis, event.keyCode) {
        case (.horizontal, 123), (.vertical, 126): resize(ratio - 0.05)
        case (.horizontal, 124), (.vertical, 125): resize(ratio + 0.05)
        default: super.keyDown(with: event)
        }
    }
    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let fraction = axis == .horizontal ? point.y / max(1, bounds.height) : point.x / max(1, bounds.width)
        let entries = actions(fraction)
        guard !entries.isEmpty else { return nil }
        let menu = NSMenu()
        menu.autoenablesItems = false; menuHandlers = []
        for entry in entries {
            if entry.title.isEmpty { menu.addItem(.separator()); continue }
            let item = NSMenuItem(title: entry.title, action: #selector(performMenuAction(_:)), keyEquivalent: "")
            item.target = self; item.isEnabled = entry.enabled; item.tag = menuHandlers.count
            menuHandlers.append(entry.perform); menu.addItem(item)
        }
        return menu
    }
    @objc private func performMenuAction(_ item: NSMenuItem) {
        guard menuHandlers.indices.contains(item.tag) else { return }
        let action = menuHandlers[item.tag]; action()
    }
}
#endif
