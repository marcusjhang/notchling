import SwiftUI
import NotchlingCore

/// Exact palette colours as SwiftUI `Color`s. The bytes come from
/// `NotchlingCore.PipPalette`, so the previews and the app can never diverge.
enum PipColors {
    static let body = Color(PipPalette.body)
    static let belly = Color(PipPalette.belly)
    static let blush = Color(PipPalette.blush)
    static let innerEar = Color(PipPalette.innerEar)
    static let ink = Color(PipPalette.ink)
    static let nightcap = Color(PipPalette.nightcap)
    static let glow = Color(PipPalette.glow)
    static let catchlight = Color.white
}

extension Color {
    init(_ rgb: RGB) {
        self.init(
            .sRGB,
            red: Double(rgb.red) / 255,
            green: Double(rgb.green) / 255,
            blue: Double(rgb.blue) / 255,
            opacity: 1
        )
    }
}

extension Rect {
    var cg: CGRect {
        CGRect(x: minX, y: minY, width: width, height: height)
    }
}

extension CGRect {
    var coreRect: Rect {
        Rect(x: Double(minX), y: Double(minY), width: Double(width), height: Double(height))
    }
}

/// The round body. `squash` drives squash/stretch: positive values flatten and
/// widen, negative values stretch tall and narrow.
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
    func path(in rect: CGRect) -> Path { Path(ellipseIn: rect) }
}

struct PipBellyShape: Shape {
    func path(in rect: CGRect) -> Path { Path(ellipseIn: rect) }
}

struct PipEyeShape: Shape {
    func path(in rect: CGRect) -> Path { Path(ellipseIn: rect) }
}

struct PipCatchlightShape: Shape {
    func path(in rect: CGRect) -> Path { Path(ellipseIn: rect) }
}

struct PipBlushShape: Shape {
    func path(in rect: CGRect) -> Path { Path(ellipseIn: rect) }
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

/// The tiny `‿` smile. Stroked, not filled, so it reads as a line on the face.
struct PipSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 1.6)
        )
        return path
    }
}

/// The happy open mouth: a soft rounded blob filled in ink.
struct PipMouthOpenShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

/// A closed eye, drawn as a small downward arc (a contented `‿` of an eye).
struct PipClosedEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

/// The filled silhouette (union of every outer part), used both as the view's
/// hit `contentShape` and as the single stroked outline. Boolean-unioning the
/// parts means the stroke follows only the outer contour - interior junctions
/// between head, body, arms and ears are not separately outlined.
struct PipSilhouetteShape: Shape {
    var squash: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let layout = PipFigureLayout(rect: rect.coreRect)
        let parts: [CGPath] = [
            PipBodyShape(squash: squash).path(in: layout.body.cg).cgPath,
            PipHeadShape().path(in: layout.head.cg).cgPath,
            PipEarShape().path(in: layout.leftEar.cg).cgPath,
            PipEarShape().path(in: layout.rightEar.cg).cgPath,
            PipTuftShape().path(in: layout.tuft.cg).cgPath,
            PipArmShape().path(in: layout.leftArm.cg).cgPath,
            PipArmShape().path(in: layout.rightArm.cg).cgPath,
        ]
        guard var combined = parts.first else { return Path() }
        for part in parts.dropFirst() {
            combined = combined.union(part)
        }
        return Path(combined)
    }
}
