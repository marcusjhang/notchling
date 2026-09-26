import XCTest
@testable import NotchlingCore

/// A deterministic input script. Implements the same protocol the app's global
/// monitor uses, so tests exercise the exact production path with no AppKit.
final class ScriptedInputSource: PipInputSource {
    private let script: [PipInput]
    private var index = 0

    init(_ script: [PipInput]) {
        self.script = script
    }

    func readInput() -> PipInput {
        defer { index += 1 }
        return script[min(index, script.count - 1)]
    }
}

final class ReactionTests: XCTestCase {
    private let figure = Rect(x: 700, y: 900, width: 56, height: 56)

    private func point(_ dx: Double, _ dy: Double) -> Point {
        Point(x: figure.center.x + dx, y: figure.center.y + dy)
    }

    /// Near but outside the tighter hover region.
    private var nearButNotHovering: Point { point(45, 0) }
    private var farAway: Point { point(0, -400) }

    /// Just past the boundary of the hover region that bounds the click target.
    private var justOutsideHover: Point {
        point(figure.width / 2 + ReactionTuning.hoverPadding + 0.5, 0)
    }

    // MARK: - Gaze

    func testGazePointsTowardCursorWithBoundedMagnitude() {
        for distance in [10.0, 50.0, 200.0, 1000.0] {
            let gaze = Gaze.toward(center: figure.center, target: point(distance, 0))
            XCTAssertGreaterThan(gaze.x, 0)
            XCTAssertEqual(gaze.y, 0, accuracy: 1e-9)
            XCTAssertLessThanOrEqual(gaze.magnitude, ReactionTuning.maxTurn + 1e-9)
        }

        let diagonal = Gaze.toward(center: figure.center, target: point(120, 120))
        XCTAssertGreaterThan(diagonal.x, 0)
        XCTAssertGreaterThan(diagonal.y, 0)
        XCTAssertEqual(diagonal.x, diagonal.y, accuracy: 1e-9)
    }

    func testTurnClampsAtTheLimitAsDistanceGrows() {
        let near = Gaze.toward(center: figure.center, target: point(20, 0))
        let mid = Gaze.toward(center: figure.center, target: point(90, 0))
        let far = Gaze.toward(center: figure.center, target: point(100_000, 0))

        XCTAssertGreaterThan(mid.magnitude, near.magnitude)
        XCTAssertLessThanOrEqual(mid.magnitude, ReactionTuning.maxTurn + 1e-9)
        XCTAssertEqual(far.magnitude, ReactionTuning.maxTurn, accuracy: 1e-6)
    }

    // MARK: - Proximity / perk

    func testNearReactionTriggersOnEnterAndRetriggersAfterLeaving() {
        var state = ReactionState()

        var frame = state.update(cursor: farAway, click: nil, figure: figure, at: 0)
        XCTAssertFalse(frame.isNear)
        XCTAssertNil(frame.active)

        frame = state.update(cursor: nearButNotHovering, click: nil, figure: figure, at: 1)
        XCTAssertTrue(frame.isNear)
        XCTAssertEqual(frame.active, .cursorNear)
        XCTAssertEqual(frame.nearTriggerCount, 1)

        frame = state.update(cursor: farAway, click: nil, figure: figure, at: 2)
        XCTAssertFalse(frame.isNear)
        XCTAssertNil(frame.active)

        frame = state.update(cursor: nearButNotHovering, click: nil, figure: figure, at: 3)
        XCTAssertTrue(frame.isNear)
        XCTAssertEqual(frame.active, .cursorNear)
        XCTAssertEqual(frame.nearTriggerCount, 2)
    }

    // MARK: - Hover emerge

    func testHoverEmergeExceedsRestAndReturnsWithinBoundedTime() {
        var state = ReactionState()

        var frame = state.update(cursor: farAway, click: nil, figure: figure, at: 0)
        let rest = frame.emerge

        frame = state.update(cursor: figure.center, click: nil, figure: figure, at: 0.1)
        XCTAssertGreaterThan(frame.emerge, rest)
        XCTAssertEqual(frame.active, .hover)

        frame = state.update(cursor: farAway, click: nil, figure: figure, at: 0.2)
        XCTAssertGreaterThan(frame.emerge, rest)

        frame = state.update(
            cursor: farAway, click: nil, figure: figure,
            at: 0.2 + ReactionTuning.emergeReleaseDuration + 0.01
        )
        XCTAssertEqual(frame.emerge, rest, accuracy: 1e-9)
        XCTAssertNotEqual(frame.active, .hover)
    }

    // MARK: - Click bounce

    func testClickProducesDecayingBounceThatComesToRest() {
        var state = ReactionState()

        var frame = state.update(cursor: nil, click: figure.center, figure: figure, at: 0)
        XCTAssertNotEqual(frame.bounce, 0)
        XCTAssertEqual(frame.active, .click)

        frame = state.update(cursor: nil, click: nil, figure: figure, at: 0.05)
        XCTAssertNotEqual(frame.bounce, 0)
        XCTAssertEqual(frame.active, .click)

        frame = state.update(
            cursor: nil, click: nil, figure: figure,
            at: ReactionTuning.bounceDuration + 0.01
        )
        XCTAssertEqual(frame.bounce, 0, accuracy: 1e-12)
        XCTAssertNotEqual(frame.active, .click)
    }

    func testClickDuringBounceStartsANewBounce() {
        var state = ReactionState()
        _ = state.update(cursor: nil, click: figure.center, figure: figure, at: 0)

        let mid = state.update(cursor: nil, click: nil, figure: figure, at: 0.3)
        let restart = state.update(cursor: nil, click: figure.center, figure: figure, at: 0.3)

        XCTAssertGreaterThan(abs(restart.bounce), abs(mid.bounce))
        XCTAssertEqual(restart.active, .click)
    }

    func testClickInsideFigureBounces() {
        var state = ReactionState()

        let frame = state.update(cursor: nil, click: figure.center, figure: figure, at: 0)

        XCTAssertNotEqual(frame.bounce, 0)
        XCTAssertEqual(frame.active, .click)
        XCTAssertEqual(frame.clickCount, 1)
    }

    func testClickFarOutsideFigureIsIgnored() {
        var state = ReactionState()

        let frame = state.update(cursor: nil, click: farAway, figure: figure, at: 0)

        XCTAssertEqual(frame.bounce, 0, accuracy: 1e-12)
        XCTAssertNotEqual(frame.active, .click)
        XCTAssertEqual(frame.clickCount, 0)
    }

    func testClickJustOutsideHoverRegionIsIgnored() {
        var state = ReactionState()
        XCTAssertFalse(
            figure.expanded(by: ReactionTuning.hoverPadding).contains(justOutsideHover),
            "test point must lie outside the hover region"
        )

        let frame = state.update(cursor: nil, click: justOutsideHover, figure: figure, at: 0)

        XCTAssertEqual(frame.bounce, 0, accuracy: 1e-12)
        XCTAssertNotEqual(frame.active, .click)
        XCTAssertEqual(frame.clickCount, 0)
    }

    func testOffFigureClickDoesNotIncreaseClickCount() {
        var state = ReactionState()

        let inside = state.update(cursor: nil, click: figure.center, figure: figure, at: 0)
        XCTAssertEqual(inside.clickCount, 1)

        let outside = state.update(cursor: nil, click: farAway, figure: figure, at: 0.1)
        XCTAssertEqual(outside.clickCount, 1)

        let alsoOutside = state.update(cursor: nil, click: justOutsideHover, figure: figure, at: 0.2)
        XCTAssertEqual(alsoOutside.clickCount, 1)
    }

    // MARK: - Arbitration

    func testReactivePreemptsMicroAndNeverEmitsItLate() {
        let clock = ManualClock(now: 1)
        var engine = ReactionEngine(seed: 5, personality: .playful, figure: figure, clock: clock)

        _ = engine.step(input: .idle)
        guard let due = engine.behavior.scheduledMicroTime else {
            return XCTFail("engine did not schedule a micro-behavior")
        }

        clock.set(due + 0.01)
        let reactive = engine.step(input: PipInput(cursor: figure.center))
        XCTAssertTrue(reactive.isReactive)
        XCTAssertTrue(reactive.microEvents.isEmpty, "micro-behavior leaked through a reaction")
        XCTAssertTrue(reactive.containsBreathing)

        clock.advance(by: ReactionTuning.bounceDuration + Personality.wakeDuration + 5)
        for _ in 0..<60 {
            clock.advance(by: 0.5)
            let out = engine.step(input: .idle)
            XCTAssertFalse(out.microEvents.contains { $0.time == due }, "preempted micro surfaced late")
        }
    }

    func testOutputReturnsToAmbientAfterReactionResolves() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 8, personality: .companion, figure: figure, clock: clock)

        clock.advance(by: 1)
        let reactive = engine.step(input: PipInput(cursor: figure.center, click: figure.center))
        XCTAssertEqual(reactive.reaction, .click)

        clock.advance(by: ReactionTuning.bounceDuration + 0.05)
        let resolved = engine.step(input: .idle)
        XCTAssertFalse(resolved.isReactive)
        XCTAssertTrue(resolved.containsBreathing)
    }

    // MARK: - Waking

    func testCursorHoverAndClickWakeDozingOrNappingPip() {
        let inputs: [PipInput] = [
            PipInput(cursor: nearButNotHovering),
            PipInput(cursor: figure.center),
            PipInput(cursor: nil, click: figure.center),
        ]

        for (index, input) in inputs.enumerated() {
            let clock = ManualClock()
            var engine = ReactionEngine(seed: UInt64(index), personality: .quiet, figure: figure, clock: clock)
            var t: TimeInterval = 0
            while t < 1000, engine.mood != .nap {
                t += 1
                clock.set(t)
                _ = engine.step(input: .idle)
            }
            XCTAssertEqual(engine.mood, .nap, "engine never napped for input \(index)")

            clock.advance(by: 1)
            let woken = engine.step(input: input)
            XCTAssertTrue(woken.mood.isAwake, "input \(index) did not wake Pip: \(woken.mood)")
        }
    }

    // MARK: - Determinism / protocol

    func testScriptedInputsReplayIdenticallyThroughTheProtocol() {
        let script: [PipInput] = (0..<60).map { i in
            PipInput(
                cursor: point(Double(i % 5) * 30 - 60, 20),
                click: i % 7 == 0 ? point(Double(i % 3), 0) : nil
            )
        }

        func run() -> [ReactionFrame] {
            let clock = ManualClock()
            let source = ScriptedInputSource(script)
            var engine = ReactionEngine(
                seed: 99, personality: .companion, figure: figure, source: source, clock: clock
            )
            var frames: [ReactionFrame] = []
            for _ in 0..<120 {
                clock.advance(by: 0.1)
                frames.append(engine.step().frame)
            }
            return frames
        }

        XCTAssertEqual(run(), run())
    }
}
