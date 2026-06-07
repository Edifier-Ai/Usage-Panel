import CodexIslandUsageCore
import SwiftUI

struct DefaultCapsuleView: View {
    let snapshot: UsageSnapshot
    let settings: WidgetSettings
    let refreshState: UsageRefreshState

    var body: some View {
        HStack(spacing: 5) {
            UsageRail(
                fraction: snapshot.fiveHourUsedFraction,
                kind: .fiveHour(refreshState)
            )

            if settings.showsWeeklyQuotaInDefault {
                UsageRail(
                    fraction: snapshot.weeklyUsedFraction,
                    kind: .week
                )
            }

            Circle()
                .fill(snapshot.isFresh ? Color(red: 0.54, green: 0.96, blue: 0.74) : Color.white.opacity(0.38))
                .frame(width: 3, height: 3)
                .shadow(color: snapshot.isFresh ? Color(red: 0.54, green: 0.96, blue: 0.74).opacity(0.8) : .clear, radius: 5)
        }
        .padding(.horizontal, 8)
        .frame(width: 118, height: 13)
        .liquidGlass(cornerRadius: 6.5, prominence: .capsule)
    }
}
