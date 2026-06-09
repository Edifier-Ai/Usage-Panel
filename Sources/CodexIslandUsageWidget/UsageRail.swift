import CodexIslandUsageCore
import SwiftUI

struct UsageRail: View {
    enum Kind {
        case fiveHour(UsageRefreshState)
        case week
    }

    @Environment(\.colorScheme) private var colorScheme
    @State private var loadingStartedAt = Date()

    let fraction: Double
    let kind: Kind
    var isLoading = false
    var height: CGFloat = 2
    var usesLightThemeContrastShadow = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.16))

                fill(width: proxy.size.width)
            }
        }
        .frame(height: height)
        .onAppear {
            loadingStartedAt = Date()
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                loadingStartedAt = Date()
            }
        }
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }

    @ViewBuilder
    private func fill(width: CGFloat) -> some View {
        if isLoading {
            TimelineView(.animation) { context in
                Capsule()
                    .fill(loadingGradient)
                    .frame(width: width * loadingProgress(at: context.date))
                    .shadow(color: contrastShadowColor, radius: contrastShadowRadius, y: contrastShadowY)
            }
        } else {
            Capsule()
                .fill(gradient)
                .frame(width: width * clampedFraction)
                .shadow(color: contrastShadowColor, radius: contrastShadowRadius, y: contrastShadowY)
        }
    }

    private func loadingProgress(at date: Date) -> Double {
        let cycleDuration = 1.35
        let elapsed = max(0, date.timeIntervalSince(loadingStartedAt))
        return elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
    }

    private var loadingGradient: LinearGradient {
        LinearGradient(
            colors: [
                UsageWidgetColors.loadingAccent,
                .white
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var gradient: LinearGradient {
        switch kind {
        case .fiveHour(let state):
            return LinearGradient(colors: [UsageWidgetColors.accent(for: state), gradientTerminalColor], startPoint: .leading, endPoint: .trailing)
        case .week:
            return LinearGradient(colors: [Color.white.opacity(0.48), Color.white.opacity(0.96)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var gradientTerminalColor: Color {
        UsageWidgetColors.gradientTerminal(for: usageDisplayScheme)
    }

    private var usageDisplayScheme: UsageDisplayScheme {
        colorScheme == .light ? .light : .dark
    }

    private var contrastShadowOpacity: Double {
        guard usesLightThemeContrastShadow else {
            return 0
        }

        return UsageWidgetColors.defaultRailContrastShadowOpacity(for: usageDisplayScheme)
    }

    private var contrastShadowColor: Color {
        Color.black.opacity(contrastShadowOpacity)
    }

    private var contrastShadowRadius: CGFloat {
        contrastShadowOpacity > 0 ? 2 : 0
    }

    private var contrastShadowY: CGFloat {
        contrastShadowOpacity > 0 ? 0.8 : 0
    }
}
