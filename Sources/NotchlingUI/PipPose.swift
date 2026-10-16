import Foundation
import CoreGraphics
import NotchlingCore

/// A single frame's worth of animation values for Pip. The fields are the
/// independent dials the behavior engine drives; the view reads them and never
/// decides anything itself.
public struct PipPose: Equatable, Sendable {
    /// A neutral, non-animated pose used while mute or display sleep has paused
    /// drawing.
    public static let resting = PipPose()
    /// A still, fully-drooped pose drawn while Pip naps.
    public static let napping: PipPose = { var pose = PipPose(); pose.droop = 1; return pose }()

    public var squash: CGFloat = 0
    public var blink: CGFloat = 0
    public var look: CGFloat = 0
    public var earTwitch: CGFloat = 0
    public var lean: CGFloat = 0
    public var stretch: CGFloat = 0
    public var yawn: CGFloat = 0
    public var droop: CGFloat = 0
    public var gazeX: CGFloat = 0
    public var gazeY: CGFloat = 0
    public var emerge: CGFloat = 0
    public var bounce: CGFloat = 0
    public var perk: CGFloat = 0
    public var musicSway: CGFloat = 0
    public var warmGlow: CGFloat = 0
    public var snuggle: CGFloat = 0
    public var nightcap: CGFloat = 0
    public var perky: CGFloat = 0
    public var mood: Mood = .idle
    /// 0 = neutral smile, 1 = happy open mouth. Set from `PipExpression`.
    public var happy: CGFloat = 0
    /// Spring-driven squash/stretch recoil on a discrete pose change.
    public var recoil: CGFloat = 0

    public init() {}

    public var isHappy: Bool { happy >= 0.5 }

    public var springKey: SpringKey {
        SpringKey(
            droop: droop,
            blink: blink,
            look: look,
            earTwitch: earTwitch,
            lean: lean,
            stretch: stretch,
            snuggle: snuggle,
            happy: happy
        )
    }

    public struct SpringKey: Equatable, Sendable {
        public var droop: CGFloat
        public var blink: CGFloat
        public var look: CGFloat
        public var earTwitch: CGFloat
        public var lean: CGFloat
        public var stretch: CGFloat
        public var snuggle: CGFloat
        public var happy: CGFloat
    }
}

/// Named poses the headless preview renderer walks through so the owner can
/// judge cuteness across Pip's states.
public extension PipPose {
    static let idle = PipPose()
    static let blink: PipPose = { var p = PipPose(); p.blink = 1; return p }()
    static let happy: PipPose = { var p = PipPose(); p.happy = 1; return p }()
    static let doze: PipPose = { var p = PipPose(); p.droop = 0.55; return p }()
    static let nap: PipPose = { var p = PipPose(); p.droop = 1; return p }()
    static let charging: PipPose = { var p = PipPose(); p.warmGlow = 1; p.snuggle = 1; return p }()
    static let nightcap: PipPose = { var p = PipPose(); p.nightcap = 1; return p }()

    static let previewPoses: [(name: String, pose: PipPose)] = [
        ("idle", .idle),
        ("blink", .blink),
        ("happy", .happy),
        ("doze", .doze),
        ("nap", .nap),
        ("charging", .charging),
        ("nightcap", .nightcap),
    ]
}
