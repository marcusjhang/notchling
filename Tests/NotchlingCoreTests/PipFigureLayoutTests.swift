import XCTest
@testable import NotchlingCore

final class PipFigureLayoutTests: XCTestCase {
    private let rect = Rect(x: 0, y: 0, width: 200, height: 200)
    private var layout: PipFigureLayout { PipFigureLayout(rect: rect) }

    // MARK: - Proportions

    func testHeadIsLargerThanBodyAtTheBabySchemaRatio() {
        let head = layout.head
        let body = layout.body

        XCTAssertGreaterThan(head.height, body.height, "the head must be the bigger half")
        XCTAssertEqual(head.height / body.height, 1.35, accuracy: 0.01)
        XCTAssertEqual(PipFigureLayout.headToBodyHeightRatio, 1.35, accuracy: 1e-9)
    }

    func testPartsStayInsideTheFigure() {
        let parts = [layout.head, layout.body, layout.belly, layout.tuft, layout.leftEar, layout.rightEar]
        for part in parts {
            XCTAssertGreaterThanOrEqual(part.minX, rect.minX - 1e-9)
            XCTAssertLessThanOrEqual(part.maxX, rect.maxX + 1e-9)
            XCTAssertGreaterThanOrEqual(part.minY, rect.minY - 1e-9)
            XCTAssertLessThanOrEqual(part.maxY, rect.maxY + 1e-9)
        }
    }

    // MARK: - Eyes

    func testEyesAreLargerThanBefore() {
        XCTAssertGreaterThan(layout.leftEye.width, 0.19 * rect.width)
        XCTAssertGreaterThan(layout.leftEye.height, 0.22 * rect.height)
        XCTAssertEqual(layout.leftEye.size, layout.rightEye.size)
    }

    func testEyesSitSlightlyBelowTheFaceMidline() {
        XCTAssertGreaterThan(layout.leftEye.midY, layout.head.midY)
        XCTAssertGreaterThan(layout.rightEye.midY, layout.head.midY)
        XCTAssertLessThan(layout.leftEye.midY - layout.head.midY, layout.head.height * 0.25)
    }

    func testEyesAreCloserTogetherThanBefore() {
        let separation = layout.rightEye.midX - layout.leftEye.midX
        XCTAssertGreaterThan(separation, 0)
        XCTAssertLessThan(separation, 0.24 * rect.width)
    }

    func testEyesAreCenteredOnTheHead() {
        let midpoint = (layout.leftEye.midX + layout.rightEye.midX) / 2
        XCTAssertEqual(midpoint, layout.head.midX, accuracy: 1e-9)
    }

    // MARK: - Catchlights

    func testEachEyeHasTwoCatchlightsOneBiggerThanTheOther() {
        let lights = layout.catchlights(in: layout.leftEye)
        XCTAssertGreaterThan(lights.big.width, lights.small.width * 1.5)
        XCTAssertGreaterThan(lights.big.height, lights.small.height * 1.5)
        for light in [lights.big, lights.small] {
            XCTAssertGreaterThanOrEqual(light.minX, layout.leftEye.minX - 1e-9)
            XCTAssertLessThanOrEqual(light.maxX, layout.leftEye.maxX + 1e-9)
            XCTAssertGreaterThanOrEqual(light.minY, layout.leftEye.minY - 1e-9)
            XCTAssertLessThanOrEqual(light.maxY, layout.leftEye.maxY + 1e-9)
        }
    }

    // MARK: - Face

    func testMouthSitsBelowBothEyes() {
        XCTAssertGreaterThan(layout.mouth.midY, layout.leftEye.midY)
        XCTAssertLessThan(layout.mouth.maxY, layout.head.maxY)
    }

    func testBlushCheeksSitBetweenEyesAndChin() {
        for blush in [layout.leftBlush, layout.rightBlush] {
            XCTAssertGreaterThan(blush.midY, layout.head.midY)
            XCTAssertLessThan(blush.maxY, layout.head.maxY)
        }
        XCTAssertGreaterThan(layout.leftBlush.maxX, layout.head.minX)
        XCTAssertLessThan(layout.rightBlush.minX, layout.head.maxX)
    }
}
