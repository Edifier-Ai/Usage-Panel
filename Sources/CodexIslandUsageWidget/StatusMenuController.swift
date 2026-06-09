import AppKit
import CodexIslandUsageCore

@MainActor
final class StatusMenuController: NSObject {
    private let viewModel: WidgetViewModel
    private let overlayPanelController: OverlayPanelController
    private let statusItem: NSStatusItem

    init(viewModel: WidgetViewModel, overlayPanelController: OverlayPanelController) {
        self.viewModel = viewModel
        self.overlayPanelController = overlayPanelController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureMenu()
    }

    private func configureMenu() {
        statusItem.button?.title = "Usage"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Widget", action: #selector(showWidget), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Hide Widget", action: #selector(hideWidget), keyEquivalent: "h"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { item in
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func showWidget() {
        viewModel.setHidden(false)
        overlayPanelController.showOrHideForCurrentState()
    }

    @objc private func hideWidget() {
        viewModel.setHidden(true)
        overlayPanelController.showOrHideForCurrentState()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
