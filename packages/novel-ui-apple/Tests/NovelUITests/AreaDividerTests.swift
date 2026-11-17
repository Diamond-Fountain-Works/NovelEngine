#if os(macOS)
import XCTest
import AppKit
@testable import NovelUI

final class AreaDividerTests: XCTestCase {
    @MainActor func testNativeMenuUsesPointerFractionAndDispatchesSelectedAction() throws {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 600), styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let divider = AreaDividerView(frame: NSRect(x: 0, y: 0, width: 6, height: 600))
        window.contentView?.addSubview(divider)
        var fractions: [Double] = [], invoked: [Int] = []
        divider.actions = { fraction in
            fractions.append(fraction)
            let row = fraction < 0.5 ? 0 : 1
            return [AreaDividerAction(title: "Join Right", enabled: true, perform: { invoked.append(row) })]
        }
        for (index, y) in [150.0, 450.0].enumerated() {
            let point = divider.convert(NSPoint(x: 3, y: y), to: nil)
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: .rightMouseDown, location: point, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: index, clickCount: 1, pressure: 1))
            let menu = try XCTUnwrap(divider.menu(for: event))
            let item = try XCTUnwrap(menu.items.first)
            XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(item.action), to: item.target, from: item))
        }
        XCTAssertEqual(fractions, [0.25, 0.75])
        XCTAssertEqual(invoked, [0, 1])
    }

    @MainActor func testArrowKeysResizeAlongTheDividerAxis() throws {
        var resized: [Double] = []
        let divider = AreaDividerView()
        divider.ratio = 0.5; divider.resize = { resized.append($0) }
        func key(_ code: UInt16) throws -> NSEvent {
            try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: code))
        }
        divider.keyDown(with: try key(123))
        divider.keyDown(with: try key(124))
        divider.axis = .vertical
        divider.keyDown(with: try key(126))
        divider.keyDown(with: try key(125))
        XCTAssertEqual(resized, [0.45, 0.55, 0.45, 0.55])
    }
}
#endif
