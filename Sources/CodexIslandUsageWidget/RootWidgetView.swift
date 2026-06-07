import CodexIslandUsageCore
import SwiftUI

struct RootWidgetView: View {
    @ObservedObject var viewModel: WidgetViewModel

    var body: some View {
        VStack(spacing: 12) {
            if !viewModel.settings.isHidden {
                DefaultCapsuleView(
                    snapshot: viewModel.snapshot,
                    settings: viewModel.settings,
                    refreshState: viewModel.refreshState()
                )
                .onTapGesture {
                    viewModel.toggleExpanded()
                }

                if viewModel.isExpanded {
                    ExpandedPopoverView(viewModel: viewModel, now: Date())
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(width: viewModel.isExpanded ? 292 : 118, alignment: .top)
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: viewModel.isExpanded)
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: viewModel.settings.showsWeeklyQuotaInDefault)
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch viewModel.settings.appearanceMode {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}
