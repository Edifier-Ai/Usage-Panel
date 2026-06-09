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

    func testExpandIsIdempotentForDuplicateClickEvents() {
        let viewModel = makeViewModel()

        viewModel.expand()
        viewModel.expand()

        XCTAssertTrue(viewModel.isExpanded)
    }

    func testStartsAwaitingInitialUsageWithNeutralSnapshot() {
        let now = Date(timeIntervalSince1970: 1_780_849_600)
        let viewModel = makeViewModel(now: now)

        XCTAssertTrue(viewModel.isAwaitingInitialUsage)
        XCTAssertEqual(viewModel.snapshot.fiveHourUsedFraction, 0)
        XCTAssertEqual(viewModel.snapshot.weeklyUsedFraction, 0)
        XCTAssertEqual(viewModel.snapshot.fiveHourRefreshDate, now)
        XCTAssertEqual(viewModel.snapshot.lastUpdated, now)
        XCTAssertFalse(viewModel.snapshot.isFresh)
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
            weeklyRefreshDate: now.addingTimeInterval(7 * 24 * 60 * 60),
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
        XCTAssertFalse(viewModel.isAwaitingInitialUsage)
    }

    func testForceRefreshReloadsProviderSnapshotImmediately() async {
        let initialNow = Date(timeIntervalSince1970: 1_780_849_600)
        let forcedNow = initialNow.addingTimeInterval(90)
        let provider = RecordingUsageProvider()
        let viewModel = makeViewModel(
            provider: provider,
            now: initialNow
        )

        await viewModel.forceRefresh(now: forcedNow)

        let requestedDates = await provider.recordedDates()
        XCTAssertEqual(requestedDates, [forcedNow])
        XCTAssertEqual(viewModel.snapshot.lastUpdated, forcedNow)
        XCTAssertEqual(viewModel.now, forcedNow)
        XCTAssertFalse(viewModel.isAwaitingInitialUsage)
    }

    func testSuccessfulRefreshWritesHeartbeat() async throws {
        let now = Date(timeIntervalSince1970: 1_780_849_600)
        let expected = UsageSnapshot(
            fiveHourUsedFraction: 0.2,
            weeklyUsedFraction: 0.8,
            fiveHourRefreshDate: now.addingTimeInterval(60),
            weeklyRefreshDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            lastUpdated: now.addingTimeInterval(-120),
            isFresh: true
        )
        let heartbeatURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexIslandUsageWidgetTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("last_success.json")
        let viewModel = makeViewModel(
            provider: MockUsageProvider { _ in expected },
            heartbeatStore: UsageHeartbeatStore(fileURL: heartbeatURL),
            now: now
        )

        await viewModel.refresh(now: now)

        let data = try Data(contentsOf: heartbeatURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let heartbeat = try decoder.decode(UsageHeartbeat.self, from: data)
        XCTAssertEqual(heartbeat.refreshedAt, now)
        XCTAssertEqual(heartbeat.sourceLastUpdated, expected.lastUpdated)
        XCTAssertEqual(heartbeat.fiveHourRemainingPercent, 80)
        XCTAssertEqual(heartbeat.weeklyRemainingPercent, 20)
        XCTAssertTrue(heartbeat.isFresh)
    }

    func testInitialRefreshFailureShowsReadableFailureState() async {
        let now = Date(timeIntervalSince1970: 1_780_849_600)
        let viewModel = makeViewModel(
            provider: FailingUsageProvider(),
            now: now
        )

        await viewModel.refresh(now: now.addingTimeInterval(60))

        XCTAssertFalse(viewModel.isAwaitingInitialUsage)
        XCTAssertFalse(viewModel.hasLoadedUsage)
        XCTAssertEqual(viewModel.usageLoadError, "暂时无法读取 Codex 用量")
        XCTAssertEqual(viewModel.snapshot.fiveHourUsedFraction, 0)
        XCTAssertEqual(viewModel.snapshot.weeklyUsedFraction, 0)
        XCTAssertEqual(viewModel.snapshot.fiveHourRefreshDate, now)
        XCTAssertEqual(viewModel.snapshot.lastUpdated, now)
        XCTAssertFalse(viewModel.snapshot.isFresh)
    }

    func testSnapshotReportsRemainingPercentages() {
        let snapshot = UsageSnapshot(
            fiveHourUsedFraction: 0.63,
            weeklyUsedFraction: 0.41,
            fiveHourRefreshDate: Date(timeIntervalSince1970: 1_780_849_600),
            weeklyRefreshDate: Date(timeIntervalSince1970: 1_781_454_400),
            lastUpdated: Date(timeIntervalSince1970: 1_780_849_600),
            isFresh: true
        )

        XCTAssertEqual(snapshot.fiveHourRemainingPercent, 37)
        XCTAssertEqual(snapshot.weeklyRemainingPercent, 59)
    }

    func testSnapshotReportsStaleAgeText() {
        let now = Date(timeIntervalSince1970: 1_780_849_600)
        let snapshot = UsageSnapshot(
            fiveHourUsedFraction: 0.63,
            weeklyUsedFraction: 0.41,
            fiveHourRefreshDate: now,
            weeklyRefreshDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            lastUpdated: now.addingTimeInterval(-16 * 60),
            isFresh: false
        )

        XCTAssertEqual(snapshot.lastUpdatedAgeText(now: now), "16 分钟前")
        XCTAssertEqual(snapshot.dataFreshnessText(now: now), "数据已过期 · 额度变动后自动刷新 · 上次更新 16 分钟前")
    }

    func testTickUpdatesCurrentTimeForRefreshState() async {
        let initialNow = Date(timeIntervalSince1970: 1_780_849_600)
        let refreshDate = initialNow.addingTimeInterval((3 * 60 * 60) + 1)
        let snapshot = UsageSnapshot(
            fiveHourUsedFraction: 0.4,
            weeklyUsedFraction: 0.2,
            fiveHourRefreshDate: refreshDate,
            weeklyRefreshDate: initialNow.addingTimeInterval(7 * 24 * 60 * 60),
            lastUpdated: initialNow,
            isFresh: true
        )
        let viewModel = makeViewModel(
            provider: MockUsageProvider { _ in snapshot },
            now: initialNow
        )

        await viewModel.refresh(now: initialNow)

        XCTAssertEqual(viewModel.refreshState(), .normal)

        viewModel.tick(now: initialNow.addingTimeInterval(2))

        XCTAssertEqual(viewModel.refreshState(), .soon)
    }

    func testRefreshFailureAfterInitialLoadMarksSnapshotAsStale() async {
        let now = Date(timeIntervalSince1970: 1_780_849_600)
        let loadedSnapshot = UsageSnapshot(
            fiveHourUsedFraction: 0.32,
            weeklyUsedFraction: 0.58,
            fiveHourRefreshDate: now.addingTimeInterval(60),
            weeklyRefreshDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            lastUpdated: now,
            isFresh: true
        )
        let viewModel = makeViewModel(
            provider: FailsAfterFirstSuccessProvider(snapshot: loadedSnapshot),
            now: now
        )

        await viewModel.refresh(now: now)
        await viewModel.refresh(now: now.addingTimeInterval(60))

        XCTAssertFalse(viewModel.isAwaitingInitialUsage)
        XCTAssertEqual(viewModel.snapshot.fiveHourUsedFraction, loadedSnapshot.fiveHourUsedFraction)
        XCTAssertEqual(viewModel.snapshot.weeklyUsedFraction, loadedSnapshot.weeklyUsedFraction)
        XCTAssertEqual(viewModel.snapshot.fiveHourRefreshDate, loadedSnapshot.fiveHourRefreshDate)
        XCTAssertEqual(viewModel.snapshot.lastUpdated, loadedSnapshot.lastUpdated)
        XCTAssertFalse(viewModel.snapshot.isFresh)
        XCTAssertTrue(viewModel.hasLoadedUsage)
        XCTAssertNil(viewModel.usageLoadError)
    }

    private func makeViewModel(
        provider: UsageProviding = MockUsageProvider(),
        store: WidgetSettingsStore? = nil,
        heartbeatStore: UsageHeartbeatStore? = nil,
        now: Date = Date(timeIntervalSince1970: 1_780_849_600)
    ) -> WidgetViewModel {
        WidgetViewModel(
            provider: provider,
            settingsStore: store ?? WidgetSettingsStore(defaults: UserDefaults(suiteName: suiteName)!),
            heartbeatStore: heartbeatStore ?? .disabled,
            now: now
        )
    }
}

private struct FailingUsageProvider: UsageProviding {
    func currentUsage(now: Date) async throws -> UsageSnapshot {
        throw NSError(domain: "CodexIslandUsageWidgetTests", code: 1)
    }
}

private actor FailsAfterFirstSuccessProvider: UsageProviding {
    private let snapshot: UsageSnapshot
    private var shouldFail = false

    init(snapshot: UsageSnapshot) {
        self.snapshot = snapshot
    }

    func currentUsage(now: Date) async throws -> UsageSnapshot {
        if shouldFail {
            throw NSError(domain: "CodexIslandUsageWidgetTests", code: 1)
        }

        shouldFail = true
        return snapshot
    }
}

private actor RecordingUsageProvider: UsageProviding {
    private var requestedDates: [Date] = []

    func currentUsage(now: Date) async throws -> UsageSnapshot {
        requestedDates.append(now)
        return UsageSnapshot(
            fiveHourUsedFraction: 0.44,
            weeklyUsedFraction: 0.66,
            fiveHourRefreshDate: now.addingTimeInterval(60 * 60),
            weeklyRefreshDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            lastUpdated: now,
            isFresh: true
        )
    }

    func recordedDates() -> [Date] {
        requestedDates
    }
}
