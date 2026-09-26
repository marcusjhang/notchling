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

/// The composed output: the ambient emission plus the reactive frame. Arbitration
/// is reactive > mood > micro, so micro-behaviors are suppressed while a
/// reaction is active.
public struct ReactionEmission: Equatable, Sendable {
    public let ambient: Emission
    public let frame: ReactionFrame
    public let time: TimeInterval

    public init(ambient: Emission, frame: ReactionFrame) {
        self.ambient = ambient
        self.frame = frame
        self.time = ambient.time
    }

    public var reaction: Reaction? { frame.active }
    public var gaze: Gaze { frame.gaze }
    public var emerge: Double { frame.emerge }
    public var bounce: Double { frame.bounce }
    public var isNear: Bool { frame.isNear }
    public var isHovering: Bool { frame.isHovering }
    public var mood: Mood { ambient.mood }
    public var isReactive: Bool { frame.active != nil }

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

/// Composes the ambient `BehaviorEngine` with `ReactionState` and arbitrates
/// between them. A reactive input also counts as activity, so a dozing or
/// napping Pip wakes up. Given the same seed, figure, injected clock, and input
/// script, the emitted sequence is identical on replay.
public struct ReactionEngine {
    public var behavior: BehaviorEngine
    public private(set) var reaction = ReactionState()
    public let figure: Rect
    public let clock: any NotchlingClock

    private let source: (any PipInputSource)?

    public init(
        seed: UInt64,
        personality: Personality = .companion,
        figure: Rect,
        source: (any PipInputSource)? = nil,
        clock: any NotchlingClock = SystemClock()
    ) {
        self.behavior = BehaviorEngine(seed: seed, personality: personality, clock: clock)
        self.figure = figure
        self.source = source
        self.clock = clock
    }

    public var now: TimeInterval { clock.now }
    public var mood: Mood { behavior.mood }

    @discardableResult
    public mutating func step() -> ReactionEmission {
        step(input: source?.readInput() ?? .idle)
    }

    @discardableResult
    public mutating func step(input: PipInput) -> ReactionEmission {
        let time = clock.now
        let frame = reaction.update(cursor: input.cursor, click: input.click, figure: figure, at: time)
        let ambient = frame.active != nil ? behavior.activity() : behavior.step()
        return ReactionEmission(ambient: ambient, frame: frame)
    }
}
