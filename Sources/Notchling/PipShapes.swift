import SwiftUI

enum PipPalette {
    static let body = Color(red: 0.925, green: 0.906, blue: 0.871)
    static let outline = Color(red: 0.169, green: 0.165, blue: 0.157)
    static let belly = Color(red: 1.0, green: 0.973, blue: 0.933)
    static let eye = Color(red: 0.169, green: 0.165, blue: 0.157)
    static let catchlight = Color.white
    static let innerEar = Color(red: 0.949, green: 0.663, blue: 0.627)
    static let warmGlow = Color(red: 1.0, green: 0.78, blue: 0.42)
    static let nightcap = Color(red: 0.557, green: 0.608, blue: 0.682)
}

/// Normalized part rectangles for the Pip figure, derived from the figure's
/// bounding rect so every part scales with the figure and stays vector-only.
struct PipLayout {
    let rect: CGRect

    private func box(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX + (cx - w / 2) * rect.width,
            y: rect.minY + (cy - h / 2) * rect.height,
            width: w * rect.width,
            height: h * rect.height
        )
    }

    var body: CGRect { box(0.50, 0.64, 0.86, 0.68) }
    var head: CGRect { box(0.50, 0.32, 0.68, 0.50) }
    var belly: CGRect { box(0.50, 0.72, 0.46, 0.38) }
    var tuft: CGRect { box(0.50, 0.04, 0.28, 0.18) }
    var leftEar: CGRect { box(0.20, 0.11, 0.22, 0.28) }
    var rightEar: CGRect { box(0.80, 0.11, 0.22, 0.28) }
    var leftEye: CGRect { box(0.38, 0.31, 0.19, 0.22) }
    var rightEye: CGRect { box(0.62, 0.31, 0.19, 0.22) }
    var leftArm: CGRect { box(0.14, 0.24, 0.16, 0.46) }
    var rightArm: CGRect { box(0.86, 0.24, 0.16, 0.46) }

    func catchlight(in eye: CGRect) -> CGRect {
        let d = eye.width * 0.34
        return CGRect(
            x: eye.minX + eye.width * 0.16,
            y: eye.minY + eye.height * 0.16,
            width: d,
            height: d
        )
    }

    func innerEar(from ear: CGRect) -> CGRect {
        ear.insetBy(dx: ear.width * 0.28, dy: ear.height * 0.30)
            .offsetBy(dx: 0, dy: ear.height * 0.10)
    }
}

/// The round body. `squash` drives squash/stretch: positive values flatten and
/// widen, negative values stretch tall and narrow. It is `animatableData`, so
/// the body outline redraws as the value changes.
struct PipBodyShape: Shape {
    var squash: CGFloat = 0

    var animatableData: CGFloat {
        get { squash }
        set { squash = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let width = rect.width * (1 - squash * 0.5)
        let height = rect.height * (1 + squash * 0.9)
        let blob = CGRect(
            x: rect.midX - width / 2,
            y: rect.midY - height / 2,
            width: width,
            height: height
        )
        return Path(ellipseIn: blob)
    }
}

struct PipHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

struct PipBellyShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

struct PipEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

struct PipCatchlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

struct PipEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.20)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

struct PipTuftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

/// A droopy nightcap that sits on Pip's crown when it is late.
struct PipNightcapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.35)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

struct PipArmShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

/// The drawn silhouette as one filled path (union of every part). Used as the
/// view's `contentShape` so hit-testing follows the creature, not its bounding
/// rectangle.
struct PipSilhouetteShape: Shape {
    var squash: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let layout = PipLayout(rect: rect)
        var path = Path()
        path.addPath(PipBodyShape(squash: squash).path(in: layout.body))
        path.addPath(PipHeadShape().path(in: layout.head))
        path.addPath(PipEarShape().path(in: layout.leftEar))
        path.addPath(PipEarShape().path(in: layout.rightEar))
        path.addPath(PipTuftShape().path(in: layout.tuft))
        path.addPath(PipArmShape().path(in: layout.leftArm))
        path.addPath(PipArmShape().path(in: layout.rightArm))
        return path
    }
}
