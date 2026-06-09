import Foundation
import XCTest
@testable import CodexIslandUsageCore

final class WidgetSettingsStoreTests: XCTestCase {
    private let suiteName = "CodexIslandUsageWidgetTests.SettingsStore"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testLoadReturnsDefaultSettingsWhenEmpty() {
        let store = WidgetSettingsStore(defaults: UserDefaults(suiteName: suiteName)!)

        XCTAssertEqual(store.load(), WidgetSettings())
    }

    func testSaveAndLoadRoundTripsSettings() {
        let store = WidgetSettingsStore(defaults: UserDefaults(suiteName: suiteName)!)
        let settings = WidgetSettings(
            appearanceMode: .light,
            showsWeeklyQuotaInDefault: false,
            isHidden: true
        )

        store.save(settings)

        XCTAssertEqual(store.load(), settings)
    }

    func testSaveDoesNotPersistObsoleteCapsuleStyleSetting() {
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = WidgetSettingsStore(defaults: defaults)
        defaults.set("style2", forKey: "CodexIslandUsageWidget.capsuleStyle")

        store.save(WidgetSettings())

        XCTAssertNil(defaults.object(forKey: "CodexIslandUsageWidget.capsuleStyle"))
    }

    func testAppearanceModeExposesColorSchemePreference() {
        XCTAssertEqual(WidgetAppearanceMode.system.colorSchemePreference, .system)
        XCTAssertEqual(WidgetAppearanceMode.dark.colorSchemePreference, .dark)
        XCTAssertEqual(WidgetAppearanceMode.light.colorSchemePreference, .light)
    }
}
