import XCTest
@testable import NotchlingCore

final class SettingsTests: XCTestCase {
    func testDefaultsAreCompanionUnmutedLaunchOff() {
        let settings = PipSettings.standard
        XCTAssertEqual(settings.personality, .companion)
        XCTAssertFalse(settings.isMuted)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testSettingsStoreRoundTrips() {
        let store = InMemorySettingsStore()
        var settings = store.load()
        XCTAssertEqual(settings, .standard)

        settings.personality = .playful
        settings.isMuted = true
        settings.launchAtLogin = true
        store.save(settings)

        XCTAssertEqual(store.load(), settings)
    }

    func testPersonalityRawValueSurvivesPersistence() {
        for personality in Personality.allCases {
            XCTAssertEqual(Personality(rawValue: personality.rawValue), personality)
        }
    }
}
