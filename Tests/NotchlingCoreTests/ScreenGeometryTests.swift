import XCTest
@testable import NotchlingCore

final class ScreenGeometryTests: XCTestCase {
    private func notchedScreen() -> ScreenGeometry {
        ScreenGeometry(
            displayID: 1,
            frame: Rect(x: 0, y: 0, width: 1512, height: 982),
            visibleFrame: Rect(x: 0, y: 0, width: 1512, height: 950),
            safeAreaTop: 32,
            auxiliaryTopLeftArea: Rect(x: 0, y: 950, width: 663.5, height: 32),
            auxiliaryTopRightArea: Rect(x: 848.5, y: 950, width: 663.5, height: 32)
        )
    }

    private func plainScreen() -> ScreenGeometry {
        ScreenGeometry(
            displayID: 2,
            frame: Rect(x: 0, y: 0, width: 3440, height: 1440),
            visibleFrame: Rect(x: 0, y: 0, width: 3440, height: 1415),
            safeAreaTop: 0
        )
    }

    func testNotchedScreenHasNotch() {
        XCTAssertTrue(notchedScreen().hasNotch)
    }

    func testNotchRectMatchesMeasuredGeometry() {
        let rect = notchedScreen().notchRect
        XCTAssertEqual(rect, Rect(x: 663.5, y: 950, width: 185, height: 32))
    }

    func testNotchedPresentationIsNotch() {
        let geometry = notchedScreen()
        guard case .notch(let rect) = geometry.presentation else {
            return XCTFail("expected notch presentation")
        }
        XCTAssertEqual(rect, Rect(x: 663.5, y: 950, width: 185, height: 32))
    }

    func testPlainScreenHasNoNotch() {
        XCTAssertFalse(plainScreen().hasNotch)
        XCTAssertNil(plainScreen().notchRect)
    }

    func testFloatingPillSitsBelowMenuBar() {
        let geometry = plainScreen()
        XCTAssertEqual(geometry.menuBarHeight, 25, accuracy: 0.0001)
        guard case .floatingPill(let rect) = geometry.presentation else {
            return XCTFail("expected floating pill presentation")
        }
        XCTAssertLessThan(rect.maxY, geometry.frame.maxY - geometry.menuBarHeight)
    }

    func testFloatingPillIsHorizontallyCentered() {
        let geometry = plainScreen()
        guard case .floatingPill(let rect) = geometry.presentation else {
            return XCTFail("expected floating pill presentation")
        }
        XCTAssertEqual(rect.midX, geometry.frame.midX, accuracy: 0.0001)
        XCTAssertEqual(rect.width, ScreenGeometry.floatingPillSize.width, accuracy: 0.0001)
        XCTAssertEqual(rect.height, ScreenGeometry.floatingPillSize.height, accuracy: 0.0001)
    }

    func testFloatingPillWidthClampsToNarrowScreen() {
        let geometry = ScreenGeometry(
            displayID: 3,
            frame: Rect(x: 0, y: 0, width: 160, height: 600),
            visibleFrame: Rect(x: 0, y: 0, width: 160, height: 575),
            safeAreaTop: 0
        )
        XCTAssertEqual(geometry.floatingPillRect.width, 160, accuracy: 0.0001)
    }

    func testDisplaySelectionPrefersNotchedDisplay() {
        let displays = [plainScreen(), notchedScreen()]
        XCTAssertEqual(DisplaySelection.preferred(from: displays)?.displayID, 1)
    }

    func testDisplaySelectionFallsBackToFirstDisplay() {
        let displays = [plainScreen()]
        XCTAssertEqual(DisplaySelection.preferred(from: displays)?.displayID, 2)
        XCTAssertNil(DisplaySelection.preferred(from: []))
    }
}
