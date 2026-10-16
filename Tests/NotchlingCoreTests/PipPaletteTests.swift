import XCTest
@testable import NotchlingCore

final class PipPaletteTests: XCTestCase {
    func testPaletteMatchesTheSpecExactly() {
        XCTAssertEqual(PipPalette.body.hex, "#F3EDE3")
        XCTAssertEqual(PipPalette.belly.hex, "#FFFBF3")
        XCTAssertEqual(PipPalette.blush.hex, "#F5B8AD")
        XCTAssertEqual(PipPalette.innerEar.hex, "#F2A9A0")
        XCTAssertEqual(PipPalette.ink.hex, "#2B2A28")
        XCTAssertEqual(PipPalette.nightcap.hex, "#8E9BB0")
        XCTAssertEqual(PipPalette.glow.hex, "#FFC76B")
    }
}
