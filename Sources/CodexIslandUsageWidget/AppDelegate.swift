import AppKit
import CodexIslandUsageCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var viewModel: WidgetViewModel?
    private var overlayPanelController: OverlayPanelController?
    private var statusMenuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let viewModel = WidgetViewModel()
        let overlayPanelController = OverlayPanelController(viewModel: viewModel)
        let statusMenuController = StatusMenuController(
            viewModel: viewModel,
            overlayPanelController: overlayPanelController
        )

        self.viewModel = viewModel
        self.overlayPanelController = overlayPanelController
        self.statusMenuController = statusMenuController

        overlayPanelController.showOrHideForCurrentState()
        Task {
            await viewModel.refresh()
        }
    }
}
