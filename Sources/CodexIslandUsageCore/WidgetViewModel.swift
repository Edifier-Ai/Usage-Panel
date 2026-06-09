import Combine
import Foundation

@MainActor
public final class WidgetViewModel: ObservableObject {
    @Published public private(set) var snapshot: UsageSnapshot
    @Published public private(set) var isAwaitingInitialUsage: Bool
    @Published public private(set) var hasLoadedUsage: Bool
    @Published public private(set) var usageLoadError: String?
    @Published public var settings: WidgetSettings {
        didSet {
            settingsStore.save(settings)
        }
    }
    @Published public private(set) var isExpanded: Bool
    @Published public private(set) var now: Date

    private let provider: UsageProviding
    private let settingsStore: WidgetSettingsStore
    private let heartbeatStore: UsageHeartbeatStore

    public init(
        provider: UsageProviding = MockUsageProvider(),
        settingsStore: WidgetSettingsStore = WidgetSettingsStore(),
        heartbeatStore: UsageHeartbeatStore = UsageHeartbeatStore(),
        now: Date = Date()
    ) {
        self.provider = provider
        self.settingsStore = settingsStore
        self.heartbeatStore = heartbeatStore
        self.settings = settingsStore.load()
        self.snapshot = UsageSnapshot.loadingPlaceholder(now: now)
        self.isAwaitingInitialUsage = true
        self.hasLoadedUsage = false
        self.usageLoadError = nil
        self.isExpanded = false
        self.now = now
    }

    public func refresh(now: Date = Date()) async {
        self.now = now

        do {
            let nextSnapshot = try await provider.currentUsage(now: now)
            snapshot = nextSnapshot
            isAwaitingInitialUsage = false
            hasLoadedUsage = true
            usageLoadError = nil
            try? heartbeatStore.recordSuccess(snapshot: nextSnapshot, refreshedAt: now)
        } catch {
            if !hasLoadedUsage {
                isAwaitingInitialUsage = false
                usageLoadError = Self.loadErrorText(for: error)
                return
            }

            usageLoadError = nil
            snapshot = UsageSnapshot(
                fiveHourUsedFraction: snapshot.fiveHourUsedFraction,
                weeklyUsedFraction: snapshot.weeklyUsedFraction,
                fiveHourRefreshDate: snapshot.fiveHourRefreshDate,
                weeklyRefreshDate: snapshot.weeklyRefreshDate,
                lastUpdated: snapshot.lastUpdated,
                isFresh: false
            )
        }
    }

    public func forceRefresh(now: Date = Date()) async {
        await refresh(now: now)
    }

    public func tick(now: Date = Date()) {
        self.now = now
    }

    public func toggleExpanded() {
        isExpanded.toggle()
    }

    public func expand() {
        isExpanded = true
    }

    public func collapse() {
        isExpanded = false
    }

    public func setAppearanceMode(_ mode: WidgetAppearanceMode) {
        settings.appearanceMode = mode
    }

    public func setShowsWeeklyQuotaInDefault(_ value: Bool) {
        settings.showsWeeklyQuotaInDefault = value
    }

    public func setHidden(_ hidden: Bool) {
        settings.isHidden = hidden
        if hidden {
            collapse()
        }
    }

    public func refreshState(now: Date? = nil) -> UsageRefreshState {
        UsageColorPolicy.state(refreshDate: snapshot.fiveHourRefreshDate, now: now ?? self.now)
    }

    private static func loadErrorText(for error: Error) -> String {
        if let usageError = error as? CodexSessionUsageProvider.Error {
            switch usageError {
            case .noUsageEventsFound:
                return "未找到 Codex 用量数据"
            case .usageSchemaChanged:
                return "Codex 用量数据格式已变化"
            }
        }

        return "暂时无法读取 Codex 用量"
    }
}
