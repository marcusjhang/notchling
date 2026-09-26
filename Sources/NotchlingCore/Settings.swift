import Foundation

/// The user-facing preferences persisted between launches. The defaults match
/// the product spec: `companion`, unmuted, launch-at-login off. Keeping this a
/// plain value type lets the menu, the animator, and the tests share one
/// definition of "what the current settings are".
public struct PipSettings: Equatable, Sendable {
    public var personality: Personality
    public var isMuted: Bool
    public var launchAtLogin: Bool

    public static let standard = PipSettings()

    public init(
        personality: Personality = .companion,
        isMuted: Bool = false,
        launchAtLogin: Bool = false
    ) {
        self.personality = personality
        self.isMuted = isMuted
        self.launchAtLogin = launchAtLogin
    }
}

/// Where settings live. The app persists them in `UserDefaults`; tests use an
/// in-memory implementation so the menu logic can be exercised without touching
/// the real domain.
public protocol SettingsStore: AnyObject {
    func load() -> PipSettings
    func save(_ settings: PipSettings)
}

/// A `SettingsStore` that keeps values in memory. Handy for tests and previews.
public final class InMemorySettingsStore: SettingsStore {
    public private(set) var settings: PipSettings

    public init(settings: PipSettings = .standard) {
        self.settings = settings
    }

    public func load() -> PipSettings { settings }

    public func save(_ settings: PipSettings) { self.settings = settings }
}
