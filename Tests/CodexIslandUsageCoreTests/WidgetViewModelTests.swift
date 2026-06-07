import Foundation
import XCTest
@testable import CodexIslandUsageCore

@MainActor
final class WidgetViewModelTests: XCTestCase {
    private let suiteName = "CodexIslandUsageWidgetTests.ViewModel"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testToggleExpandedChangesExpandedState() {
        let viewModel = makeViewModel()

        viewModel.toggleExpanded()

        XCTAssertTrue(viewModel.isExpanded)
    }

    func testSettingsMutationsPersist() {
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = WidgetSettingsStore(defaults: defaults)
        let viewModel = makeViewModel(store: store)

        viewModel.setAppearanceMode(.dark)
        viewModel.setShowsWeeklyQuotaInDefault(false)
        viewModel.setHidden(true)

        XCTAssertEqual(
            store.load(),
            WidgetSettings(
                appearanceMode: .dark,
                showsWeeklyQuotaInDefault: false,
                isHidden: true
            )
        )
    }

    func testRefreshLoadsProviderSnapshot() async {
        let now = Date(timeIntervalSince1970: 1_780_849_600)
        let expected = UsageSnapshot(
            fiveHourUsedFraction: 0.2,
            weeklyUsedFraction: 0.8,
            fiveHourRefreshDate: now.addingTimeInterval(60),
            lastUpdated: now,
            isFresh: true
        )
        let viewModel = makeViewModel(
            provider: MockUsageProvider { _ in expected },
            now: now
        )

        await viewModel.refresh(now: now)

        XCTAssertEqual(viewModel.snapshot, expected)
        XCTAssertEqual(viewModel.refreshState(now: now), .urgent)
    }

    private func makeViewModel(
        provider: UsageProviding = MockUsageProvider(),
        store: WidgetSettingsStore? = nil,
        now: Date = Date(timeIntervalSince1970: 1_780_849_600)
    ) -> WidgetViewModel {
        WidgetViewModel(
            provider: provider,
            settingsStore: store ?? WidgetSettingsStore(defaults: UserDefaults(suiteName: suiteName)!),
            now: now
        )
    }
}
