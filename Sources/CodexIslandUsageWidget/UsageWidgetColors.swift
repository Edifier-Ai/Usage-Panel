import CodexIslandUsageCore
import SwiftUI

enum UsageWidgetColors {
    static let loadingAccent = accent(for: .soon)
    static let freshAccent = accent(for: .normal)
    static let staleAccent = accent(for: .urgent)

    static func accent(for state: UsageRefreshState) -> Color {
        Color(UsageColorPolicy.accentColor(for: state))
    }

    static func gradientTerminal(for scheme: UsageDisplayScheme) -> Color {
        Color(UsageColorPolicy.gradientTerminalColor(for: scheme))
    }

    static func defaultRailContrastShadowOpacity(for scheme: UsageDisplayScheme) -> Double {
        UsageColorPolicy.defaultRailContrastShadowOpacity(for: scheme)
    }
}

private extension Color {
    init(_ color: UsageDisplayColor) {
        self.init(red: color.red, green: color.green, blue: color.blue)
    }
}
