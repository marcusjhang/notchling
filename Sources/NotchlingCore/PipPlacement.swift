import Foundation

/// Pure placement/size math for the Pip figure.
///
/// Pip perches on the bottom edge of a presentation (the notch lip or the
/// floating pill) and hangs downward from it. One routine serves both the
/// notched and the non-notched presentations: horizontally centered, top edge
/// flush with the presentation's bottom edge, extending into the screen
/// (decreasing y in AppKit's bottom-left origin coordinates).
public enum PipPlacement {
    /// The single source of truth for Pip's size. Both presentations read these,
    /// so the notch and floating-pill figures shrink together.
    public static let figureHeight: Double = 22
    public static let figureAspectRatio: Double = 0.85
    /// Small, fixed padding around the figure's maximum animation envelope.
    public static let panelMargin: Double = 8
    /// How far the largest pose can swing beyond the figure's own bounds.
    public static let maxAnimationAmplitude: Double = 12

    public static var figureWidth: Double { figureHeight * figureAspectRatio }

    public static var panelPadding: Double { panelMargin + maxAnimationAmplitude }

    /// The fixed panel envelope for the maximum animation amplitude.
    public static var panelSize: Size {
        Size(
            width: figureWidth + panelPadding * 2,
            height: figureHeight + panelPadding * 2
        )
    }

    public static func figureRect(for presentation: Presentation) -> Rect {
        let anchor = presentation.rect
        let width = figureWidth
        let height = figureHeight
        return Rect(
            x: anchor.midX - width / 2,
            y: anchor.minY - height,
            width: width,
            height: height
        )
    }

    public static func figureRect(for geometry: ScreenGeometry) -> Rect {
        figureRect(for: geometry.presentation)
    }

    /// The fixed transparent panel, anchored at the presentation lip, big enough
    /// to hold the figure through its maximum animation amplitude plus margin.
    public static func panelEnvelope(for presentation: Presentation) -> Rect {
        figureRect(for: presentation).expanded(by: panelPadding)
    }

    public static func panelEnvelope(for geometry: ScreenGeometry) -> Rect {
        panelEnvelope(for: geometry.presentation)
    }
}
