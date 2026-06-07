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
        expandedHeight: Double = 260,
        topOffset: Double = 31
    ) {
        self.notchWidth = notchWidth
        self.defaultHeight = defaultHeight
        self.expandedWidth = expandedWidth
        self.expandedHeight = expandedHeight
        self.topOffset = topOffset
    }

    public func frame(in screenFrame: CGRect, isExpanded: Bool) -> CGRect {
        let width = isExpanded ? expandedWidth : notchWidth
        let height = isExpanded ? expandedHeight : defaultHeight
        let x = screenFrame.midX - (width / 2)
        let y = screenFrame.maxY - topOffset - height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
