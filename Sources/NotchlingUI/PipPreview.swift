import SwiftUI
import ImageIO
import NotchlingCore

/// Headless PNG rendering for the cuteness previews. Uses SwiftUI's offscreen
/// `ImageRenderer` so the previews are painted by the exact same `PipFigure` the
/// app draws - no second drawing implementation to drift. No window is created.
@MainActor
public enum PipPreview {
    public static let canvasSize: CGFloat = 260
    private static let figureInset: CGFloat = 0.80

    public static func pngData(for pose: PipPose, scale: CGFloat = 2) -> Data? {
        let figure = canvasSize * figureInset
        let content = PipFigure(pose: pose)
            .frame(width: figure, height: figure)
            .frame(width: canvasSize, height: canvasSize)
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.isOpaque = false
        guard let cgImage = renderer.cgImage else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
