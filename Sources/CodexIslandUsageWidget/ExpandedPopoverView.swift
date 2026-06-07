import CodexIslandUsageCore
import SwiftUI

struct ExpandedPopoverView: View {
    @ObservedObject var viewModel: WidgetViewModel
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Codex Usage")
                .font(.system(size: 12, weight: .semibold))

            metricBlock(
                title: "5 小时额度",
                value: "\(Int(viewModel.snapshot.fiveHourUsedFraction * 100))% used",
                detailTitle: "刷新倒计时",
                detailValue: refreshCountdownText,
                rail: UsageRail(
                    fraction: viewModel.snapshot.fiveHourUsedFraction,
                    kind: .fiveHour(viewModel.refreshState(now: now))
                )
            )

            metricBlock(
                title: "本周额度",
                value: "\(Int(viewModel.snapshot.weeklyUsedFraction * 100))% used",
                detailTitle: "数据更新",
                detailValue: lastUpdatedText,
                rail: UsageRail(
                    fraction: viewModel.snapshot.weeklyUsedFraction,
                    kind: .week
                )
            )

            Divider().opacity(0.25)

            HStack {
                Text("外观")
                    .font(.system(size: 11))
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.settings.appearanceMode },
                    set: { viewModel.setAppearanceMode($0) }
                )) {
                    Text("系统").tag(WidgetAppearanceMode.system)
                    Text("暗").tag(WidgetAppearanceMode.dark)
                    Text("亮").tag(WidgetAppearanceMode.light)
                }
                .pickerStyle(.segmented)
                .frame(width: 126)
            }

            HStack {
                Text("默认态显示周额度")
                    .font(.system(size: 11))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.settings.showsWeeklyQuotaInDefault },
                    set: { viewModel.setShowsWeeklyQuotaInDefault($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            Button("隐藏") {
                viewModel.setHidden(true)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding(13)
        .frame(width: 292)
        .liquidGlass(cornerRadius: 20, prominence: .popover)
    }

    private func metricBlock(
        title: String,
        value: String,
        detailTitle: String,
        detailValue: String,
        rail: UsageRail
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
            }

            rail

            HStack {
                Text(detailTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(detailValue)
                    .font(.system(size: 11, weight: .semibold))
            }
        }
    }

    private var refreshCountdownText: String {
        let remaining = max(0, viewModel.snapshot.fiveHourRefreshDate.timeIntervalSince(now))
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private var lastUpdatedText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: viewModel.snapshot.lastUpdated)
    }
}
