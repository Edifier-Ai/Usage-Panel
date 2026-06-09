import CoreGraphics

public struct OverlayLayout: Equatable, Sendable {
    public var notchWidth: Double
    public var defaultHeight: Double
    public var expandedWidth: Double
    public var expandedHeight: Double
    public var topOffset: Double

    public init(
        notchWidth: Double = 118,
        defaultHeight: Double = 13,
        expandedWidth: Double = 292,
        expandedHeight: Double = 304,
        topOffset: Double = 31
    ) {
        self.notchWidth = notchWidth
        self.defaultHeight = defaultHeight
        self.expandedWidth = expandedWidth
        self.expandedHeight = expandedHeight
        self.topOffset = topOffset
    }

    public var hostedContentWidth: Double {
        expandedWidth
    }

    public var popoverGap: Double {
        12
    }

    public var popoverPanelHeight: Double {
        expandedHeight - defaultHeight - popoverGap
    }

    public func hostedContentHeight(isExpanded: Bool) -> Double {
        isExpanded ? expandedHeight : defaultHeight
    }

    public var defaultCapsuleHitRect: CGRect {
        CGRect(
            x: (expandedWidth - notchWidth) / 2,
            y: 0,
            width: notchWidth,
            height: defaultHeight
        )
    }

    public func defaultCapsuleFrame(in panelFrame: CGRect) -> CGRect {
        defaultCapsuleHitRect.offsetBy(dx: panelFrame.minX, dy: panelFrame.minY)
    }

    public func defaultCapsuleClickFrame(in panelFrame: CGRect) -> CGRect {
        defaultCapsuleFrame(in: panelFrame)
    }

    public func frame(in screenFrame: CGRect, isExpanded: Bool) -> CGRect {
        let width = expandedWidth
        let height = isExpanded ? expandedHeight : defaultHeight
        let x = screenFrame.midX - (width / 2)
        let y = screenFrame.maxY - topOffset - height

        return CGRect(x: x, y: y, width: width, height: height)
    }

    public func defaultPanelFrame(in screenFrame: CGRect) -> CGRect {
        frame(in: screenFrame, isExpanded: false)
    }

    public func popoverPanelFrame(in screenFrame: CGRect) -> CGRect {
        let defaultFrame = defaultPanelFrame(in: screenFrame)
        return CGRect(
            x: defaultFrame.minX,
            y: defaultFrame.minY - popoverGap - popoverPanelHeight,
            width: expandedWidth,
            height: popoverPanelHeight
        )
    }
}
