import AppKit
import NotchlingCore

/// Ties the whole app together: persisted settings, the one panel, the menu-bar
/// item, and the display/sleep/lock observers. All state changes flow through
/// here so the menu and the on-screen Pip never disagree.
@MainActor
final class AppController {
    private let store: SettingsStore
    private var settings: PipSettings
    private var screenState: ScreenState = .active

    private let input = CursorTracker()
    private let system = SystemStateMonitor()

    private var panelHost: PanelHost?
    private var menuBar: MenuBarController?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(store: SettingsStore = UserDefaultsSettingsStore()) {
        self.store = store
        self.settings = store.load()
    }

    func start() {
        screenState = .active

        if settings.launchAtLogin, !LoginItem.isEnabled {
            LoginItem.setEnabled(true)
            settings.launchAtLogin = LoginItem.isEnabled
            store.save(settings)
        }

        let host = PanelHost(
            settings: settings,
            screenState: screenState,
            source: input,
            systemSource: system
        )
        panelHost = host
        host.rebuild()

        menuBar = MenuBarController(settings: settings) { [weak self] action in
            self?.handle(action)
        }

        installObservers()
    }

    func stop() {
        for (center, token) in observers {
            center.removeObserver(token)
        }
        observers.removeAll()
        panelHost?.teardown()
        panelHost = nil
        menuBar?.remove()
        menuBar = nil
    }

    private func handle(_ action: MenuBarController.Action) {
        switch action {
        case .setPersonality(let personality):
            settings.personality = personality
        case .setMuted(let muted):
            settings.isMuted = muted
        case .setLaunchAtLogin(let enabled):
            LoginItem.setEnabled(enabled)
            settings.launchAtLogin = LoginItem.isEnabled
        case .quit:
            NSApp.terminate(nil)
            return
        }
        persist()
    }

    private func persist() {
        store.save(settings)
        panelHost?.update(settings: settings)
        menuBar?.update(settings: settings)
    }

    private func setScreenState(_ state: ScreenState) {
        screenState = state
        panelHost?.setScreenState(state)
    }

    private func installObservers() {
        let defaultCenter = NotificationCenter.default
        observers.append((defaultCenter, defaultCenter.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.panelHost?.rebuild() }
        }))

        let workspace = NSWorkspace.shared.notificationCenter
        observers.append((workspace, workspace.addObserver(
            forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.setScreenState(.asleep) }
        }))
        observers.append((workspace, workspace.addObserver(
            forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.setScreenState(.active) }
        }))
        observers.append((workspace, workspace.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.setScreenState(.asleep) }
        }))
        observers.append((workspace, workspace.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.setScreenState(.active) }
        }))
        observers.append((workspace, workspace.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.setScreenState(.locked) }
        }))
        observers.append((workspace, workspace.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.setScreenState(.active) }
        }))
    }
}
