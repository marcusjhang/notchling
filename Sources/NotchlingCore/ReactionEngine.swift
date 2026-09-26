import Foundation

/// One read of the pointer state. A non-nil `click` is an edge carrying the
/// click location: a source reports it once and the consumer's read clears it.
/// Whether the click counts is decided in `NotchlingCore` from that location.
public struct PipInput: Equatable, Sendable {
    public var cursor: Point?
    public var click: Point?

    public init(cursor: Point? = nil, click: Point? = nil) {
        self.cursor = cursor
        self.click = click
    }

    public static let idle = PipInput()
}

/// Where reactive input comes from. The app implements this with a global
/// `NSEvent` monitor; tests supply scripted sequences. Keeping it a protocol is
/// what lets the core stay free of AppKit and stay replayable.
public protocol PipInputSource: AnyObject {
    func readInput() -> PipInput
}

/// The composed output: the ambient emission plus the reactive frame and the
/// system state. Arbitration is reactive > mood > micro, so micro-behaviors are
/// suppressed while any reaction is active. When a pointer reaction and a system
/// reaction are both present, exactly one survives (see `Reaction.arbitrate`).
public struct ReactionEmission: Equatable, Sendable {
    public let ambient: Emission
    public let frame: ReactionFrame
    public let system: SystemState
    public let timeOfDay: TimeOfDay
    /// The single arbitrated reaction, pointer or system.
    public let reaction: Reaction?

    public init(
        ambient: Emission,
        frame: ReactionFrame,
        system: SystemState = .idle,
        timeOfDay: TimeOfDay = .daytime,
        reaction: Reaction? = nil
    ) {
        self.ambient = ambient
        self.frame = frame
        self.system = system
        self.timeOfDay = timeOfDay
        self.reaction = reaction ?? frame.active
    }

    public var time: TimeInterval { ambient.time }
    public var pointerReaction: Reaction? { frame.active }
    public var systemReaction: Reaction? { Reaction.system(from: system) }
    public var gaze: Gaze { frame.gaze }
    public var emerge: Double { frame.emerge }
    public var bounce: Double { frame.bounce }
    public var isNear: Bool { frame.isNear }
    public var isHovering: Bool { frame.isHovering }
    public var mood: Mood { ambient.mood }
    public var isReactive: Bool { reaction != nil }

    public var isMusicPlaying: Bool { reaction == .music }
    public var isCharging: Bool { reaction == .charging }
    public var isMorning: Bool { timeOfDay == .morning }
    public var isNightcap: Bool { timeOfDay == .night }

    /// The behavior events that survive arbitration. While reactive, only the
    /// continuous breathe passes; micro-behaviors are dropped here and, because
    /// the ambient engine already advanced its schedule, are never emitted late.
    public var events: [BehaviorEvent] {
        isReactive ? ambient.events.filter { $0.behavior == .breathe } : ambient.events
    }

    public var behaviors: [Behavior] { events.map(\.behavior) }
    public var microEvents: [BehaviorEvent] { events.filter { $0.behavior.isMicro } }
    public var microBehaviors: [Behavior] { microEvents.map(\.behavior) }
    public var containsBreathing: Bool { events.contains { $0.behavior == .breathe } }
}

/// Composes the ambient `BehaviorEngine` with `ReactionState` and the injected
/// system state, then arbitrates down to at most one reaction. A pointer or
/// system reaction also counts as activity, so a dozing or napping Pip wakes up.
/// Given the same seed, figure, injected clock, and scripted pointer and system
/// inputs, the emitted sequence is identical on replay.
public struct ReactionEngine {
    public var behavior: BehaviorEngine
    public private(set) var reaction = ReactionState()
    public let figure: Rect
    public let clock: any NotchlingClock
    public let calendar: Calendar

    private let source: (any PipInputSource)?
    private let systemSource: (any SystemStateSource)?

    public init(
        seed: UInt64,
        personality: Personality = .companion,
        figure: Rect,
        source: (any PipInputSource)? = nil,
        systemSource: (any SystemStateSource)? = nil,
        clock: any NotchlingClock = SystemClock(),
        calendar: Calendar = .current
    ) {
        self.behavior = BehaviorEngine(seed: seed, personality: personality, clock: clock)
        self.figure = figure
        self.source = source
        self.systemSource = systemSource
        self.clock = clock
        self.calendar = calendar
    }

    public var now: TimeInterval { clock.now }
    public var mood: Mood { behavior.mood }

    /// The time-of-day mood for the clock's current reading.
    public var timeOfDay: TimeOfDay {
        TimeOfDay(date: Date(timeIntervalSinceReferenceDate: clock.now), calendar: calendar)
    }

    /// Force a wake interrupt without a pointer or system trigger. Used when the
    /// app resumes after muting or display sleep, so Pip does not come back
    /// straight into doze/nap.
    @discardableResult
    public mutating func wake() -> Emission {
        behavior.activity()
    }

    @discardableResult
    public mutating func step() -> ReactionEmission {
        step(input: source?.readInput() ?? .idle, system: systemSource?.readSystemState() ?? .idle)
    }

    @discardableResult
    public mutating func step(input: PipInput) -> ReactionEmission {
        step(input: input, system: systemSource?.readSystemState() ?? .idle)
    }

    @discardableResult
    public mutating func step(system: SystemState) -> ReactionEmission {
        step(input: source?.readInput() ?? .idle, system: system)
    }

    @discardableResult
    public mutating func step(input: PipInput, system: SystemState) -> ReactionEmission {
        let time = clock.now
        let frame = reaction.update(cursor: input.cursor, click: input.click, figure: figure, at: time)
        let day = TimeOfDay(date: Date(timeIntervalSinceReferenceDate: time), calendar: calendar)
        let resolved = Reaction.arbitrate(pointer: frame.active, system: Reaction.system(from: system))
        let ambient = resolved != nil ? behavior.activity() : behavior.step()
        return ReactionEmission(
            ambient: ambient,
            frame: frame,
            system: system,
            timeOfDay: day,
            reaction: resolved
        )
    }
}
