import Foundation

public enum WidgetAppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case dark
    case light
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
