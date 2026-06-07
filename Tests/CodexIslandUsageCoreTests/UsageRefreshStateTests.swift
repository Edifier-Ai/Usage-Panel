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
}
