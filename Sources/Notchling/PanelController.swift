import AppKit
import SwiftUI
import NotchlingCore

/// Owns one Pip panel for one screen. The window frame never changes; only the
/// animator's pose animates inside it. `close()` tears the panel down so a
/// rebuild after a display change can never leave a stale panel behind.
@MainActor
final class PanelController {
    private let panel: NSPanel
    private let animator: PipAnimator

    init(
        screen: NSScreen,
        settings: PipSettings,
        screenState: ScreenState,
        source: (any PipInputSource)?,
        systemSource: (any SystemStateSource)?
    ) {
        let geometry = ScreenGeometry(screen: screen)
        let stage = Self.stageFrame(for: screen)
        let figure = PipPlacement.figureRect(for: geometry)

        animator = PipAnimator(
            settings: settings,
            figure: figure,
            screenState: screenState,
            source: source,
            systemSource: systemSource
        )

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
            rootView: PipView(target: Self.viewRect(for: figure, in: stage), animator: animator)
        )
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func update(settings: PipSettings) {
        animator.update(settings: settings)
    }

    func setScreenState(_ state: ScreenState) {
        animator.setScreenState(state)
    }

    func close() {
        animator.stop()
        panel.orderOut(nil)
        panel.contentView = nil
        panel.close()
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
