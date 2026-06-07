import AppKit
import CodexIslandUsageCore
import Combine
import SwiftUI

@MainActor
final class OverlayPanelController {
    private let viewModel: WidgetViewModel
    private let panel: NSPanel
    private let layout = OverlayLayout()
    private var cancellables = Set<AnyCancellable>()
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    init(viewModel: WidgetViewModel) {
        self.viewModel = viewModel
        self.panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        observeState()
        installOutsideClickCollapse()
    }

    func showOrHideForCurrentState() {
        if viewModel.settings.isHidden {
            panel.orderOut(nil)
        } else {
            reposition()
            panel.orderFrontRegardless()
        }
    }

    func reposition() {
        guard let screen = NSScreen.main else {
            return
        }

        panel.setFrame(
            layout.frame(in: screen.frame, isExpanded: viewModel.isExpanded),
            display: true,
            animate: false
        )
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: RootWidgetView(viewModel: viewModel))
    }

    private func observeState() {
        viewModel.$isExpanded
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.showOrHideForCurrentState()
                }
            }
            .store(in: &cancellables)

        viewModel.$settings
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.showOrHideForCurrentState()
                }
            }
            .store(in: &cancellables)
    }

    private func installOutsideClickCollapse() {
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.collapseIfClickIsOutsidePanel()
            }
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.collapseIfClickIsOutsidePanel()
            }
            return event
        }
    }

    private func collapseIfClickIsOutsidePanel() {
        guard viewModel.isExpanded else {
            return
        }

        if !panel.frame.contains(NSEvent.mouseLocation) {
            viewModel.collapse()
        }
    }
}
