import AppKit
import NotchlingCore

/// Pointer input from a global `NSEvent` monitor.
///
/// A global monitor observes mouse movement and clicks without any permission
/// (no Accessibility, no Input Monitoring) and without consuming the events, so
/// Pip never blocks a click. Positions are reported in screen coordinates, the
/// same space as `ScreenGeometry` and the figure rect computed from it. State is
/// guarded by a lock so the core can read it from any thread.
final class CursorTracker: PipInputSource, @unchecked Sendable {
    private let lock = NSLock()
    private var cursor: Point?
    private var pendingClick = false
    private var monitors: [Any] = []

    init() {
        let location = NSEvent.mouseLocation
        cursor = Point(x: Double(location.x), y: Double(location.y))

        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown]
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event)
        }) {
            monitors.append(monitor)
        }
    }

    func readInput() -> PipInput {
        lock.lock()
        defer { lock.unlock() }
        let click = pendingClick
        pendingClick = false
        return PipInput(cursor: cursor, click: click)
    }

    private func handle(_ event: NSEvent) {
        let location = NSEvent.mouseLocation
        lock.lock()
        defer { lock.unlock() }
        cursor = Point(x: Double(location.x), y: Double(location.y))
        if event.type == .leftMouseDown {
            pendingClick = true
        }
    }
}
