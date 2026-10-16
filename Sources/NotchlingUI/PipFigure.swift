import SwiftUI
import NotchlingCore

/// Pip, drawn entirely from vector `Shape`s. All placement comes from
/// `PipFigureLayout` in `NotchlingCore`; this view only paints. The outline is a
/// single thin stroke of the unioned silhouette, so interior boundaries between
/// head, belly and eyes are never separately outlined.
public struct PipFigure: View {
    public var pose: PipPose

    public init(pose: PipPose = PipPose()) {
        self.pose = pose
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = PipFigureLayout(rect: Rect(x: 0, y: 0, width: Double(size.width), height: Double(size.height)))
            let line = max(0.9, size.height * 0.02)
            let squash = pose.squash - pose.stretch * 0.5 + pose.bounce + pose.recoil

            ZStack {
                if pose.warmGlow > 0 {
                    PipHeadShape()
                        .fill(PipColors.glow)
                        .frame(width: layout.body.width * 1.5, height: layout.body.height * 1.5)
                        .position(x: layout.body.midX, y: layout.body.midY)
                }

                PipBodyShape(squash: squash).fill(PipColors.body)
                    .frame(width: layout.body.width, height: layout.body.height)
                    .position(x: layout.body.midX, y: layout.body.midY)

                PipBellyShape().fill(PipColors.belly)
                    .frame(width: layout.belly.width, height: layout.belly.height)
                    .position(x: layout.belly.midX, y: layout.belly.midY)

                ear(layout.leftEar, inner: layout.innerEar(from: layout.leftEar), rotation: -20 + earSwing)
                ear(layout.rightEar, inner: layout.innerEar(from: layout.rightEar), rotation: 20 - earSwing)

                PipArmShape().fill(PipColors.body)
                    .frame(width: layout.leftArm.width, height: layout.leftArm.height)
                    .position(x: layout.leftArm.midX, y: layout.leftArm.midY)
                PipArmShape().fill(PipColors.body)
                    .frame(width: layout.rightArm.width, height: layout.rightArm.height)
                    .position(x: layout.rightArm.midX, y: layout.rightArm.midY)

                PipHeadShape().fill(PipColors.body)
                    .frame(width: layout.head.width, height: layout.head.height)
                    .position(x: layout.head.midX, y: layout.head.midY)

                PipTuftShape().fill(PipColors.body)
                    .frame(width: layout.tuft.width, height: layout.tuft.height)
                    .position(x: layout.tuft.midX, y: layout.tuft.midY)

                PipSilhouetteShape(squash: squash)
                    .stroke(PipColors.ink, lineWidth: line)

                blush(layout.leftBlush)
                blush(layout.rightBlush)

                eye(layout.leftEye)
                eye(layout.rightEye)

                mouth(layout.mouth, line: line)

                if pose.nightcap > 0 {
                    PipNightcapShape()
                        .fill(PipColors.nightcap)
                        .frame(width: layout.head.width * 0.98, height: layout.head.height * 0.7)
                        .position(
                            x: layout.head.midX,
                            y: layout.head.minY + layout.head.height * 0.10
                        )
                }
            }
            .rotationEffect(.degrees(Double(pose.lean) * 4), anchor: .bottom)
            .scaleEffect(1 - pose.snuggle * 0.05, anchor: .bottom)
            .compositingGroup()
            .shadow(color: .black.opacity(0.18), radius: line * 0.8, y: line * 0.6)
        }
        .contentShape(PipSilhouetteShape(squash: pose.squash - pose.stretch * 0.5 + pose.bounce + pose.recoil))
    }

    private var earSwing: Double {
        Double(pose.earTwitch) * 9 + Double(pose.droop) * 16 - Double(pose.perk) * 6
    }

    private func ear(_ frame: Rect, inner: Rect, rotation: Double) -> some View {
        let frame = frame.cg
        let inner = inner.cg
        return ZStack {
            PipEarShape().fill(PipColors.body)
            PipEarShape()
                .fill(PipColors.innerEar)
                .frame(width: inner.width, height: inner.height)
                .position(x: inner.midX - frame.minX, y: inner.midY - frame.minY)
        }
        .frame(width: frame.width, height: frame.height)
        .rotationEffect(.degrees(rotation), anchor: .bottom)
        .position(x: frame.midX, y: frame.midY)
    }

    private func blush(_ frame: Rect) -> some View {
        let frame = frame.cg
        return PipBlushShape()
            .fill(PipColors.blush)
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }

    @ViewBuilder
    private func eye(_ frame: Rect) -> some View {
        let frame = frame.cg
        let closed = min(1, pose.blink + pose.droop * 0.85)
        let dx = (pose.look - 0.5) * 2 * frame.width * 0.18
            + pose.droop * frame.width * 0.05
            + pose.gazeX * frame.width * 0.28
        let dy = -pose.gazeY * frame.height * 0.24

        if closed > 0.7 {
            PipClosedEyeShape()
                .stroke(PipColors.ink, style: StrokeStyle(lineWidth: max(1, frame.width * 0.14), lineCap: .round))
                .frame(width: frame.width, height: frame.height * 0.4)
                .position(x: frame.midX + dx, y: frame.midY + dy)
        } else {
            let height = frame.height * (1 - 0.9 * closed)
            let eyeRect = CGRect(
                x: frame.minX,
                y: frame.midY - height / 2,
                width: frame.width,
                height: max(0.5, height)
            )
            let catchlights = PipFigureLayout(rect: eyeRect.coreRect).catchlights(in: eyeRect.coreRect)
            ZStack {
                PipEyeShape().fill(PipColors.ink)
                    .frame(width: eyeRect.width, height: eyeRect.height)
                PipCatchlightShape()
                    .fill(PipColors.catchlight)
                    .frame(width: catchlights.big.width, height: catchlights.big.height)
                    .offset(
                        x: catchlights.big.midX - eyeRect.midX,
                        y: catchlights.big.midY - eyeRect.midY
                    )
                    .opacity(1 - closed)
                PipCatchlightShape()
                    .fill(PipColors.catchlight)
                    .frame(width: catchlights.small.width, height: catchlights.small.height)
                    .offset(
                        x: catchlights.small.midX - eyeRect.midX,
                        y: catchlights.small.midY - eyeRect.midY
                    )
                    .opacity(1 - closed)
            }
            .frame(width: eyeRect.width, height: eyeRect.height)
            .position(x: frame.midX + dx, y: frame.midY + dy)
        }
    }

    @ViewBuilder
    private func mouth(_ frame: Rect, line: CGFloat) -> some View {
        let frame = frame.cg
        if pose.happy > 0.5 {
            PipMouthOpenShape()
                .fill(PipColors.ink)
                .frame(width: frame.width * 1.15, height: frame.height * 1.5)
                .position(x: frame.midX, y: frame.midY + frame.height * 0.15)
        } else {
            PipSmileShape()
                .stroke(PipColors.ink, style: StrokeStyle(lineWidth: line * 1.1, lineCap: .round))
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
        }
    }
}
