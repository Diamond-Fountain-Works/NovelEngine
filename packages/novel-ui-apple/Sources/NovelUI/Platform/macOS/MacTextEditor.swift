#if os(macOS)
import AppKit
import SwiftUI

/// The AppKit boundary owns input composition, selection and native text undo only.
@MainActor struct MacTextEditor: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let serif: Bool
    let palette: NovelPalette
    var focusToken: UUID? = nil
    let onFocus: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = ManuscriptScrollView()
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true; scroll.borderType = .noBorder
        let view = ManuscriptTextView(frame: CGRect(x: 0, y: 0, width: 700, height: 400))
        view.isRichText = false; view.importsGraphics = false; view.allowsUndo = true
        view.isAutomaticQuoteSubstitutionEnabled = false; view.isAutomaticDashSubstitutionEnabled = false
        view.isAutomaticTextReplacementEnabled = false; view.isAutomaticSpellingCorrectionEnabled = false
        view.isVerticallyResizable = true; view.isHorizontallyResizable = false
        view.minSize = .zero; view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.autoresizingMask = [.width]; view.textContainer?.widthTracksTextView = true
        view.textContainer?.containerSize = NSSize(width: 700, height: CGFloat.greatestFiniteMagnitude)
        view.delegate = context.coordinator; view.string = text
        view.onFocus = onFocus
        view.focusRequest = focusToken
        context.coordinator.observeUndo(in: view)
        view.setAccessibilityIdentifier("editor.body"); view.setAccessibilityLabel("正文")
        scroll.documentView = view
        style(view, scroll: scroll)
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let view = scroll.documentView as? ManuscriptTextView else { return }
        view.onFocus = onFocus
        view.focusRequest = focusToken
        if !view.string.utf8.elementsEqual(text.utf8), !view.hasMarkedText() {
            let selection = view.selectedRange()
            view.undoManager?.removeAllActions()
            view.string = text
            let count = (text as NSString).length
            view.setSelectedRange(NSRange(location: min(selection.location, count), length: 0))
        }
        if !view.hasMarkedText() { style(view, scroll: scroll) }
    }
    private func style(_ view: NSTextView, scroll: NSScrollView) {
        let font = serif ? NSFont(name: "Songti SC", size: fontSize) ?? .systemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)
        if view.font != font { view.font = font }
        view.textColor = NSColor(palette.text); view.insertionPointColor = NSColor(palette.accent)
        view.backgroundColor = NSColor(palette.paper); scroll.backgroundColor = NSColor(palette.paper)
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = fontSize * 0.65
        view.defaultParagraphStyle = paragraph
        view.typingAttributes = [.font: font, .foregroundColor: NSColor(palette.text), .paragraphStyle: paragraph]
    }
    @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacTextEditor
        private weak var editor: NSTextView?
        init(_ parent: MacTextEditor) { self.parent = parent }
        deinit { NotificationCenter.default.removeObserver(self) }
        func observeUndo(in view: NSTextView) {
            editor = view
            for name in [Notification.Name.NSUndoManagerDidUndoChange, Notification.Name.NSUndoManagerDidRedoChange] {
                NotificationCenter.default.addObserver(self, selector: #selector(undoStateChanged), name: name, object: view.undoManager)
            }
        }
        @objc private func undoStateChanged(_ notification: Notification) {
            // Text undo may finish without a delegate textDidChange callback.
            if let editor { commit(editor) }
        }
        func textDidBeginEditing(_ notification: Notification) { parent.onFocus() }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            commit(view)
        }
        private func commit(_ view: NSTextView) {
            // Commit only completed input; marked text remains owned by the input method.
            if !view.hasMarkedText(), !parent.text.utf8.elementsEqual(view.string.utf8) { parent.text = view.string }
        }
    }
}

@MainActor final class ManuscriptTextView: NSTextView {
    var onFocus: () -> Void = {}
    var focusRequest: UUID? {
        didSet { if focusRequest != oldValue { applyRequestedFocus() } }
    }
    private let textUndoManager = UndoManager()
    override var undoManager: UndoManager? { textUndoManager }
    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { onFocus() }
        return accepted
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow(); applyRequestedFocus()
    }
    private func applyRequestedFocus() {
        guard let token = focusRequest, window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.focusRequest == token, !self.isHiddenOrHasHiddenAncestor else { return }
            self.window?.makeFirstResponder(self)
        }
    }
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        let inset = max(24, (newSize.width - 680) / 2)
        if textContainerInset.width != inset { textContainerInset = NSSize(width: inset, height: 18) }
    }
}

@MainActor final class ManuscriptScrollView: NSScrollView {
    override func tile() {
        super.tile()
        guard let editor = documentView as? ManuscriptTextView, contentSize.width > 0 else { return }
        let width = contentSize.width
        editor.minSize = NSSize(width: 0, height: contentSize.height)
        editor.maxSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        if abs(editor.frame.width - width) > 0.5 {
            editor.setFrameSize(NSSize(width: width, height: max(editor.frame.height, contentSize.height)))
        }
    }
}
#endif
