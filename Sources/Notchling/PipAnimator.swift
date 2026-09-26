import Foundation
import Observation
import NotchlingCore

/// Drives Pip's animation clock and decides when to run it at all. The timer is
/// event-gated: it is stopped entirely while muted or while the display is
/// asleep/locked, and slowed to a near-idle poll while Pip naps so activity can
/// still wake him. This is what keeps idle CPU near zero.
@MainActor
@Observable
final class PipAnimator {
    private(set) var pose = PipPose.resting

    @ObservationIgnored private let model: PipModel
    @ObservationIgnored private var settings: PipSettings
    @ObservationIgnored private var screenState: ScreenState
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var scheduledInterval: TimeInterval?

    init(
        settings: PipSettings,
        figure: Rect,
        screenState: ScreenState = .active,
        source: (any PipInputSource)?,
        systemSource: (any SystemStateSource)?
    ) {
        self.settings = settings
        self.screenState = screenState
        self.model = PipModel(
            figure: figure,
            personality: settings.personality,
            source: source,
            systemSource: systemSource
        )
        rescheduleIfNeeded()
    }

    func update(settings: PipSettings) {
        let wasMuted = self.settings.isMuted
        self.settings = settings
        if settings.isMuted {
            pose = .resting
        } else if wasMuted {
            model.wake()
        }
        rescheduleIfNeeded()
    }

    func setScreenState(_ state: ScreenState) {
        let wasPaused = screenState.pausesAnimation
        screenState = state
        if state.pausesAnimation {
            pose = .resting
        } else if wasPaused {
            model.wake()
        }
        rescheduleIfNeeded()
    }

    /// Stops the animation clock for good. Called when the panel is torn down so
    /// a replaced panel can never leave a timer running behind it.
    func stop() {
        timer?.invalidate()
        timer = nil
        scheduledInterval = nil
    }

    private var desiredInterval: TimeInterval? {
        AnimationPolicy.frameInterval(
            settings: settings,
            screenState: screenState,
            mood: model.mood,
            engaged: model.isEngaged
        )
    }

    private func rescheduleIfNeeded() {
        let desired = desiredInterval
        guard desired != scheduledInterval else { return }
        scheduledInterval = desired

        timer?.invalidate()
        timer = nil
        guard let desired else { return }

        let timer = Timer(timeInterval: desired, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard !settings.isMuted, screenState.isActive else { return }
        let updated = model.tick(personality: settings.personality)
        pose = AnimationPolicy.shouldAnimate(
            settings: settings,
            screenState: screenState,
            mood: model.mood
        ) ? updated : .napping
        rescheduleIfNeeded()
    }
}
