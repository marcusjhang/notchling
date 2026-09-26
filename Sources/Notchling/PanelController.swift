import AppKit
import SwiftUI
import NotchlingCore

@MainActor
final class PanelController {
    private let panel: NSPanel

    init(screen: NSScreen) {
        let geometry = ScreenGeometry(screen: screen)
        let stage = Self.stageFrame(for: screen)

        panel = NotchlingPanel(
            contentRect: stage,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 8)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true
        panel.contentView = NSHostingView(
            rootView: PipPlaceholderView(target: Self.viewRect(for: geometry.presentation.rect, in: stage))
        )
    }

    func show() {
        panel.orderFrontRegardless()
    }

    private static func stageFrame(for screen: NSScreen) -> CGRect {
        let frame = screen.frame
        let height = frame.height / 2
        return CGRect(x: frame.minX, y: frame.maxY - height, width: frame.width, height: height)
    }

    private static func viewRect(for rect: Rect, in stage: CGRect) -> CGRect {
        CGRect(
            x: rect.minX - stage.minX,
            y: stage.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
