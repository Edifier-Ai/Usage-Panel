import CodexIslandUsageCore
import SwiftUI

struct DefaultCapsuleView: View {
    let snapshot: UsageSnapshot
    let settings: WidgetSettings
    let refreshState: UsageRefreshState
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 5) {
            UsageRail(
                fraction: snapshot.fiveHourUsedFraction,
                kind: .fiveHour(refreshState),
                isLoading: isLoading,
                height: 3,
                usesLightThemeContrastShadow: true
            )

            if settings.showsWeeklyQuotaInDefault {
                UsageRail(
                    fraction: snapshot.weeklyUsedFraction,
                    kind: .week,
                    isLoading: isLoading,
                    height: 3,
                    usesLightThemeContrastShadow: true
                )
            }

            Circle()
                .fill(statusColor)
                .frame(width: 3, height: 3)
                .shadow(color: statusShadowColor, radius: 5)
        }
        .padding(.horizontal, 8)
        .frame(width: 118, height: 13)
        .liquidGlass(cornerRadius: 4, prominence: .capsule)
    }

    private var statusColor: Color {
        if isLoading {
            return UsageWidgetColors.loadingAccent
        }
        return snapshot.isFresh ? UsageWidgetColors.freshAccent : Color.white.opacity(0.38)
    }

    private var statusShadowColor: Color {
        if isLoading {
            return UsageWidgetColors.loadingAccent.opacity(0.72)
        }
        return snapshot.isFresh ? UsageWidgetColors.freshAccent.opacity(0.8) : .clear
    }
}
