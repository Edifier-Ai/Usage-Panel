import Foundation

public enum UsageRefreshState: String, Equatable, Sendable {
    case normal
    case soon
    case urgent
}

public enum UsageDisplayScheme: Equatable, Sendable {
    case light
    case dark
}

public struct UsageDisplayColor: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum UsageColorPolicy {
    public static let normalAccentColor = UsageDisplayColor(red: 0.37, green: 0.94, blue: 0.64)
    public static let soonAccentColor = UsageDisplayColor(red: 1.0, green: 0.84, blue: 0.28)
    public static let urgentAccentColor = UsageDisplayColor(red: 1.0, green: 0.36, blue: 0.42)
    public static let lightGradientTerminalColor = UsageDisplayColor(red: 1.0, green: 1.0, blue: 1.0)
    public static let darkGradientTerminalColor = UsageDisplayColor(red: 1.0, green: 1.0, blue: 1.0)
    public static let lightDefaultRailContrastShadowOpacity = 0.16
    public static let darkDefaultRailContrastShadowOpacity = 0.0

    public static func state(refreshDate: Date, now: Date) -> UsageRefreshState {
        let remaining = refreshDate.timeIntervalSince(now)

        if remaining < 60 * 60 {
            return .urgent
        }

        if remaining < 3 * 60 * 60 {
            return .soon
        }

        return .normal
    }

    public static func accentColor(for state: UsageRefreshState) -> UsageDisplayColor {
        switch state {
        case .normal:
            normalAccentColor
        case .soon:
            soonAccentColor
        case .urgent:
            urgentAccentColor
        }
    }

    public static func gradientTerminalColor(for scheme: UsageDisplayScheme) -> UsageDisplayColor {
        switch scheme {
        case .light:
            lightGradientTerminalColor
        case .dark:
            darkGradientTerminalColor
        }
    }

    public static func defaultRailContrastShadowOpacity(for scheme: UsageDisplayScheme) -> Double {
        switch scheme {
        case .light:
            lightDefaultRailContrastShadowOpacity
        case .dark:
            darkDefaultRailContrastShadowOpacity
        }
    }
}
