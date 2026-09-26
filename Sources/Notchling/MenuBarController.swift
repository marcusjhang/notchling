import AppKit
import NotchlingCore

/// The menu-bar presence: a creature-derived template icon and a menu with the
/// three personalities (exactly one checked), Mute, Launch at Login, and Quit.
/// It only reports actions; `AppController` owns state and persistence.
@MainActor
final class MenuBarController: NSObject {
    enum Action {
        case setPersonality(Personality)
        case setMuted(Bool)
        case setLaunchAtLogin(Bool)
        case quit
    }

    private let statusItem: NSStatusItem
    private let onAction: (Action) -> Void
    private var settings: PipSettings
    private var personalityItems: [NSMenuItem] = []
    private let muteItem: NSMenuItem
    private let launchItem: NSMenuItem

    init(settings: PipSettings, onAction: @escaping (Action) -> Void) {
        self.settings = settings
        self.onAction = onAction
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        muteItem = NSMenuItem(title: "Mute", action: nil, keyEquivalent: "")
        launchItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
        super.init()

        statusItem.button?.image = PipIcon.menuBar()
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "Notchling"
        buildMenu()
        update(settings: settings)
    }

    func update(settings: PipSettings) {
        self.settings = settings
        for item in personalityItems {
            let raw = item.representedObject as? String
            item.state = raw == settings.personality.rawValue ? .on : .off
        }
        muteItem.state = settings.isMuted ? .on : .off
        launchItem.state = LoginItem.isEnabled ? .on : .off
    }

    func remove() {
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func buildMenu() {
        let menu = NSMenu()

        for personality in Personality.allCases {
            let item = NSMenuItem(
                title: Self.title(for: personality),
                action: #selector(selectPersonality(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = personality.rawValue
            personalityItems.append(item)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        muteItem.target = self
        muteItem.action = #selector(toggleMute(_:))
        menu.addItem(muteItem)

        launchItem.target = self
        launchItem.action = #selector(toggleLaunchAtLogin(_:))
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private static func title(for personality: Personality) -> String {
        switch personality {
        case .quiet: return "Quiet"
        case .companion: return "Companion"
        case .playful: return "Playful"
        }
    }

    @objc private func selectPersonality(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let personality = Personality(rawValue: raw) else { return }
        onAction(.setPersonality(personality))
    }

    @objc private func toggleMute(_ sender: NSMenuItem) {
        onAction(.setMuted(!settings.isMuted))
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        onAction(.setLaunchAtLogin(!LoginItem.isEnabled))
    }

    @objc private func quit(_ sender: NSMenuItem) {
        onAction(.quit)
    }
}
