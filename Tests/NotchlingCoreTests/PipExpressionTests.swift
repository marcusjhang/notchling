import XCTest
@testable import NotchlingCore

final class PipExpressionTests: XCTestCase {
    private let figure = Rect(x: 700, y: 900, width: 56, height: 56)

    func testTapMovesPipIntoTheHappyExpression() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 1, personality: .companion, figure: figure, clock: clock)

        let resting = engine.step(input: .idle)
        XCTAssertEqual(resting.expression, .neutral)

        clock.advance(by: 1)
        let tapped = engine.step(input: PipInput(cursor: figure.center, click: figure.center))
        XCTAssertEqual(tapped.reaction, .click)
        XCTAssertEqual(tapped.expression, .happy)
    }

    func testHappyExpressionResolvesBackToNeutral() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 2, personality: .companion, figure: figure, clock: clock)

        clock.advance(by: 1)
        XCTAssertEqual(engine.step(input: PipInput(click: figure.center)).expression, .happy)

        clock.advance(by: ReactionTuning.bounceDuration + 0.05)
        XCTAssertEqual(engine.step(input: .idle).expression, .neutral)
    }
}
