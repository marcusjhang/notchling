import Foundation

/// Pure placement/size math for the Pip figure.
///
/// Pip perches on the bottom edge of a presentation (the notch lip or the
/// floating pill) and hangs downward from it. One routine serves both the
/// notched and the non-notched presentations: horizontally centered, top edge
/// flush with the presentation's bottom edge, extending into the screen
/// (decreasing y in AppKit's bottom-left origin coordinates).
public enum PipPlacement {
    public static let figureHeight: Double = 34
    public static let figureAspectRatio: Double = 0.82

    public static var figureWidth: Double { figureHeight * figureAspectRatio }

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
}
