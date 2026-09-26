import XCTest
@testable import NotchlingCore

/// A deterministic system-state script. Implements the same protocol the app's
/// CoreAudio/IOKit monitors use, so the triggers are exercised with no hardware.
final class ScriptedSystemSource: SystemStateSource {
    private let script: [SystemState]
    private var index = 0

    init(_ script: [SystemState]) {
        self.script = script
    }

    func readSystemState() -> SystemState {
        defer { index += 1 }
        return script[min(index, script.count - 1)]
    }
}

final class SystemReactionTests: XCTestCase {
    private let figure = Rect(x: 700, y: 900, width: 56, height: 56)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func instant(hour: Int, minute: Int = 0) -> TimeInterval {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = hour
        components.minute = minute
        return utc.date(from: components)!.timeIntervalSinceReferenceDate
    }

    // MARK: - Music

    func testMusicReactionActivatesPersistsAndClears() {
        let clock = ManualClock()
        let source = ScriptedSystemSource([.music, .music, .idle])
        var engine = ReactionEngine(
            seed: 7, personality: .companion, figure: figure, systemSource: source, clock: clock
        )

        clock.advance(by: 1)
        let first = engine.step()
        XCTAssertEqual(first.reaction, .music)
        XCTAssertTrue(first.isReactive)
        XCTAssertTrue(first.containsBreathing)

        clock.advance(by: 1)
        let still = engine.step()
        XCTAssertEqual(still.reaction, .music, "music reaction must persist while the device runs")

        clock.advance(by: 1)
        let stopped = engine.step()
        XCTAssertNil(stopped.reaction)
        XCTAssertFalse(stopped.isReactive)
        XCTAssertTrue(stopped.containsBreathing, "should fall back to ambient breathing")
    }

    func testNoMusicReactionWhenOutputIsIdle() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 3, personality: .companion, figure: figure, clock: clock)
        let out = engine.step(system: .idle)
        XCTAssertNil(out.reaction)
        XCTAssertFalse(out.isMusicPlaying)
    }

    // MARK: - Charging

    func testChargingReactionActivatesAndClears() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 4, personality: .companion, figure: figure, clock: clock)

        let charging = engine.step(system: .charging)
        XCTAssertEqual(charging.reaction, .charging)
        XCTAssertTrue(charging.isCharging)
        XCTAssertTrue(charging.containsBreathing)

        clock.advance(by: 1)
        let unplugged = engine.step(system: .idle)
        XCTAssertNil(unplugged.reaction)
        XCTAssertFalse(unplugged.isCharging)
    }

    func testChargingOutranksMusicWhenBothAreActive() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 5, personality: .companion, figure: figure, clock: clock)
        let both = engine.step(system: SystemState(audioOutputRunning: true, isCharging: true))
        XCTAssertEqual(both.reaction, .charging, "exactly one system reaction; charging wins")
    }

    // MARK: - Time of day

    func testTimeOfDayFromInjectedClockOnly() {
        let clock = ManualClock()
        let engine = ReactionEngine(
            seed: 1, personality: .companion, figure: figure, clock: clock, calendar: utc
        )

        clock.set(instant(hour: 8))
        XCTAssertEqual(engine.timeOfDay, .morning)
        XCTAssertTrue(engine.timeOfDay.isPerky)

        clock.set(instant(hour: 12))
        XCTAssertEqual(engine.timeOfDay, .daytime)

        clock.set(instant(hour: 22))
        XCTAssertNotEqual(engine.timeOfDay, .night)
        XCTAssertFalse(engine.timeOfDay.isNightcap)

        clock.set(instant(hour: 23, minute: 30))
        XCTAssertEqual(engine.timeOfDay, .night)
        XCTAssertTrue(engine.timeOfDay.isNightcap)
    }

    func testSteppingClockAcrossBoundaryChangesReportedTimeOfDay() {
        let clock = ManualClock(now: instant(hour: 22))
        var engine = ReactionEngine(
            seed: 2, personality: .companion, figure: figure, clock: clock, calendar: utc
        )

        XCTAssertEqual(engine.step().timeOfDay, .daytime)

        clock.set(instant(hour: 23, minute: 5))
        let night = engine.step()
        XCTAssertEqual(night.timeOfDay, .night)
        XCTAssertTrue(night.isNightcap)
        XCTAssertNil(night.reaction, "time of day is a mood, not a reaction")
        XCTAssertTrue(night.containsBreathing)
    }

    func testEveryEmissionCarriesTimeOfDay() {
        let clock = ManualClock(now: instant(hour: 9))
        var engine = ReactionEngine(
            seed: 9, personality: .playful, figure: figure, clock: clock, calendar: utc
        )
        for _ in 0..<10 {
            clock.advance(by: 1)
            XCTAssertEqual(engine.step().timeOfDay, .morning)
        }
    }

    // MARK: - Activity / waking

    func testMusicAndChargingWakeDozingOrNappingPip() {
        let states: [SystemState] = [.music, .charging]

        for (index, state) in states.enumerated() {
            let clock = ManualClock()
            var engine = ReactionEngine(
                seed: UInt64(index), personality: .quiet, figure: figure, clock: clock
            )
            var t: TimeInterval = 0
            while t < 1000, engine.mood != .nap {
                t += 1
                clock.set(t)
                _ = engine.step(system: .idle)
            }
            XCTAssertEqual(engine.mood, .nap, "engine never napped for state \(index)")

            clock.advance(by: 1)
            let woken = engine.step(system: state)
            XCTAssertTrue(woken.mood.isAwake, "system state \(index) did not wake Pip: \(woken.mood)")
            XCTAssertTrue(woken.containsBreathing)
        }
    }

    // MARK: - Arbitration

    func testSystemAndPointerReactionsArbitrateToExactlyOne() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 6, personality: .companion, figure: figure, clock: clock)

        let pointerNear = PipInput(cursor: Point(x: figure.center.x + 45, y: figure.center.y))
        let together = engine.step(input: pointerNear, system: .music)

        XCTAssertNotNil(together.reaction)
        XCTAssertEqual(together.reaction, .cursorNear, "pointer reactions outrank ambient system ones")
        XCTAssertEqual(together.pointerReaction, .cursorNear)
        XCTAssertEqual(together.systemReaction, .music)
        XCTAssertTrue(together.microEvents.isEmpty, "no micro-behavior while any reaction is active")
        XCTAssertTrue(together.containsBreathing)
    }

    func testSystemOnlyArbitrationReportsTheSystemReaction() {
        let clock = ManualClock()
        var engine = ReactionEngine(seed: 6, personality: .companion, figure: figure, clock: clock)
        let out = engine.step(input: .idle, system: .music)
        XCTAssertEqual(out.reaction, .music)
        XCTAssertTrue(out.microEvents.isEmpty)
    }

    // MARK: - Determinism

    func testScriptedPointerAndSystemInputsReplayIdentically() {
        let pointers: [PipInput] = (0..<60).map { i in
            PipInput(cursor: Point(x: figure.center.x + Double(i % 5) * 30 - 60, y: figure.center.y + 20))
        }
        let systems: [SystemState] = (0..<60).map { i in
            switch i % 4 {
            case 0: return SystemState(audioOutputRunning: true)
            case 1: return SystemState(isCharging: true)
            case 2: return SystemState(audioOutputRunning: true, isCharging: true)
            default: return .idle
            }
        }

        func run() -> [ReactionEmission] {
            let clock = ManualClock()
            let pointerSource = ScriptedInputSource(pointers)
            let systemSource = ScriptedSystemSource(systems)
            var engine = ReactionEngine(
                seed: 99,
                personality: .companion,
                figure: figure,
                source: pointerSource,
                systemSource: systemSource,
                clock: clock,
                calendar: utc
            )
            var emissions: [ReactionEmission] = []
            for _ in 0..<120 {
                clock.advance(by: 0.1)
                emissions.append(engine.step())
            }
            return emissions
        }

        XCTAssertEqual(run(), run())
    }
}
