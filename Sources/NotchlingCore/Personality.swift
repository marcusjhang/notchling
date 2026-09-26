import Foundation

/// The personality dial: how often Pip fidgets and how long he stays awake
/// before dozing and napping. Ranges are deliberately non-overlapping between
/// adjacent personalities so their cadence ordering is stable.
public enum Personality: String, CaseIterable, Equatable, Sendable {
    case quiet
    case companion
    case playful

    /// Delay between consecutive micro-behaviors, in seconds.
    public var cadence: ClosedRange<TimeInterval> {
        switch self {
        case .quiet: return 25...45
        case .companion: return 8...20
        case .playful: return 4...10
        }
    }

    /// Idle time before Pip starts to doze.
    public var dozeDelay: TimeInterval {
        switch self {
        case .quiet: return 45
        case .companion: return 150
        case .playful: return 300
        }
    }

    /// Idle time before Pip is fully asleep.
    public var napDelay: TimeInterval {
        switch self {
        case .quiet: return 90
        case .companion: return 300
        case .playful: return 600
        }
    }

    /// How long the `wake` mood lasts after an activity interrupt.
    public static let wakeDuration: TimeInterval = 3

    /// The most micro-behaviors this personality may emit inside `window`.
    public func attentionBudget(inWindow window: TimeInterval) -> Int {
        guard window > 0 else { return 0 }
        return Int(window / cadence.lowerBound) + 1
    }
}
