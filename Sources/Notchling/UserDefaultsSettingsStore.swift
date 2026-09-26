import Foundation
import NotchlingCore

/// Persists `Settings` in `UserDefaults`. Keys are namespaced so the app never
/// collides with another tool's defaults.
final class UserDefaultsSettingsStore: SettingsStore {
    private enum Key {
        static let personality = "com.notchling.pip.personality"
        static let muted = "com.notchling.pip.muted"
        static let launchAtLogin = "com.notchling.pip.launchAtLogin"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PipSettings {
        var settings = PipSettings.standard
        if let raw = defaults.string(forKey: Key.personality),
           let personality = Personality(rawValue: raw) {
            settings.personality = personality
        }
        settings.isMuted = defaults.bool(forKey: Key.muted)
        settings.launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        return settings
    }

    func save(_ settings: PipSettings) {
        defaults.set(settings.personality.rawValue, forKey: Key.personality)
        defaults.set(settings.isMuted, forKey: Key.muted)
        defaults.set(settings.launchAtLogin, forKey: Key.launchAtLogin)
    }
}
