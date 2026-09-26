import Foundation

/// Time source for the behavior engine. The engine never reads wall-clock time
/// itself: it only ever asks its injected clock, so tests can drive time
/// deterministically with a `ManualClock`.
public protocol NotchlingClock {
    var now: TimeInterval { get }
}

/// Reads real time. Used by the running app.
public struct SystemClock: NotchlingClock {
    public init() {}
    public var now: TimeInterval { Date().timeIntervalSinceReferenceDate }
}

/// A clock the caller moves by hand. Inject one in tests to advance simulated
/// time independently of the wall clock.
public final class ManualClock: NotchlingClock {
    public private(set) var now: TimeInterval

    public init(now: TimeInterval = 0) {
        self.now = now
    }

    public func advance(by delta: TimeInterval) {
        now += delta
    }

    public func set(_ time: TimeInterval) {
        now = time
    }
}
