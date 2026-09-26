import Foundation

/// A behavior paired with the simulated time it occurred at. Carrying the time
/// lets callers verify scheduling (cadence gaps, budget) even when they step the
/// engine in coarse increments.
public struct BehaviorEvent: Equatable, Sendable {
    public let behavior: Behavior
    public let time: TimeInterval

    public init(behavior: Behavior, time: TimeInterval) {
        self.behavior = behavior
        self.time = time
    }
}

/// Everything the engine produced for one step.
public struct Emission: Equatable, Sendable {
    /// Breathing first, then any micro-behaviors whose scheduled time has passed.
    public let events: [BehaviorEvent]
    public let mood: Mood
    public let time: TimeInterval

    public init(events: [BehaviorEvent], mood: Mood, time: TimeInterval) {
        self.events = events
        self.mood = mood
        self.time = time
    }

    public var behaviors: [Behavior] { events.map(\.behavior) }
    public var microEvents: [BehaviorEvent] { events.filter { $0.behavior.isMicro } }
    public var microBehaviors: [Behavior] { microEvents.map(\.behavior) }
    public var containsBreathing: Bool { events.contains { $0.behavior == .breathe } }
}

/// Deterministic, clock-injected ambient behavior state machine.
///
/// Breathing is emitted on every step in every mood. Micro-behaviors are
/// scheduled one-at-a-time with a gap drawn from the active personality's
/// cadence, so the attention budget can never be exceeded and observed gaps
/// stay inside the cadence range. Randomness comes only from the seed, and time
/// only from the injected clock, so a fixed seed plus a fixed clock reproduces
/// the exact same sequence of emissions.
public struct BehaviorEngine {
    public let seed: UInt64
    public var personality: Personality
    public let clock: any NotchlingClock

    public private(set) var mood: Mood = .idle
    public private(set) var lastActivityTime: TimeInterval?
    public private(set) var scheduledMicroTime: TimeInterval?

    public var now: TimeInterval { clock.now }

    private var rng: SplitMix64
    private var deck: [Behavior] = []
    private var wakeUntil: TimeInterval = 0
    private var started = false

    public init(
        seed: UInt64,
        personality: Personality = .companion,
        clock: any NotchlingClock = SystemClock()
    ) {
        self.seed = seed
        self.personality = personality
        self.clock = clock
        self.rng = SplitMix64(seed: seed)
    }

    /// Advance simulated time to the clock's current reading and emit for this
    /// step. Stepping without moving the injected clock produces only breathing
    /// and no mood transition.
    @discardableResult
    public mutating func step() -> Emission {
        let t = clock.now
        if !started {
            started = true
            lastActivityTime = t
            scheduleNextMicro(after: t)
        }

        var events: [BehaviorEvent] = [BehaviorEvent(behavior: .breathe, time: t)]

        var emitted = 0
        while let next = scheduledMicroTime, next <= t, emitted < 1_000_000 {
            events.append(BehaviorEvent(behavior: drawMicroBehavior(), time: next))
            scheduleNextMicro(after: next)
            emitted += 1
        }

        updateMood(at: t)
        return Emission(events: events, mood: mood, time: t)
    }

    /// Deliver an activity interrupt (cursor, hover, click, audio, input) at the
    /// clock's current reading. This resets the idle timer and wakes Pip out of
    /// doze or nap.
    @discardableResult
    public mutating func activity() -> Emission {
        let t = clock.now
        started = true
        lastActivityTime = t
        wakeUntil = t + Personality.wakeDuration
        mood = .wake
        scheduleNextMicro(after: t)
        return Emission(events: [BehaviorEvent(behavior: .breathe, time: t)], mood: mood, time: t)
    }

    private mutating func updateMood(at t: TimeInterval) {
        switch mood {
        case .wake:
            if t >= wakeUntil {
                mood = .idle
            }
        case .nap:
            break
        case .idle, .doze:
            guard let since = lastActivityTime else { return }
            let idle = t - since
            if idle >= personality.napDelay {
                mood = .nap
            } else if idle >= personality.dozeDelay {
                mood = .doze
            } else {
                mood = .idle
            }
        }
    }

    private mutating func scheduleNextMicro(after time: TimeInterval) {
        let gap = Double.random(in: personality.cadence, using: &rng)
        scheduledMicroTime = time + gap
    }

    /// Emit the six micro-behaviors from a shuffled deck, reshuffled when
    /// exhausted. Random yet guaranteed to cover every behavior within six draws.
    private mutating func drawMicroBehavior() -> Behavior {
        if deck.isEmpty {
            deck = Behavior.microBehaviors.shuffled(using: &rng)
        }
        return deck.removeLast()
    }
}

/// Small, dependency-free deterministic generator (SplitMix64).
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
