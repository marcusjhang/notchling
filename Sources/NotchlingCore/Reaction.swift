import Foundation

/// Explicit limits for the reactive layer. The spec fixes four of them: the
/// maximum gaze turn, the hover-emerge release time, and the click-bounce decay.
public enum ReactionTuning {
    /// Extra margin around the figure that counts as "cursor near".
    public static let proximityPadding: Double = 30
    /// Extra margin around the figure that counts as "hovering Pip".
    public static let hoverPadding: Double = 2
    /// Hard ceiling on gaze/turn magnitude, regardless of cursor distance.
    public static let maxTurn: Double = 1.0
    /// Distance at which the gaze reaches `maxTurn`; closer is weaker, farther clamps.
    public static let gazeReferenceRadius: Double = 140
    /// How far Pip emerges while hovered.
    public static let hoverEmerge: Double = 7
    /// Time to settle back to the non-hovered offset after hover ends.
    public static let emergeReleaseDuration: TimeInterval = 0.45
    public static let bounceAmplitude: Double = 0.22
    public static let bounceFrequency: Double = 2.2
    public static let bounceDecay: TimeInterval = 0.28
    /// After this long the bounce is exactly at rest.
    public static let bounceDuration: TimeInterval = 0.9
}

/// A clamped direction from Pip's figure toward the cursor. Magnitude is at most
/// `ReactionTuning.maxTurn`; direction always points at the cursor.
public struct Gaze: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }

    public static let zero = Gaze()

    public var magnitude: Double { (x * x + y * y).squareRoot() }

    public static func toward(
        center: Point,
        target: Point,
        referenceRadius: Double = ReactionTuning.gazeReferenceRadius,
        maxTurn: Double = ReactionTuning.maxTurn
    ) -> Gaze {
        let dx = target.x - center.x
        let dy = target.y - center.y
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance > 1e-9 else { return .zero }
        let magnitude = min(maxTurn, maxTurn * distance / max(referenceRadius, 1e-9))
        return Gaze(x: dx / distance * magnitude, y: dy / distance * magnitude)
    }
}

/// The reactive interrupts that outrank mood and micro-behavior. Higher priority
/// wins when several are present at once.
public enum Reaction: String, CaseIterable, Equatable, Sendable {
    case cursorNear
    case hover
    case click

    public var priority: Int {
        switch self {
        case .click: return 3
        case .hover: return 2
        case .cursorNear: return 1
        }
    }
}

/// A single reactive update: what Pip is reacting to and the values it drives.
public struct ReactionFrame: Equatable, Sendable {
    public let active: Reaction?
    public let isNear: Bool
    public let isHovering: Bool
    public let gaze: Gaze
    public let emerge: Double
    public let bounce: Double
    public let nearTriggerCount: Int
    public let clickCount: Int
    public let time: TimeInterval

    public init(
        active: Reaction?,
        isNear: Bool,
        isHovering: Bool,
        gaze: Gaze,
        emerge: Double,
        bounce: Double,
        nearTriggerCount: Int,
        clickCount: Int,
        time: TimeInterval
    ) {
        self.active = active
        self.isNear = isNear
        self.isHovering = isHovering
        self.gaze = gaze
        self.emerge = emerge
        self.bounce = bounce
        self.nearTriggerCount = nearTriggerCount
        self.clickCount = clickCount
        self.time = time
    }
}

/// Pure reactive state. Feed it cursor location and click edges with a figure
/// rect and the injected time; it returns the clamped gaze, the proximity
/// reaction, the hover-emerge offset, and the click bounce. No AppKit, no
/// wall-clock reads, so it is fully deterministic.
public struct ReactionState: Equatable, Sendable {
    public private(set) var isNear = false
    public private(set) var isHovering = false
    public private(set) var nearTriggerCount = 0
    public private(set) var clickCount = 0

    private var hoverReleaseTime: TimeInterval?
    private var clickTime: TimeInterval?

    public init() {}

    @discardableResult
    public mutating func update(
        cursor: Point?,
        click: Point?,
        figure: Rect,
        at time: TimeInterval
    ) -> ReactionFrame {
        let gaze: Gaze
        let near: Bool
        let hovering: Bool
        let hoverRegion = figure.expanded(by: ReactionTuning.hoverPadding)
        if let cursor {
            gaze = Gaze.toward(center: figure.center, target: cursor)
            near = figure.expanded(by: ReactionTuning.proximityPadding).contains(cursor)
            hovering = hoverRegion.contains(cursor)
        } else {
            gaze = .zero
            near = false
            hovering = false
        }

        if near && !isNear { nearTriggerCount += 1 }
        isNear = near

        let wasHovering = isHovering
        isHovering = hovering
        let emerge: Double
        if hovering {
            hoverReleaseTime = nil
            emerge = ReactionTuning.hoverEmerge
        } else if let release = hoverReleaseTime {
            let progress = min(1, max(0, (time - release) / ReactionTuning.emergeReleaseDuration))
            emerge = ReactionTuning.hoverEmerge * (1 - progress)
            if progress >= 1 { hoverReleaseTime = nil }
        } else if wasHovering {
            hoverReleaseTime = time
            emerge = ReactionTuning.hoverEmerge
        } else {
            emerge = 0
        }

        if let click, hoverRegion.contains(click) {
            clickTime = time
            clickCount += 1
        }

        let bounce: Double
        if let clickedAt = clickTime {
            let elapsed = time - clickedAt
            if elapsed >= 0, elapsed < ReactionTuning.bounceDuration {
                bounce = ReactionTuning.bounceAmplitude
                    * exp(-elapsed / ReactionTuning.bounceDecay)
                    * cos(2 * .pi * ReactionTuning.bounceFrequency * elapsed)
            } else {
                bounce = 0
                clickTime = nil
            }
        } else {
            bounce = 0
        }

        let active: Reaction?
        if let clickedAt = clickTime, time - clickedAt < ReactionTuning.bounceDuration {
            active = .click
        } else if hovering {
            active = .hover
        } else if near {
            active = .cursorNear
        } else {
            active = nil
        }

        return ReactionFrame(
            active: active,
            isNear: near,
            isHovering: hovering,
            gaze: gaze,
            emerge: emerge,
            bounce: bounce,
            nearTriggerCount: nearTriggerCount,
            clickCount: clickCount,
            time: time
        )
    }
}
