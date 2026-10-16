import XCTest
@testable import NotchlingCore

final class SpringTests: XCTestCase {
    func testUnderdampedSpringOvershootsBeforeSettling() {
        let spring = Spring(response: 0.45, dampingFraction: 0.5)

        var peak = 0.0
        var t: TimeInterval = 0
        while t <= spring.response * 4 {
            peak = max(peak, spring.value(elapsed: t))
            t += spring.response / 200
        }

        XCTAssertGreaterThan(peak, 1.02, "an underdamped spring must overshoot its resting value")
        XCTAssertEqual(spring.value(elapsed: spring.response * 12), 1, accuracy: 0.01)
    }

    func testSpringIsNotLinearInterpolation() {
        let spring = Spring(response: 0.6, dampingFraction: 0.45)
        let halfway = spring.value(elapsed: spring.response * 0.5)
        XCTAssertGreaterThan(abs(halfway - 0.5), 0.05, "the response should differ noticeably from a linear ramp")
    }

    func testCriticallyDampedSpringDoesNotOvershoot() {
        let spring = Spring(response: 0.5, dampingFraction: 1)

        var peak = 0.0
        var t: TimeInterval = 0
        while t <= spring.response * 6 {
            peak = max(peak, spring.value(elapsed: t))
            t += spring.response / 200
        }

        XCTAssertLessThanOrEqual(peak, 1.001)
    }

    func testSpringMapsOntoAnArbitraryRange() {
        let spring = Spring(response: 0.45, dampingFraction: 0.5)
        XCTAssertEqual(spring.value(elapsed: -1, from: -0.12, to: 0), -0.12, accuracy: 1e-9)

        var dipped = false
        var t: TimeInterval = 0
        while t <= spring.response * 4 {
            if spring.value(elapsed: t, from: -0.12, to: 0) > 0 { dipped = true }
            t += spring.response / 200
        }
        XCTAssertTrue(dipped, "the spring should cross the resting value (overshoot)")
    }
}
