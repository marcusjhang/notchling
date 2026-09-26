import XCTest
@testable import NotchlingCore

final class AnimationPolicyTests: XCTestCase {
    func testAnimatesWhenActiveUnmutedAndAwake() {
        XCTAssertTrue(
            AnimationPolicy.shouldAnimate(settings: .standard, screenState: .active, mood: .idle)
        )
        XCTAssertEqual(
            AnimationPolicy.frameInterval(
                settings: .standard, screenState: .active, mood: .idle, engaged: true
            ),
            AnimationPolicy.activeFrameInterval
        )
    }

    func testIdleDropsToSlowCadenceButKeepsAnimating() {
        XCTAssertTrue(
            AnimationPolicy.shouldAnimate(settings: .standard, screenState: .active, mood: .idle)
        )
        XCTAssertEqual(
            AnimationPolicy.frameInterval(
                settings: .standard, screenState: .active, mood: .idle, engaged: false
            ),
            AnimationPolicy.idleFrameInterval
        )
        XCTAssertGreaterThan(AnimationPolicy.idleFrameInterval, AnimationPolicy.activeFrameInterval)
    }

    func testMuteStopsAllAnimation() {
        var settings = PipSettings.standard
        settings.isMuted = true
        XCTAssertFalse(AnimationPolicy.shouldAnimate(settings: settings, screenState: .active, mood: .idle))
        XCTAssertNil(AnimationPolicy.frameInterval(
            settings: settings, screenState: .active, mood: .idle, engaged: true
        ))
    }

    func testDisplaySleepAndSessionLockStopAllAnimation() {
        for state in [ScreenState.asleep, .locked] {
            XCTAssertFalse(AnimationPolicy.shouldAnimate(settings: .standard, screenState: state, mood: .idle))
            XCTAssertNil(AnimationPolicy.frameInterval(
                settings: .standard, screenState: state, mood: .idle, engaged: true
            ))
        }
    }

    func testNapStopsDrawingButKeepsASlowPoll() {
        XCTAssertFalse(AnimationPolicy.shouldAnimate(settings: .standard, screenState: .active, mood: .nap))
        XCTAssertEqual(
            AnimationPolicy.frameInterval(
                settings: .standard, screenState: .active, mood: .nap, engaged: true
            ),
            AnimationPolicy.napFrameInterval
        )
        XCTAssertEqual(
            AnimationPolicy.frameInterval(
                settings: .standard, screenState: .active, mood: .nap, engaged: false
            ),
            AnimationPolicy.napFrameInterval
        )
    }

    func testDozeStillAnimates() {
        XCTAssertTrue(AnimationPolicy.shouldAnimate(settings: .standard, screenState: .active, mood: .doze))
        XCTAssertEqual(
            AnimationPolicy.frameInterval(
                settings: .standard, screenState: .active, mood: .doze, engaged: true
            ),
            AnimationPolicy.activeFrameInterval
        )
    }
}
