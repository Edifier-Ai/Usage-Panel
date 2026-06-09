import CodexIslandUsageCore
import AppKit
import SwiftUI

extension WidgetAppearanceMode {
    var nsAppearance: NSAppearance? {
        switch colorSchemePreference {
        case .system:
            return nil
        case .dark:
            return NSAppearance(named: .darkAqua)
        case .light:
            return NSAppearance(named: .aqua)
        }
    }
}

extension WidgetColorSchemePreference {
    var swiftUIColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

extension View {
    func widgetAppearance(_ mode: WidgetAppearanceMode) -> some View {
        preferredColorScheme(mode.colorSchemePreference.swiftUIColorScheme)
    }
}
