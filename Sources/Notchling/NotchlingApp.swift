import AppKit
import NotchlingCore

@main
@MainActor
struct NotchlingApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let screens = NSScreen.screens
        let geometries = screens.map { ScreenGeometry(screen: $0) }
        guard let selected = DisplaySelection.preferred(from: geometries) else {
            return
        }
        let screen = screens[geometries.firstIndex(of: selected) ?? 0]

        let controller = PanelController(screen: screen)
        controller.show()
        app.run()
    }
}
