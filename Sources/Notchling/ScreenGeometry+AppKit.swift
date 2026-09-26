import AppKit
import NotchlingCore

@MainActor
extension ScreenGeometry {
    init(screen: NSScreen) {
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        self.init(
            displayID: displayID,
            frame: Rect(screen.frame),
            visibleFrame: Rect(screen.visibleFrame),
            safeAreaTop: Double(screen.safeAreaInsets.top),
            auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea.map { Rect($0) },
            auxiliaryTopRightArea: screen.auxiliaryTopRightArea.map { Rect($0) }
        )
    }
}

extension Rect {
    init(_ rect: CGRect) {
        self.init(
            x: Double(rect.origin.x),
            y: Double(rect.origin.y),
            width: Double(rect.size.width),
            height: Double(rect.size.height)
        )
    }
}
