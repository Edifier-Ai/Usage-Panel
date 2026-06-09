import AppKit
import CodexIslandUsageCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var viewModel: WidgetViewModel?
    private var overlayPanelController: OverlayPanelController?
    private var statusMenuController: StatusMenuController?
    private var staleUsageNotificationController: StaleUsageNotificationController?
    private var tickTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let viewModel = WidgetViewModel(provider: CodexSessionUsageProvider())
        let overlayPanelController = OverlayPanelController(viewModel: viewModel)
        let statusMenuController = StatusMenuController(
            viewModel: viewModel,
            overlayPanelController: overlayPanelController
        )
        let staleUsageNotificationController = StaleUsageNotificationController()

        self.viewModel = viewModel
        self.overlayPanelController = overlayPanelController
        self.statusMenuController = statusMenuController
        self.staleUsageNotificationController = staleUsageNotificationController

        staleUsageNotificationController.requestAuthorization()
        overlayPanelController.showOrHideForCurrentState()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak viewModel] _ in
            Task { @MainActor in
                await viewModel?.refresh()
                if let viewModel {
                    staleUsageNotificationController.notifyIfNeeded(
                        snapshot: viewModel.snapshot,
                        hasLoadedUsage: viewModel.hasLoadedUsage,
                        isAwaitingInitialUsage: viewModel.isAwaitingInitialUsage,
                        now: viewModel.now
                    )
                }
            }
        }

        Task {
            await viewModel.refresh()
            staleUsageNotificationController.notifyIfNeeded(
                snapshot: viewModel.snapshot,
                hasLoadedUsage: viewModel.hasLoadedUsage,
                isAwaitingInitialUsage: viewModel.isAwaitingInitialUsage,
                now: viewModel.now
            )
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        tickTimer?.invalidate()
        tickTimer = nil
    }
}
