import Foundation

/// A closed-form damped harmonic oscillator, the physics behind Pip's
/// squash/stretch. An underdamped spring (`dampingFraction < 1`) overshoots its
/// target and rings back down, which is what makes a discrete pose change read as
/// anticipation and overshoot instead of a flat linear ramp. Pure and
/// deterministic, so the motion is asserted by tests rather than trusted.
public struct Spring: Equatable, Sendable {
    /// Seconds for the oscillation; the same meaning as SwiftUI's spring response.
    public var response: Double
    /// 1 is critically damped (no overshoot); below 1 overshoots.
    public var dampingFraction: Double

    public init(response: Double = 0.45, dampingFraction: Double = 0.5) {
        self.response = response
        self.dampingFraction = dampingFraction
    }

    /// A repeated `sharedSpring`, matching what the app animates with.
    public static let pip = Spring(response: 0.45, dampingFraction: 0.5)

    /// Time after which the spring is within `tolerance` of its target. Used to
    /// stop sampling a settled animation.
    public static func settleTime(response: Double, dampingFraction: Double, tolerance: Double = 0.01) -> TimeInterval {
        let spring = Spring(response: response, dampingFraction: dampingFraction)
        var t: TimeInterval = 0
        let step = response / 40
        while t < response * 12 {
            if abs(spring.value(elapsed: t) - 1) <= tolerance { break }
            t += step
        }
        return t
    }

    /// The normalized position (0 at `elapsed == 0`, 1 at rest) in `0...1` target
    /// space. Underdamped springs exceed 1 before settling: the overshoot.
    public func value(elapsed: Double) -> Double {
        displacement(elapsed: elapsed)
    }

    /// Map the normalized spring onto an arbitrary from/to range.
    public func value(elapsed: Double, from: Double, to: Double) -> Double {
        from + (to - from) * displacement(elapsed: elapsed)
    }

    private func displacement(elapsed: Double) -> Double {
        let t = max(0, elapsed)
        let omega = 2 * Double.pi / max(response, 1e-6)
        let zeta = min(max(dampingFraction, 0), 1)
        if zeta >= 1 {
            let e = exp(-omega * t)
            return 1 - e * (1 + omega * t)
        }
        let damped = omega * (1 - zeta * zeta).squareRoot()
        let e = exp(-zeta * omega * t)
        return 1 - e * (cos(damped * t) + (zeta * omega / damped) * sin(damped * t))
    }
}
