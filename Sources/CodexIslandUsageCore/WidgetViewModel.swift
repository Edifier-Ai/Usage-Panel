import Combine
import Foundation

@MainActor
public final class WidgetViewModel: ObservableObject {
    @Published public private(set) var snapshot: UsageSnapshot
    @Published public var settings: WidgetSettings {
        didSet {
            settingsStore.save(settings)
        }
    }
    @Published public private(set) var isExpanded: Bool

    private let provider: UsageProviding
    private let settingsStore: WidgetSettingsStore

    public init(
        provider: UsageProviding = MockUsageProvider(),
        settingsStore: WidgetSettingsStore = WidgetSettingsStore(),
        now: Date = Date()
    ) {
        self.provider = provider
        self.settingsStore = settingsStore
        self.settings = settingsStore.load()
        self.snapshot = UsageSnapshot.demo(now: now)
        self.isExpanded = false
    }

    public func refresh(now: Date = Date()) async {
        if let nextSnapshot = try? await provider.currentUsage(now: now) {
            snapshot = nextSnapshot
        }
    }

    public func toggleExpanded() {
        isExpanded.toggle()
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

    public func refreshState(now: Date = Date()) -> UsageRefreshState {
        UsageColorPolicy.state(refreshDate: snapshot.fiveHourRefreshDate, now: now)
    }
}
