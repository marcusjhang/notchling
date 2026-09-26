import XCTest
@testable import NotchlingCore

final class BehaviorEngineTests: XCTestCase {
    private let step: TimeInterval = 0.5

    // MARK: - Determinism

    func testIdenticalSeedAndClockProduceIdenticalSequences() {
        let clockA = ManualClock()
        let clockB = ManualClock()
        var a = BehaviorEngine(seed: 42, personality: .companion, clock: clockA)
        var b = BehaviorEngine(seed: 42, personality: .companion, clock: clockB)

        var sequenceA: [Emission] = []
        var sequenceB: [Emission] = []
        for _ in 0..<2400 {
            clockA.advance(by: step)
            clockB.advance(by: step)
            sequenceA.append(a.step())
            sequenceB.append(b.step())
        }
        XCTAssertEqual(sequenceA, sequenceB)
    }

    func testSteppingTwiceOnFrozenClockIsIdentical() {
        let clock = ManualClock(now: 12)
        var engine = BehaviorEngine(seed: 3, personality: .playful, clock: clock)
        let first = engine.step()
        let second = engine.step()
        XCTAssertEqual(first, second)
    }

    // MARK: - Injected clock drives everything

    func testFrozenClockEmitsOnlyBreathingAndNoMoodTransition() {
        let clock = ManualClock(now: 0)
        var engine = BehaviorEngine(seed: 7, personality: .quiet, clock: clock)
        for _ in 0..<1000 {
            let emission = engine.step()
            XCTAssertEqual(emission.behaviors, [.breathe])
            XCTAssertTrue(emission.microBehaviors.isEmpty)
            XCTAssertEqual(emission.mood, .idle)
        }
        XCTAssertEqual(engine.mood, .idle)
    }

    // MARK: - Budget and cadence

    func testMicroBehaviorsRespectCadenceAndBudget() {
        let window: TimeInterval = 1800
        for personality in Personality.allCases {
            let clock = ManualClock()
            var engine = BehaviorEngine(seed: 123, personality: personality, clock: clock)

            var microTimes: [TimeInterval] = []
            var t: TimeInterval = 0
            while t < window {
                t += 0.25
                clock.set(t)
                microTimes.append(contentsOf: engine.step().microEvents.map(\.time))
            }

            let ordered = microTimes.sorted()
            for (previous, next) in zip(ordered, ordered.dropFirst()) {
                let gap = next - previous
                XCTAssertGreaterThanOrEqual(
                    gap + 1e-9, personality.cadence.lowerBound,
                    "\(personality) gap \(gap) below cadence"
                )
                XCTAssertLessThanOrEqual(
                    gap, personality.cadence.upperBound + 1e-9,
                    "\(personality) gap \(gap) above cadence"
                )
            }
            XCTAssertLessThanOrEqual(
                ordered.count, personality.attentionBudget(inWindow: window),
                "\(personality) exceeded its attention budget"
            )
        }
    }

    func testFrequencyOrdersQuietBelowCompanionBelowPlayful() {
        let window: TimeInterval = 3600

        func microCount(_ personality: Personality) -> Int {
            let clock = ManualClock()
            var engine = BehaviorEngine(seed: 99, personality: personality, clock: clock)
            var count = 0
            var t: TimeInterval = 0
            while t < window {
                t += 1
                clock.set(t)
                count += engine.step().microEvents.count
            }
            return count
        }

        let quiet = microCount(.quiet)
        let companion = microCount(.companion)
        let playful = microCount(.playful)
        XCTAssertLessThan(quiet, companion)
        XCTAssertLessThan(companion, playful)
    }

    // MARK: - Mood arc

    func testMoodArcReachesDozeThenNapAndActivityWakes() {
        let clock = ManualClock()
        var engine = BehaviorEngine(seed: 1, personality: .quiet, clock: clock)

        var moods: [Mood] = []
        var t: TimeInterval = 0
        while t < 200 {
            t += 1
            clock.set(t)
            moods.append(engine.step().mood)
        }

        guard let dozeIndex = moods.firstIndex(of: .doze),
              let napIndex = moods.firstIndex(of: .nap) else {
            return XCTFail("mood arc never reached doze and nap")
        }
        XCTAssertLessThan(dozeIndex, napIndex)
        XCTAssertEqual(engine.mood, .nap)

        clock.advance(by: 1)
        let woken = engine.activity()
        XCTAssertTrue(woken.mood.isAwake)
        XCTAssertEqual(woken.mood, .wake)

        clock.advance(by: Personality.wakeDuration + 1)
        XCTAssertTrue(engine.step().mood.isAwake)
    }

    func testNapOnsetOrdersQuietBeforeCompanionBeforePlayful() {
        func napOnset(_ personality: Personality) -> TimeInterval {
            let clock = ManualClock()
            var engine = BehaviorEngine(seed: 11, personality: personality, clock: clock)
            var t: TimeInterval = 0
            while t < 2000 {
                t += 1
                clock.set(t)
                if engine.step().mood == .nap { return t }
            }
            return .infinity
        }

        XCTAssertLessThan(napOnset(.quiet), napOnset(.companion))
        XCTAssertLessThan(napOnset(.companion), napOnset(.playful))
    }

    // MARK: - Breathing and coverage

    func testBreathingIsEmittedInEveryStepOfEveryMood() {
        let clock = ManualClock()
        var engine = BehaviorEngine(seed: 5, personality: .quiet, clock: clock)
        var moodsSeen = Set<Mood>()

        for _ in 0..<2000 {
            clock.advance(by: 1)
            let emission = engine.step()
            XCTAssertTrue(emission.containsBreathing)
            moodsSeen.insert(emission.mood)
        }

        XCTAssertTrue(moodsSeen.contains(.idle))
        XCTAssertTrue(moodsSeen.contains(.doze))
        XCTAssertTrue(moodsSeen.contains(.nap))
    }

    func testEveryMicroBehaviorAppearsOverLongSeededRun() {
        let clock = ManualClock()
        var engine = BehaviorEngine(seed: 2026, personality: .companion, clock: clock)
        var seen = Set<Behavior>()
        var t: TimeInterval = 0
        while t < 3600 {
            t += 0.5
            clock.set(t)
            seen.formUnion(engine.step().microBehaviors)
        }
        for behavior in Behavior.microBehaviors {
            XCTAssertTrue(seen.contains(behavior), "missing \(behavior)")
        }
    }

    func testChangingOnlyPersonalityChangesEmissionSequence() {
        let clockA = ManualClock()
        let clockB = ManualClock()
        var quiet = BehaviorEngine(seed: 77, personality: .quiet, clock: clockA)
        var playful = BehaviorEngine(seed: 77, personality: .playful, clock: clockB)

        var quietMicros = 0
        var playfulMicros = 0
        for _ in 0..<1200 {
            clockA.advance(by: step)
            clockB.advance(by: step)
            quietMicros += quiet.step().microEvents.count
            playfulMicros += playful.step().microEvents.count
        }
        XCTAssertGreaterThan(playfulMicros, quietMicros)
    }
}
