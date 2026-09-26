import Foundation

/// Whether the Mac can currently show animation at all. Screen lock is tracked
/// separately from display sleep so the app can resume correctly on the matching
/// wake/unlock notification.
public enum ScreenState: Equatable, Sendable {
    case active
    case asleep
    case locked

    public var isActive: Bool { self == .active }

    /// True when rendering must stop entirely (no timer at all).
    public var pausesAnimation: Bool { self != .active }
}

/// The single place that decides whether Pip may animate, and how fast. Mute,
/// display sleep/lock, and a full nap all stop drawing; a nap keeps a slow poll
/// alive so cursor or audio activity can wake Pip again.
public enum AnimationPolicy {
    /// Cadence while Pip is engaged (reacting, tracking the cursor, or mid
    /// micro-behavior). Fast enough that movement reads as motion.
    public static let activeFrameInterval: TimeInterval = 1.0 / 30.0
    /// Cadence for idle, unattended breathing. Slow enough that an awake-but-idle
    /// Pip stays well under ~1% CPU, fast enough that breathing still reads.
    public static let idleFrameInterval: TimeInterval = 1.0 / 6.0
    /// Slow poll while napping: cheap enough for near-zero CPU, fast enough to
    /// notice activity and resume.
    public static let napFrameInterval: TimeInterval = 1.0

    /// True only when frames are actually drawn.
    public static func shouldAnimate(
        settings: PipSettings,
        screenState: ScreenState,
        mood: Mood
    ) -> Bool {
        !settings.isMuted && screenState.isActive && !mood.isAsleep
    }

    /// The timer interval, or `nil` to stop the timer entirely. `engaged` keeps
    /// the active cadence while the pointer is moving or a reaction is live and
    /// drops to the slow idle cadence the rest of the time.
    public static func frameInterval(
        settings: PipSettings,
        screenState: ScreenState,
        mood: Mood,
        engaged: Bool
    ) -> TimeInterval? {
        if settings.isMuted || screenState.pausesAnimation { return nil }
        if mood.isAsleep { return napFrameInterval }
        return engaged ? activeFrameInterval : idleFrameInterval
    }
}
