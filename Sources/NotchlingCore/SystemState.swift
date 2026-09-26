import Foundation

/// A single read of the surrounding system state that Pip reacts to.
///
/// Audio is a boolean: are the default output device's streams running
/// (`kAudioDevicePropertyDeviceIsRunningSomewhere`)? No samples are read and no
/// permission is required. Charging is a boolean power-source fact. Keeping the
/// value plain lets the reaction triggers be unit-tested with no hardware.
public struct SystemState: Equatable, Sendable {
    public var audioOutputRunning: Bool
    public var isCharging: Bool

    public init(audioOutputRunning: Bool = false, isCharging: Bool = false) {
        self.audioOutputRunning = audioOutputRunning
        self.isCharging = isCharging
    }

    public static let idle = SystemState()
    public static let music = SystemState(audioOutputRunning: true)
    public static let charging = SystemState(isCharging: true)

    /// Alias for callers that think in terms of "music playing".
    public var isAudioRunning: Bool { audioOutputRunning }
}

/// Where system state comes from. The app implements this with a CoreAudio
/// property listener plus an IOKit power-source notification; tests supply a
/// scripted sequence. Keeping it a protocol keeps the core free of frameworks
/// and makes the triggers testable without hardware.
public protocol SystemStateSource: AnyObject {
    func readSystemState() -> SystemState
}

/// Time-of-day moods derived purely from the injected clock. `morning` is the
/// perky start, `daytime` is neutral, and `night` is the late-night nightcap.
public enum TimeOfDay: String, CaseIterable, Equatable, Sendable {
    case morning
    case daytime
    case night

    public static let morningStartHour = 5
    public static let nightStartHour = 23

    public init(hour: Int) {
        let h = ((hour % 24) + 24) % 24
        if h >= Self.nightStartHour || h < Self.morningStartHour {
            self = .night
        } else if h < 12 {
            self = .morning
        } else {
            self = .daytime
        }
    }

    public init(date: Date, calendar: Calendar = .current) {
        self.init(hour: calendar.component(.hour, from: date))
    }

    public var isPerky: Bool { self == .morning }
    public var isNightcap: Bool { self == .night }
}
