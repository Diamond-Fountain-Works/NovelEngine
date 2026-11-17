#if os(macOS)
import XCTest
import AppKit
import SwiftUI
@testable import NovelUI

final class TextEditorTests: XCTestCase {
    @MainActor func testCanonicallyEquivalentUnicodeEditAndUndoPreserveActualInputBytes() throws {
        let original = "e\u{301}"
        let box = TextBox(original)
        let (host, editor) = try editor(box)
        withExtendedLifetime(host) {
            editor.setSelectedRange(NSRange(location: 0, length: (editor.string as NSString).length))
            editor.insertText("é", replacementRange: editor.selectedRange())
            XCTAssertEqual(Array(box.text.utf8), Array("é".utf8))
            editor.breakUndoCoalescing(); editor.undoManager?.undo()
            XCTAssertEqual(Array(box.text.utf8), Array(original.utf8))
            editor.undoManager?.redo()
            XCTAssertEqual(Array(box.text.utf8), Array("é".utf8))
        }
    }
    @MainActor func testProgrammaticFocusRequestAndCancellation() async throws {
        let leftText = TextBox("左侧"), rightText = TextBox("右侧")
        let (leftHost, left) = try editor(leftText)
        let (rightHost, right) = try editor(rightText)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 500), styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let content = try XCTUnwrap(window.contentView)
        content.addSubview(leftHost); content.addSubview(rightHost)
        XCTAssertTrue(window.makeFirstResponder(left))
        let token = UUID()
        rightHost.rootView = MacTextEditor(text: Binding(get: { rightText.text }, set: { rightText.text = $0 }), fontSize: 18, serif: true, palette: NovelPalette(.light), focusToken: token, onFocus: {})
        rightHost.layoutSubtreeIfNeeded()
        XCTAssertEqual((right as? ManuscriptTextView)?.focusRequest, token)
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        XCTAssertTrue(window.firstResponder === right)
        leftHost.rootView = MacTextEditor(text: Binding(get: { leftText.text }, set: { leftText.text = $0 }), fontSize: 18, serif: true, palette: NovelPalette(.light), focusToken: UUID(), onFocus: {})
        leftHost.layoutSubtreeIfNeeded()
        leftHost.rootView = MacTextEditor(text: Binding(get: { leftText.text }, set: { leftText.text = $0 }), fontSize: 18, serif: true, palette: NovelPalette(.light), onFocus: {})
        leftHost.layoutSubtreeIfNeeded()
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        XCTAssertTrue(window.firstResponder === right)
        XCTAssertEqual(left.string, "左侧"); XCTAssertEqual(right.string, "右侧")
    }
    @MainActor func testDFWFontIsRegistered() {
        NovelBrandFonts.register()
        XCTAssertNotNil(NSFont(name: "DFWAfterglowSolid-BoldItalic", size: 12))
    }
    @MainActor func testNativeTypingReachesBindingAndUndoReturnsOriginal() throws {
        let box = TextBox("原文\n")
        let (host, editor) = try editor(box)
        withExtendedLifetime(host) {
            editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
            editor.insertText("中文🙂", replacementRange: editor.selectedRange())
            XCTAssertEqual(box.text, "原文\n中文🙂")
            XCTAssertTrue(editor.undoManager?.canUndo == true)
            editor.breakUndoCoalescing()
            editor.undoManager?.undo()
            XCTAssertEqual(editor.string, "原文\n")
            XCTAssertEqual(box.text, "原文\n")
            editor.undoManager?.redo()
            XCTAssertEqual(editor.string, "原文\n中文🙂")
            XCTAssertEqual(box.text, "原文\n中文🙂")
        }
    }
    @MainActor func testChineseMarkedTextIsNotSavedBeforeCommit() throws {
        let box = TextBox("")
        let (host, editor) = try editor(box)
        withExtendedLifetime(host) {
            editor.setMarkedText("pin", selectedRange: NSRange(location: 3, length: 0), replacementRange: NSRange(location: 0, length: 0))
            XCTAssertTrue(editor.hasMarkedText())
            XCTAssertEqual(box.text, "")
            editor.insertText("拼", replacementRange: editor.markedRange())
            XCTAssertEqual(box.text, "拼")
        }
    }
    @MainActor func testPlainEditorDoesNotEnableTextRewriting() throws {
        let (host, editor) = try editor(TextBox(""))
        withExtendedLifetime(host) {
            XCTAssertFalse(editor.isRichText)
            XCTAssertFalse(editor.isAutomaticQuoteSubstitutionEnabled)
            XCTAssertFalse(editor.isAutomaticTextReplacementEnabled)
            XCTAssertFalse(editor.isAutomaticSpellingCorrectionEnabled)
        }
    }
    @MainActor func testTextContainerTracksNarrowSplitWidth() throws {
        let (host, editor) = try editor(TextBox("原文"))
        host.frame.size.width = 420
        host.layoutSubtreeIfNeeded()
        let scroll = try XCTUnwrap(editor.enclosingScrollView)
        scroll.tile()
        XCTAssertEqual(editor.frame.width, scroll.contentSize.width, accuracy: 1)
        XCTAssertEqual(editor.textContainerInset.width, 24, accuracy: 1)
    }
    @MainActor func testSwitchingFirstResponderActivatesEditorWithoutTyping() throws {
        let first = TextBox("第一栏原文"), second = TextBox("第二栏原文")
        var focused: [Int] = []
        let (leftHost, left) = try editor(first, onFocus: { focused.append(1) })
        let (rightHost, right) = try editor(second, onFocus: { focused.append(2) })
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 500), styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let content = try XCTUnwrap(window.contentView)
        leftHost.frame = NSRect(x: 0, y: 0, width: 500, height: 500)
        rightHost.frame = NSRect(x: 500, y: 0, width: 500, height: 500)
        content.addSubview(leftHost); content.addSubview(rightHost)
        focused.removeAll()
        XCTAssertTrue(window.makeFirstResponder(left))
        XCTAssertEqual(focused.last, 1)
        XCTAssertTrue(window.makeFirstResponder(right))
        XCTAssertEqual(focused.last, 2)
        XCTAssertTrue(window.makeFirstResponder(left))
        XCTAssertEqual(focused.last, 1)
        XCTAssertEqual(first.text, "第一栏原文")
        XCTAssertEqual(second.text, "第二栏原文")
        XCTAssertFalse(left.undoManager?.canUndo == true)
        XCTAssertFalse(right.undoManager?.canUndo == true)
    }
    @MainActor private func editor(_ box: TextBox, onFocus: @escaping () -> Void = {}) throws -> (NSHostingView<MacTextEditor>, NSTextView) {
        _ = NSApplication.shared
        let root = MacTextEditor(text: Binding(get: { box.text }, set: { box.text = $0 }), fontSize: 18, serif: true, palette: NovelPalette(.light), onFocus: onFocus)
        let host = NSHostingView(rootView: root)
        host.frame = CGRect(x: 0, y: 0, width: 800, height: 500)
        host.layoutSubtreeIfNeeded()
        func find(_ view: NSView) -> NSTextView? {
            if let text = view as? NSTextView { return text }
            return view.subviews.lazy.compactMap(find).first
        }
        return (host, try XCTUnwrap(find(host)))
    }
}
@MainActor private final class TextBox { var text: String; init(_ text: String) { self.text = text } }
#endif
