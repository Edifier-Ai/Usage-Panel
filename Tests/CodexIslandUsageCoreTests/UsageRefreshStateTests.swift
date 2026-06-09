import Foundation
import XCTest
@testable import CodexIslandUsageCore

final class UsageRefreshStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_780_849_600)

    func testRefreshAtOrAfterThreeHoursIsNormal() {
        let refreshDate = now.addingTimeInterval(3 * 60 * 60)

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .normal
        )
    }

    func testRefreshUnderThreeHoursAndAtLeastOneHourIsSoon() {
        let refreshDate = now.addingTimeInterval((2 * 60 * 60) + (59 * 60))

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .soon
        )
    }

    func testRefreshUnderOneHourIsUrgent() {
        let refreshDate = now.addingTimeInterval((59 * 60) + 59)

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .urgent
        )
    }

    func testPastRefreshDateIsUrgent() {
        let refreshDate = now.addingTimeInterval(-60)

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .urgent
        )
    }

    func testRefreshStatePaletteUsesGreenYellowRedProgression() {
        XCTAssertEqual(
            UsageColorPolicy.accentColor(for: .normal),
            UsageDisplayColor(red: 0.37, green: 0.94, blue: 0.64)
        )
        XCTAssertEqual(
            UsageColorPolicy.accentColor(for: .soon),
            UsageDisplayColor(red: 1.0, green: 0.84, blue: 0.28)
        )
        XCTAssertEqual(
            UsageColorPolicy.accentColor(for: .urgent),
            UsageDisplayColor(red: 1.0, green: 0.36, blue: 0.42)
        )
    }

    func testGradientTerminalColorUsesWhiteInEveryTheme() {
        XCTAssertEqual(
            UsageColorPolicy.gradientTerminalColor(for: .light),
            UsageDisplayColor(red: 1.0, green: 1.0, blue: 1.0)
        )
        XCTAssertEqual(
            UsageColorPolicy.gradientTerminalColor(for: .dark),
            UsageDisplayColor(red: 1.0, green: 1.0, blue: 1.0)
        )
    }

    func testDefaultRailContrastShadowOnlyAppearsInLightTheme() {
        XCTAssertEqual(
            UsageColorPolicy.defaultRailContrastShadowOpacity(for: .light),
            0.16
        )
        XCTAssertEqual(
            UsageColorPolicy.defaultRailContrastShadowOpacity(for: .dark),
            0.0
        )
    }
}
