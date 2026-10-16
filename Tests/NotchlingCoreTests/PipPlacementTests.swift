import XCTest
@testable import NotchlingCore

final class PipPlacementTests: XCTestCase {
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

    func testNotchedFigureIsCenteredOnNotchAndHangsBelowItsLip() {
        let geometry = notchedScreen()
        let notch = geometry.notchRect!
        let figure = PipPlacement.figureRect(for: geometry)

        XCTAssertGreaterThanOrEqual(figure.height, 18)
        XCTAssertLessThanOrEqual(figure.height, 28)
        XCTAssertEqual(figure.midX, notch.midX, accuracy: 0.0001)
        XCTAssertEqual(figure.maxY, notch.minY, accuracy: 0.0001)
        XCTAssertLessThan(figure.minY, notch.minY)
    }

    func testNonNotchedFigureIsCenteredOnPillAndHangsBelowIt() {
        let geometry = plainScreen()
        let pill = geometry.floatingPillRect
        let figure = PipPlacement.figureRect(for: geometry)

        XCTAssertGreaterThanOrEqual(figure.height, 18)
        XCTAssertLessThanOrEqual(figure.height, 28)
        XCTAssertEqual(figure.midX, pill.midX, accuracy: 0.0001)
        XCTAssertEqual(figure.maxY, pill.minY, accuracy: 0.0001)
        XCTAssertLessThan(figure.minY, pill.minY)
    }

    func testOneRoutineServesBothPresentations() {
        let notch = Rect(x: 663.5, y: 950, width: 185, height: 32)
        let pill = Rect(x: 100, y: 1390, width: 220, height: 30)

        let fromNotch = PipPlacement.figureRect(for: .notch(notch))
        let fromPill = PipPlacement.figureRect(for: .floatingPill(pill))

        XCTAssertEqual(fromNotch.midX, notch.midX, accuracy: 0.0001)
        XCTAssertEqual(fromNotch.maxY, notch.minY, accuracy: 0.0001)
        XCTAssertEqual(fromPill.midX, pill.midX, accuracy: 0.0001)
        XCTAssertEqual(fromPill.maxY, pill.minY, accuracy: 0.0001)
        XCTAssertEqual(fromNotch.size, fromPill.size)
    }

    func testFigureSizeIsWithinReadableRange() {
        XCTAssertGreaterThanOrEqual(PipPlacement.figureHeight, 18)
        XCTAssertLessThanOrEqual(PipPlacement.figureHeight, 28)
        XCTAssertGreaterThan(PipPlacement.figureWidth, 0)
    }

    func testFigureWidthIsDerivedFromHeightByAspectRatio() {
        XCTAssertEqual(
            PipPlacement.figureWidth,
            PipPlacement.figureHeight * PipPlacement.figureAspectRatio,
            accuracy: 1e-9
        )
        let figure = PipPlacement.figureRect(for: .notch(Rect(x: 0, y: 0, width: 10, height: 10)))
        XCTAssertEqual(figure.width, PipPlacement.figureHeight * PipPlacement.figureAspectRatio, accuracy: 1e-9)
    }

    func testEnvelopeHoldsTheFigureFlushWithTheLipForBothPresentations() {
        for geometry in [notchedScreen(), plainScreen()] {
            let lip = geometry.presentation.rect
            let figure = PipPlacement.figureRect(for: geometry)
            let envelope = PipPlacement.panelEnvelope(for: geometry)

            XCTAssertEqual(figure.midX, lip.midX, accuracy: 0.0001)
            XCTAssertEqual(figure.maxY, lip.minY, accuracy: 0.0001)
            XCTAssertGreaterThanOrEqual(figure.minX, envelope.minX)
            XCTAssertLessThanOrEqual(figure.maxX, envelope.maxX)
            XCTAssertGreaterThanOrEqual(figure.minY, envelope.minY)
            XCTAssertLessThanOrEqual(figure.maxY, envelope.maxY)
        }
    }

    func testPanelEnvelopeIsFixedAndWithinBounds() {
        XCTAssertLessThanOrEqual(PipPlacement.panelSize.width, 160)
        XCTAssertLessThanOrEqual(PipPlacement.panelSize.height, 140)
        XCTAssertLessThanOrEqual(PipPlacement.panelSize.width, 200)
        XCTAssertLessThanOrEqual(PipPlacement.panelSize.height, 180)

        let notch = Rect(x: 0, y: 100, width: 200, height: 32)
        let pill = Rect(x: 0, y: 500, width: 220, height: 30)
        XCTAssertEqual(
            PipPlacement.panelEnvelope(for: .notch(notch)).size,
            PipPlacement.panelEnvelope(for: .floatingPill(pill)).size
        )
    }
}
