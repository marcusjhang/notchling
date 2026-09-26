import AppKit

@main
@MainActor
final class NotchlingApp: NSObject, NSApplicationDelegate {
    private var controller: AppController?

    static func main() {
        let app = NSApplication.shared
        let delegate = NotchlingApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = AppController()
        self.controller = controller
        controller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }
}
