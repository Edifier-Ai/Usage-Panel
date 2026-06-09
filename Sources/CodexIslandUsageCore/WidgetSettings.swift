import Foundation

public enum WidgetAppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case dark
    case light
}

public enum WidgetColorSchemePreference: Equatable, Sendable {
    case system
    case dark
    case light
}

public extension WidgetAppearanceMode {
    var colorSchemePreference: WidgetColorSchemePreference {
        switch self {
        case .system:
            return .system
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

public struct WidgetSettings: Equatable, Codable, Sendable {
    public var appearanceMode: WidgetAppearanceMode
    public var showsWeeklyQuotaInDefault: Bool
    public var isHidden: Bool

    public init(
        appearanceMode: WidgetAppearanceMode = .system,
        showsWeeklyQuotaInDefault: Bool = true,
        isHidden: Bool = false
    ) {
        self.appearanceMode = appearanceMode
        self.showsWeeklyQuotaInDefault = showsWeeklyQuotaInDefault
        self.isHidden = isHidden
    }
}
