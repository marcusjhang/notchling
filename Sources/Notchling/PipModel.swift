import SwiftUI
import NotchlingCore

/// Drives the creature from the reactive behavior engine. One shared spring
/// smooths the discrete behavior targets; breathing is a continuous baseline
/// that runs in every mood. Cursor tracking flows through the injected input
/// source, so the decision logic stays entirely in `NotchlingCore`.
@MainActor
final class PipModel {
    static let sharedSpring = Animation.spring(response: 0.45, dampingFraction: 0.72)
    static let breathingPeriod: Double = 2.5
    static let behaviorDuration: TimeInterval = 0.7

    private var engine: ReactionEngine
    private var active: (behavior: Behavior, time: TimeInterval)?
    private var lastGaze: Gaze = .zero

    /// True while something is worth animating at the fast cadence: a live
    /// reaction, a micro-behavior mid-flight, cursor movement, or hover-emerge.
    private(set) var isEngaged = false

    init(
        figure: Rect,
        personality: Personality,
        source: (any PipInputSource)?,
        systemSource: (any SystemStateSource)?
    ) {
        engine = ReactionEngine(
            seed: 0x4E4F_5443,
            personality: personality,
            figure: figure,
            source: source,
            systemSource: systemSource,
            clock: SystemClock()
        )
    }

    /// True once the ambient arc has fully reached sleep. Drives animation
    /// gating in the app layer.
    var isAsleep: Bool { engine.mood.isAsleep }

    var mood: Mood { engine.mood }

    /// Wake Pip out of doze or nap. Called when the app resumes after muting or
    /// display sleep so animation starts from a lively state.
    func wake() {
        _ = engine.wake()
    }

    func tick(personality: Personality) -> PipPose {
        if engine.behavior.personality != personality {
            engine.behavior.personality = personality
        }
        let emission = engine.step()
        let time = emission.time

        var pose = PipPose()
        pose.mood = emission.mood
        let breathingPeriod = Self.breathingPeriod * (emission.isCharging ? 1.8 : 1)
        pose.squash = CGFloat(sin(time * 2 * .pi / breathingPeriod)) * 0.06

        switch emission.mood {
        case .idle, .wake: pose.droop = 0
        case .doze: pose.droop = 0.55
        case .nap: pose.droop = 1
        }

        pose.gazeX = CGFloat(emission.gaze.x)
        pose.gazeY = CGFloat(emission.gaze.y)
        pose.emerge = CGFloat(emission.emerge)
        pose.bounce = CGFloat(emission.bounce)
        pose.perk = emission.isNear ? 1 : 0

        pose.musicSway = emission.isMusicPlaying ? CGFloat(sin(time * 2 * .pi / 1.8)) * 0.5 : 0
        pose.warmGlow = emission.isCharging ? 1 : 0
        pose.snuggle = emission.isCharging ? 1 : 0
        pose.nightcap = emission.isNightcap ? 1 : 0
        pose.perky = emission.isMorning ? 1 : 0

        if !emission.mood.isAsleep, let micro = emission.microEvents.last {
            active = (micro.behavior, micro.time)
        }
        var microActive = false
        if let active, time - active.time < Self.behaviorDuration {
            microActive = true
            let progress = max(0, min(1, (time - active.time) / Self.behaviorDuration))
            apply(active.behavior, CGFloat(sin(progress * .pi)), to: &pose)
        }

        let pointerMoved = emission.gaze != lastGaze
        lastGaze = emission.gaze
        isEngaged = !emission.mood.isAsleep
            && (emission.isReactive || microActive || pointerMoved || emission.emerge > 0)

        return pose
    }

    private func apply(_ behavior: Behavior, _ envelope: CGFloat, to pose: inout PipPose) {
        switch behavior {
        case .breathe: break
        case .blink: pose.blink = envelope
        case .lookAround: pose.look = envelope
        case .earTwitch: pose.earTwitch = envelope
        case .weightShift: pose.lean = envelope
        case .stretch: pose.stretch = envelope
        case .yawn: pose.yawn = envelope
        }
    }
}

/// A single frame's worth of animation values for Pip.
struct PipPose: Equatable {
    /// A neutral, non-animated pose used while mute or display sleep has paused
    /// drawing.
    static let resting = PipPose()
    /// A still, fully-drooped pose drawn while Pip naps. The engine keeps
    /// polling at a slow cadence, but nothing visibly moves.
    static let napping = PipPose(droop: 1)

    var squash: CGFloat = 0
    var blink: CGFloat = 0
    var look: CGFloat = 0
    var earTwitch: CGFloat = 0
    var lean: CGFloat = 0
    var stretch: CGFloat = 0
    var yawn: CGFloat = 0
    var droop: CGFloat = 0
    var gazeX: CGFloat = 0
    var gazeY: CGFloat = 0
    var emerge: CGFloat = 0
    var bounce: CGFloat = 0
    var perk: CGFloat = 0
    var musicSway: CGFloat = 0
    var warmGlow: CGFloat = 0
    var snuggle: CGFloat = 0
    var nightcap: CGFloat = 0
    var perky: CGFloat = 0
    var mood: Mood = .idle

    var springKey: SpringKey {
        SpringKey(
            droop: droop,
            blink: blink,
            look: look,
            earTwitch: earTwitch,
            lean: lean,
            stretch: stretch,
            snuggle: snuggle
        )
    }

    struct SpringKey: Equatable {
        var droop: CGFloat
        var blink: CGFloat
        var look: CGFloat
        var earTwitch: CGFloat
        var lean: CGFloat
        var stretch: CGFloat
        var snuggle: CGFloat
    }
}
