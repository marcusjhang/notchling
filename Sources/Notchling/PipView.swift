import SwiftUI
import NotchlingCore

/// Pip, drawn entirely from vector custom Shapes and anchored at `target`
/// (the figure rectangle in view coordinates). A single `TimelineView` ticks
/// the `PipModel`, which reads cursor/click input through the input protocol,
/// steps the `ReactionEngine`, and returns a pose; one shared spring smooths
/// the discrete behavior targets. `figure` is the same rect in screen
/// coordinates, which is the space the global cursor monitor reports in.
@MainActor
struct PipView: View {
    let target: CGRect
    let figure: Rect
    @State private var model: PipModel

    init(target: CGRect, figure: Rect) {
        self.target = target
        self.figure = figure
        _model = State(initialValue: PipModel(figure: figure))
    }

    var body: some View {
        GeometryReader { _ in
            TimelineView(.animation) { _ in
                let pose = model.tick()
                PipFigure(pose: pose)
                    .frame(width: target.width, height: target.height)
                    .rotationEffect(.degrees(Double(pose.gazeX) * 3), anchor: .top)
                    .offset(y: pose.emerge + pose.perk * 2)
                    .position(x: target.midX, y: target.midY)
                    .animation(PipModel.sharedSpring, value: pose.springKey)
            }
        }
    }
}

struct PipFigure: View {
    var pose = PipPose()

    var body: some View {
        GeometryReader { proxy in
            let layout = PipLayout(rect: CGRect(origin: .zero, size: proxy.size))
            let line = max(1.2, proxy.size.height * 0.035)
            let squash = pose.squash - pose.stretch * 0.5 + pose.bounce

            ZStack {
                part(PipBodyShape(squash: squash), frame: layout.body, line: line)
                part(PipBellyShape(), frame: layout.belly, fill: PipPalette.belly)

                ear(layout.leftEar, inner: layout.innerEar(from: layout.leftEar), rotation: -22 + earSwing, line: line)
                ear(layout.rightEar, inner: layout.innerEar(from: layout.rightEar), rotation: 22 - earSwing, line: line)

                part(PipArmShape(), frame: layout.leftArm, line: line)
                part(PipArmShape(), frame: layout.rightArm, line: line)

                part(PipHeadShape(), frame: layout.head, line: line)
                part(PipTuftShape(), frame: layout.tuft, line: line)

                eye(layout.leftEye)
                eye(layout.rightEye)
            }
            .rotationEffect(.degrees(pose.lean * 4), anchor: .bottom)
            .compositingGroup()
            .shadow(color: .black.opacity(0.22), radius: line, y: line)
        }
        .contentShape(PipSilhouetteShape(squash: pose.squash - pose.stretch * 0.5 + pose.bounce))
    }

    private var earSwing: Double {
        Double(pose.earTwitch) * 9 + Double(pose.droop) * 16 - Double(pose.perk) * 6
    }

    @ViewBuilder
    private func part(_ shape: some Shape, frame: CGRect, fill: Color = PipPalette.body, line: CGFloat? = nil) -> some View {
        if let line {
            shape
                .fill(fill)
                .overlay(shape.stroke(PipPalette.outline, lineWidth: line))
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
        } else {
            shape
                .fill(fill)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
        }
    }

    private func ear(_ frame: CGRect, inner: CGRect, rotation: Double, line: CGFloat) -> some View {
        ZStack {
            PipEarShape().fill(PipPalette.body)
            PipEarShape()
                .fill(PipPalette.innerEar)
                .frame(width: inner.width, height: inner.height)
                .position(x: inner.midX - frame.minX, y: inner.midY - frame.minY)
            PipEarShape().stroke(PipPalette.outline, lineWidth: line)
        }
        .frame(width: frame.width, height: frame.height)
        .rotationEffect(.degrees(rotation), anchor: .bottom)
        .position(x: frame.midX, y: frame.midY)
    }

    private func eye(_ frame: CGRect) -> some View {
        let closed = min(1, pose.blink + pose.droop * 0.45 + pose.yawn * 0.5)
        let height = frame.height * (1 - 0.92 * closed)
        let eyeRect = CGRect(
            x: frame.minX,
            y: frame.midY - height / 2,
            width: frame.width,
            height: max(0.5, height)
        )
        let light = PipLayout(rect: eyeRect).catchlight(in: eyeRect)
        let dx = (pose.look - 0.5) * 2 * frame.width * 0.18
            + pose.droop * frame.width * 0.06
            + pose.gazeX * frame.width * 0.30
        let dy = -pose.gazeY * frame.height * 0.26
        return ZStack(alignment: .topLeading) {
            PipEyeShape().fill(PipPalette.eye)
            PipCatchlightShape()
                .fill(PipPalette.catchlight)
                .frame(width: light.width, height: light.height)
                .offset(x: light.minX - eyeRect.minX, y: light.minY - eyeRect.minY)
        }
        .frame(width: eyeRect.width, height: eyeRect.height)
        .position(x: frame.midX + dx, y: frame.midY + dy)
    }
}
