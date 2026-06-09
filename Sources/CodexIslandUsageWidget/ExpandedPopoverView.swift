import CodexIslandUsageCore
import SwiftUI

struct ExpandedPopoverView: View {
    @ObservedObject var viewModel: WidgetViewModel
    @State private var isRefreshing = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: viewModel.isAwaitingInitialUsage ? viewModel.now : context.date)
        }
        .foregroundStyle(.primary)
        .padding(13)
        .frame(width: 292)
        .liquidGlass(cornerRadius: 20, prominence: .popover)
        .widgetAppearance(viewModel.settings.appearanceMode)
        .nativeGlassEffectContainer()
    }

    private func content(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Usage Panel")
                    .font(.system(size: 12, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isRefreshing else {
                            return
                        }
                        isRefreshing = true
                        Task { @MainActor in
                            await viewModel.forceRefresh()
                            isRefreshing = false
                        }
                    }
                    .help("强制刷新")
                    .accessibilityLabel("强制刷新")
                    .accessibilityAddTraits(.isButton)
            }

            statusRow(now: now)

            metricBlock(
                title: "5 小时额度",
                value: quotaValueText(viewModel.snapshot.fiveHourRemainingPercent),
                detailTitle: "刷新倒计时",
                detailValue: fiveHourRefreshCountdownText(now: now),
                rail: UsageRail(
                    fraction: viewModel.snapshot.fiveHourUsedFraction,
                    kind: .fiveHour(viewModel.refreshState()),
                    isLoading: viewModel.isAwaitingInitialUsage,
                    height: 3
                )
            )

            metricBlock(
                title: "周额度",
                value: quotaValueText(viewModel.snapshot.weeklyRemainingPercent),
                detailTitle: "刷新倒计时",
                detailValue: weeklyRefreshCountdownText(now: now),
                rail: UsageRail(
                    fraction: viewModel.snapshot.weeklyUsedFraction,
                    kind: .week,
                    isLoading: viewModel.isAwaitingInitialUsage,
                    height: 3
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
        }
    }

    private func statusRow(now: Date) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText(now: now))
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .foregroundStyle(statusColor)
    }

    private func statusText(now: Date) -> String {
        if !viewModel.hasLoadedUsage, let usageLoadError = viewModel.usageLoadError {
            return usageLoadError
        }

        if viewModel.isAwaitingInitialUsage {
            return "正在读取 Codex 用量"
        }

        return viewModel.snapshot.dataFreshnessText(now: now)
    }

    private var statusColor: Color {
        if !viewModel.hasLoadedUsage, viewModel.usageLoadError != nil {
            return UsageWidgetColors.staleAccent
        }

        if viewModel.isAwaitingInitialUsage {
            return UsageWidgetColors.loadingAccent
        }

        return viewModel.snapshot.isFresh
            ? UsageWidgetColors.freshAccent
            : UsageWidgetColors.staleAccent
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

    private func fiveHourRefreshCountdownText(now: Date) -> String {
        if viewModel.isAwaitingInitialUsage {
            return "loading"
        }

        guard viewModel.hasLoadedUsage else {
            return "未读取"
        }

        return countdownText(until: viewModel.snapshot.fiveHourRefreshDate, now: now)
    }

    private func weeklyRefreshCountdownText(now: Date) -> String {
        if viewModel.isAwaitingInitialUsage {
            return "loading"
        }

        guard viewModel.hasLoadedUsage else {
            return "未读取"
        }

        return countdownText(until: viewModel.snapshot.weeklyRefreshDate, now: now)
    }

    private func countdownText(until refreshDate: Date, now: Date) -> String {
        let remaining = max(0, refreshDate.timeIntervalSince(now))
        let days = Int(remaining) / (24 * 60 * 60)
        let hours = (Int(remaining) % (24 * 60 * 60)) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }

        return "\(hours)h \(minutes)m"
    }

    private func quotaValueText(_ remainingPercent: Int) -> String {
        if viewModel.isAwaitingInitialUsage {
            return "loading"
        }

        guard viewModel.hasLoadedUsage else {
            return "未读取"
        }

        return "剩余额度 \(remainingPercent)%"
    }
}
