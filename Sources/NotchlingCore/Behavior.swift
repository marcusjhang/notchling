import Foundation

/// A single thing Pip can do. `.breathe` is the always-on baseline; the other
/// six are the randomized micro-behaviors drawn from the attention budget.
public enum Behavior: String, CaseIterable, Equatable, Sendable {
    case breathe
    case blink
    case lookAround
    case earTwitch
    case weightShift
    case stretch
    case yawn

    public static let microBehaviors: [Behavior] = [
        .blink, .lookAround, .earTwitch, .weightShift, .stretch, .yawn
    ]

    public var isMicro: Bool { self != .breathe }
    public var isBreathing: Bool { self == .breathe }
}

/// The longer ambient arc. `wake` is the brief stretch after an activity
/// interrupt; it settles back to `idle`. `nap` is only left on activity.
public enum Mood: String, CaseIterable, Equatable, Sendable {
    case idle
    case doze
    case nap
    case wake

    public var isAsleep: Bool { self == .nap }
    public var isAwake: Bool { self == .idle || self == .wake }
}
