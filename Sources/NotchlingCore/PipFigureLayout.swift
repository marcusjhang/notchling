import Foundation

/// The single source of truth for Pip's proportions. Every part rectangle is a
/// normalized fraction of the figure's bounding rect, so the same math sizes the
/// on-screen creature and the headless previews. Coordinates use a top-left
/// origin (y grows downward), matching SwiftUI's rendering space.
///
/// The cute/baby-schema rules live here, not in the view: a head that is about
/// 1.35x taller than the body, large low-set eyes placed close together, and
/// fixed cheek/mouth landmarks. Keeping it here means the cuteness is unit-tested
/// rather than eyeballed.
public struct PipFigureLayout: Equatable, Sendable {
    public let rect: Rect

    public init(rect: Rect) {
        self.rect = rect
    }

    /// Head height divided by body height. The spec's baby-schema target.
    public static let headToBodyHeightRatio: Double = 1.35
    /// Body height as a fraction of the figure height.
    public static let bodyHeightFraction: Double = 0.40
    /// Head height implied by the ratio, so the two can never drift apart.
    public static let headHeightFraction: Double = bodyHeightFraction * headToBodyHeightRatio

    private func box(_ cx: Double, _ cy: Double, _ w: Double, _ h: Double) -> Rect {
        Rect(
            x: rect.minX + (cx - w / 2) * rect.width,
            y: rect.minY + (cy - h / 2) * rect.height,
            width: w * rect.width,
            height: h * rect.height
        )
    }

    public var body: Rect { box(0.50, 0.68, 0.74, Self.bodyHeightFraction) }
    public var head: Rect { box(0.50, 0.30, 0.76, Self.headHeightFraction) }
    public var belly: Rect { box(0.50, 0.74, 0.42, 0.24) }
    public var tuft: Rect { box(0.50, 0.06, 0.30, 0.12) }
    public var leftEar: Rect { box(0.155, 0.11, 0.20, 0.20) }
    public var rightEar: Rect { box(0.845, 0.11, 0.20, 0.20) }
    public var leftArm: Rect { box(0.155, 0.66, 0.14, 0.22) }
    public var rightArm: Rect { box(0.845, 0.66, 0.14, 0.22) }

    /// Eyes sit slightly below the head's vertical midline and a little closer
    /// together than the old wide-set placement, while each eye is larger.
    public var leftEye: Rect { eye(centerX: 0.39) }
    public var rightEye: Rect { eye(centerX: 0.61) }

    /// Cheeks sit low and to the outside, just under the outer eye corners.
    public var leftBlush: Rect { box(0.205, 0.42, 0.16, 0.105) }
    public var rightBlush: Rect { box(0.795, 0.42, 0.16, 0.105) }

    /// The mouth landmark, below both eyes and above the head's bottom edge.
    public var mouth: Rect { box(0.50, 0.475, 0.18, 0.085) }

    private func eye(centerX: Double) -> Rect {
        let centerY = 0.30 + Self.headHeightFraction * 0.08
        return box(centerX, centerY, 0.21, 0.28)
    }

    /// Two catchlights per eye: one noticeably larger than the other.
    public struct Catchlights: Equatable, Sendable {
        public let big: Rect
        public let small: Rect
    }

    public func catchlights(in eye: Rect) -> Catchlights {
        let big = eye.width * 0.44
        let small = eye.width * 0.22
        return Catchlights(
            big: Rect(
                x: eye.minX + eye.width * 0.16,
                y: eye.minY + eye.height * 0.14,
                width: big,
                height: big
            ),
            small: Rect(
                x: eye.minX + eye.width * 0.62,
                y: eye.minY + eye.height * 0.60,
                width: small,
                height: small
            )
        )
    }

    public func innerEar(from ear: Rect) -> Rect {
        Rect(
            x: ear.minX + ear.width * 0.30,
            y: ear.minY + ear.height * 0.40,
            width: ear.width * 0.40,
            height: ear.height * 0.44
        )
    }
}
