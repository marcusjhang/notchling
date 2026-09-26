import SwiftUI

/// Pip, drawn entirely from vector custom Shapes and anchored at `target`
/// (the figure rectangle computed by `NotchlingCore`). Static in M1; `squash`
/// feeds the body's squash/stretch `animatableData`.
struct PipView: View {
    let target: CGRect
    var squash: CGFloat = 0

    var body: some View {
        GeometryReader { _ in
            PipFigure(squash: squash)
                .frame(width: target.width, height: target.height)
                .position(x: target.midX, y: target.midY)
        }
    }
}

struct PipFigure: View {
    var squash: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let layout = PipLayout(rect: CGRect(origin: .zero, size: proxy.size))
            let line = max(1.2, proxy.size.height * 0.035)

            ZStack {
                part(PipBodyShape(squash: squash), frame: layout.body, line: line)
                part(PipBellyShape(), frame: layout.belly, fill: PipPalette.belly)

                ear(layout.leftEar, inner: layout.innerEar(from: layout.leftEar), rotation: -22, line: line)
                ear(layout.rightEar, inner: layout.innerEar(from: layout.rightEar), rotation: 22, line: line)

                part(PipArmShape(), frame: layout.leftArm, line: line)
                part(PipArmShape(), frame: layout.rightArm, line: line)

                part(PipHeadShape(), frame: layout.head, line: line)
                part(PipTuftShape(), frame: layout.tuft, line: line)

                eye(layout.leftEye)
                eye(layout.rightEye)
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.22), radius: line, y: line)
        }
        .contentShape(PipSilhouetteShape(squash: squash))
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
        let light = PipLayout(rect: frame).catchlight(in: frame)
        return ZStack(alignment: .topLeading) {
            PipEyeShape().fill(PipPalette.eye)
            PipCatchlightShape()
                .fill(PipPalette.catchlight)
                .frame(width: light.width, height: light.height)
                .offset(x: light.minX - frame.minX, y: light.minY - frame.minY)
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }
}
