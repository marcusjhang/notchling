import AppKit
import NotchlingCore

/// Keeps exactly one `PanelController` alive. Every rebuild closes the previous
/// panel before creating the replacement, so display attach/detach/rearrange
/// always converges on a single Pip panel on the newly preferred display.
@MainActor
final class PanelHost {
    private var controller: PanelController?
    private var settings: PipSettings
    private var screenState: ScreenState
    private let source: (any PipInputSource)?
    private let systemSource: (any SystemStateSource)?

    init(
        settings: PipSettings,
        screenState: ScreenState,
        source: (any PipInputSource)?,
        systemSource: (any SystemStateSource)?
    ) {
        self.settings = settings
        self.screenState = screenState
        self.source = source
        self.systemSource = systemSource
    }

    var panelCount: Int { controller == nil ? 0 : 1 }

    func rebuild() {
        controller?.close()
        controller = nil
        guard let screen = Self.preferredScreen() else { return }
        let controller = PanelController(
            screen: screen,
            settings: settings,
            screenState: screenState,
            source: source,
            systemSource: systemSource
        )
        self.controller = controller
        controller.show()
    }

    func update(settings: PipSettings) {
        self.settings = settings
        controller?.update(settings: settings)
    }

    func setScreenState(_ state: ScreenState) {
        screenState = state
        controller?.setScreenState(state)
    }

    func teardown() {
        controller?.close()
        controller = nil
    }

    static func preferredScreen() -> NSScreen? {
        let screens = NSScreen.screens
        let geometries = screens.map { ScreenGeometry(screen: $0) }
        guard let selected = DisplaySelection.preferred(from: geometries),
              let index = geometries.firstIndex(of: selected) else {
            return screens.first
        }
        return screens[index]
    }
}
