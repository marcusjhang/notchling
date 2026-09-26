import ServiceManagement

/// Thin wrapper over `SMAppService.mainApp` — the public, permission-free way to
/// register the app as a login item on macOS 13+. Reading `status` lets the menu
/// reflect the system's real state rather than a stored guess.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
