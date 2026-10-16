import SwiftUI
import NotchlingCore
import NotchlingUI

/// Pip, anchored at `target` (the figure rectangle in view coordinates).
/// `PipAnimator` owns the engine clock and pauses it while muted, napping, or
/// the display is asleep; one shared spring smooths the discrete behavior
/// targets. All drawing and placement live in `NotchlingUI`/`NotchlingCore`.
@MainActor
struct PipView: View {
    let target: CGRect
    let animator: PipAnimator

    var body: some View {
        let pose = animator.pose
        PipFigure(pose: pose)
            .frame(width: target.width, height: target.height)
            .rotationEffect(
                .degrees(Double(pose.gazeX) * 3 + Double(pose.musicSway) * 4),
                anchor: .top
            )
            .offset(y: pose.emerge + pose.perk * 2 - pose.perky * 1.5 + pose.snuggle * 3)
            .scaleEffect(1 - pose.snuggle * 0.05, anchor: .bottom)
            .position(x: target.midX, y: target.midY)
            .animation(PipModel.sharedSpring, value: pose.springKey)
    }
}
