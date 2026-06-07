import Foundation

public final class WidgetSettingsStore {
    private enum Keys {
        static let appearanceMode = "CodexIslandUsageWidget.appearanceMode"
        static let showsWeeklyQuotaInDefault = "CodexIslandUsageWidget.showsWeeklyQuotaInDefault"
        static let isHidden = "CodexIslandUsageWidget.isHidden"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> WidgetSettings {
        let appearanceMode = defaults.string(forKey: Keys.appearanceMode)
            .flatMap(WidgetAppearanceMode.init(rawValue:)) ?? .system

        let showsWeeklyQuotaInDefault: Bool
        if defaults.object(forKey: Keys.showsWeeklyQuotaInDefault) == nil {
            showsWeeklyQuotaInDefault = true
        } else {
            showsWeeklyQuotaInDefault = defaults.bool(forKey: Keys.showsWeeklyQuotaInDefault)
        }

        return WidgetSettings(
            appearanceMode: appearanceMode,
            showsWeeklyQuotaInDefault: showsWeeklyQuotaInDefault,
            isHidden: defaults.bool(forKey: Keys.isHidden)
        )
    }

    public func save(_ settings: WidgetSettings) {
        defaults.set(settings.appearanceMode.rawValue, forKey: Keys.appearanceMode)
        defaults.set(settings.showsWeeklyQuotaInDefault, forKey: Keys.showsWeeklyQuotaInDefault)
        defaults.set(settings.isHidden, forKey: Keys.isHidden)
    }
}
