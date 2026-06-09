import AppKit
import CodexIslandUsageCore
import Combine
import SwiftUI

@MainActor
final class OverlayPanelController {
    private let viewModel: WidgetViewModel
    private let panel: NSPanel
    private let popoverPanel: NSPanel
    private let layout = OverlayLayout()
    private var cancellables = Set<AnyCancellable>()
    nonisolated(unsafe) private var globalEventMonitor: Any?
    nonisolated(unsafe) private var localEventMonitor: Any?
    nonisolated(unsafe) private var screenObserver: Any?

    init(viewModel: WidgetViewModel) {
        self.viewModel = viewModel
        self.panel = OverlayPanel(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.popoverPanel = OverlayPanel(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        configurePopoverPanel()
        applyAppearance(viewModel.settings.appearanceMode)
        observeState()
        installOutsideClickCollapse()
        observeScreenChanges()
    }

    deinit {
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
        }
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    func showOrHideForCurrentState() {
        showOrHide(isHidden: viewModel.settings.isHidden, isExpanded: viewModel.isExpanded)
    }

    private func showOrHide(isHidden: Bool, isExpanded: Bool) {
        if isHidden {
            panel.orderOut(nil)
            popoverPanel.orderOut(nil)
        } else {
            reposition()
            panel.makeKeyAndOrderFront(nil)
            if isExpanded {
                showPopover()
            } else {
                popoverPanel.orderOut(nil)
            }
        }
    }

    func reposition() {
        guard let screen = preferredOverlayScreen() else {
            return
        }

        panel.setFrame(
            layout.defaultPanelFrame(in: screen.frame),
            display: true,
            animate: false
        )

        popoverPanel.setFrame(
            layout.popoverPanelFrame(in: screen.frame),
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
        panel.becomesKeyOnlyIfNeeded = true
        panel.acceptsMouseMovedEvents = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let hostingView = OverlayHostingView(rootView: RootWidgetView(viewModel: viewModel))
        hostingView.onMouseDown = { [weak self] point in
            self?.handlePanelMouseDown(at: point)
        }
        let containerView = OverlayContainerView(layout: layout)
        containerView.onPanelClick = { [weak self] in
            self?.viewModel.expand()
        }
        containerView.host(hostingView)
        panel.contentView = containerView
    }

    private func configurePopoverPanel() {
        popoverPanel.isOpaque = false
        popoverPanel.backgroundColor = .clear
        popoverPanel.hasShadow = false
        popoverPanel.hidesOnDeactivate = false
        popoverPanel.isFloatingPanel = true
        popoverPanel.becomesKeyOnlyIfNeeded = true
        popoverPanel.acceptsMouseMovedEvents = true
        popoverPanel.level = .statusBar
        popoverPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        popoverPanel.contentView = NSHostingView(rootView: ExpandedPopoverView(viewModel: viewModel))
    }

    private func showPopover() {
        reposition()
        popoverPanel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    private func handlePanelMouseDown(at point: CGPoint) {
        guard !viewModel.isExpanded else {
            return
        }
        guard layout.defaultCapsuleHitRect.contains(point) else {
            return
        }
        viewModel.expand()
    }

    private func observeState() {
        viewModel.$isExpanded
            .sink { [weak self] isExpanded in
                MainActor.assumeIsolated {
                    guard let self else {
                        return
                    }
                    self.showOrHide(
                        isHidden: self.viewModel.settings.isHidden,
                        isExpanded: isExpanded
                    )
                }
            }
            .store(in: &cancellables)

        viewModel.$settings
            .map(\.isHidden)
            .removeDuplicates()
            .sink { [weak self] isHidden in
                MainActor.assumeIsolated {
                    guard let self else {
                        return
                    }
                    self.showOrHide(
                        isHidden: isHidden,
                        isExpanded: self.viewModel.isExpanded
                    )
                }
            }
            .store(in: &cancellables)

        viewModel.$settings
            .map(\.appearanceMode)
            .removeDuplicates()
            .sink { [weak self] appearanceMode in
                MainActor.assumeIsolated {
                    self?.applyAppearance(appearanceMode)
                }
            }
            .store(in: &cancellables)

    }

    private func applyAppearance(_ appearanceMode: WidgetAppearanceMode) {
        let appearance = appearanceMode.nsAppearance
        panel.appearance = appearance
        popoverPanel.appearance = appearance
    }

    private func installOutsideClickCollapse() {
        // Expanding is already handled by the capsule hit button and the hosting
        // view's mouseDown. These monitors only need to collapse the popover when
        // a click lands outside it while expanded.
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

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.showOrHideForCurrentState()
            }
        }
    }

    private func collapseIfClickIsOutsidePanel() {
        guard viewModel.isExpanded else {
            return
        }
        if !panel.frame.contains(NSEvent.mouseLocation),
           !popoverPanel.frame.contains(NSEvent.mouseLocation) {
            viewModel.collapse()
        }
    }

    private func preferredOverlayScreen() -> NSScreen? {
        let screenPairs = NSScreen.screens.map { screen in
            (screen: screen, overlayScreen: screen.overlayScreen(isMain: screen == NSScreen.main))
        }
        let preferred = OverlayScreenSelector.preferredScreen(from: screenPairs.map(\.overlayScreen))

        return screenPairs.first { $0.overlayScreen.id == preferred?.id }?.screen
    }
}

private extension NSScreen {
    func overlayScreen(isMain: Bool) -> OverlayScreen {
        let displayID = (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0

        return OverlayScreen(
            id: displayID,
            frame: frame,
            isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
            isMain: isMain
        )
    }
}

private final class OverlayHostingView: NSHostingView<RootWidgetView> {
    var onMouseDown: ((CGPoint) -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?(convert(event.locationInWindow, from: nil))
        super.mouseDown(with: event)
    }
}

private final class OverlayContainerView: NSView {
    var onPanelClick: (() -> Void)?

    private let overlayLayout: OverlayLayout
    private let hitButton = NSButton()

    init(layout: OverlayLayout) {
        self.overlayLayout = layout
        super.init(frame: .zero)
        configureHitButton()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func host(_ hostingView: NSView) {
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView, positioned: .below, relativeTo: hitButton)
        updateHitButtonFrame()
    }

    override func layout() {
        super.layout()
        updateHitButtonFrame()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateHitButtonFrame()
    }

    private func updateHitButtonFrame() {
        hitButton.isHidden = false
        hitButton.frame = overlayLayout.defaultCapsuleHitRect
    }

    private func configureHitButton() {
        hitButton.title = ""
        hitButton.isBordered = false
        hitButton.image = nil
        hitButton.alphaValue = 0.01
        hitButton.target = self
        hitButton.action = #selector(panelClicked)
        addSubview(hitButton)
    }

    @objc private func panelClicked() {
        onPanelClick?()
    }
}

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}
