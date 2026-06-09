import CodexIslandUsageCore
import SwiftUI

struct RootWidgetView: View {
    @ObservedObject var viewModel: WidgetViewModel
    private let layout = OverlayLayout()

    var body: some View {
        VStack(spacing: 12) {
            if !viewModel.settings.isHidden {
                capsuleView
            }
        }
        .nativeGlassEffectContainer(spacing: 12)
        .frame(
            width: rootWidth,
            height: rootHeight,
            alignment: .top
        )
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: viewModel.settings.showsWeeklyQuotaInDefault)
        .animation(.easeInOut(duration: 0.18), value: viewModel.isAwaitingInitialUsage)
        .widgetAppearance(viewModel.settings.appearanceMode)
    }

    @ViewBuilder
    private var capsuleView: some View {
        DefaultCapsuleView(
            snapshot: viewModel.snapshot,
            settings: viewModel.settings,
            refreshState: viewModel.refreshState(),
            isLoading: viewModel.isAwaitingInitialUsage
        )
    }

    private var rootWidth: CGFloat {
        return CGFloat(layout.hostedContentWidth)
    }

    private var rootHeight: CGFloat {
        return CGFloat(layout.defaultHeight)
    }
}
