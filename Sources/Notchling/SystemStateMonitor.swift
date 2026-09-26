import CoreAudio
import Foundation
import IOKit.ps
import NotchlingCore

/// Boolean "is the default output device running audio somewhere" watch.
///
/// Reads only `kAudioDevicePropertyDeviceIsRunningSomewhere` (a `UInt32`) and
/// subscribes to its changes. It never opens a stream, captures samples, or asks
/// for any permission. State is guarded by a lock so `NotchlingCore` can read it
/// from any thread.
final class AudioActivityMonitor: @unchecked Sendable {
    private let lock = NSLock()
    private var running = false
    private var deviceID = AudioObjectID(kAudioObjectUnknown)
    private var runningListener: AudioObjectPropertyListenerBlock?
    private var defaultListener: AudioObjectPropertyListenerBlock?

    private var runningAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    private var defaultAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    init() {
        attach(to: Self.defaultOutputDevice())

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self else { return }
            self.detach()
            self.attach(to: Self.defaultOutputDevice())
        }
        defaultListener = listener
        _ = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &defaultAddress, DispatchQueue.main, listener
        )
    }

    func readSystemState() -> SystemState {
        lock.lock()
        defer { lock.unlock() }
        return SystemState(audioOutputRunning: running)
    }

    private func attach(to device: AudioObjectID) {
        deviceID = device
        guard device != AudioObjectID(kAudioObjectUnknown) else {
            setRunning(false)
            return
        }
        setRunning(Self.isRunning(device: device))

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self else { return }
            self.setRunning(Self.isRunning(device: self.deviceID))
        }
        runningListener = listener
        _ = AudioObjectAddPropertyListenerBlock(device, &runningAddress, DispatchQueue.main, listener)
    }

    private func detach() {
        guard deviceID != AudioObjectID(kAudioObjectUnknown), let runningListener else { return }
        _ = AudioObjectRemovePropertyListenerBlock(deviceID, &runningAddress, DispatchQueue.main, runningListener)
        self.runningListener = nil
    }

    private func setRunning(_ value: Bool) {
        lock.lock()
        running = value
        lock.unlock()
    }

    private static func isRunning(device: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        return status == noErr && value != 0
    }

    private static func defaultOutputDevice() -> AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device
        )
        return status == noErr ? device : AudioObjectID(kAudioObjectUnknown)
    }
}

/// Power-source watch backed by IOKit. It reports whether any battery is
/// charging, refreshed by an IOKit run-loop notification, so it is fully
/// event-driven and needs no permission.
final class PowerMonitor: @unchecked Sendable {
    private let lock = NSLock()
    private var charging = false
    private var runLoopSource: CFRunLoopSource?

    init() {
        refresh()
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: @convention(c) (UnsafeMutableRawPointer?) -> Void = { context in
            guard let context else { return }
            Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue().refresh()
        }
        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }

    func readSystemState() -> SystemState {
        lock.lock()
        defer { lock.unlock() }
        return SystemState(isCharging: charging)
    }

    private func refresh() {
        let value = Self.isCharging()
        lock.lock()
        charging = value
        lock.unlock()
    }

    private static func isCharging() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return false
        }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any] else { continue }
            if let charging = description[kIOPSIsChargingKey] as? Bool, charging {
                return true
            }
        }
        return false
    }
}

/// Merges the audio and power watches into the single `SystemState` the engine
/// reads each step.
final class SystemStateMonitor: SystemStateSource, @unchecked Sendable {
    private let audio = AudioActivityMonitor()
    private let power = PowerMonitor()

    func readSystemState() -> SystemState {
        SystemState(
            audioOutputRunning: audio.readSystemState().audioOutputRunning,
            isCharging: power.readSystemState().isCharging
        )
    }
}
