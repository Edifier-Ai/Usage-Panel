import CoreGraphics

public struct OverlayScreen: Equatable, Sendable {
    public var id: UInt32
    public var frame: CGRect
    public var isBuiltIn: Bool
    public var isMain: Bool

    public init(
        id: UInt32,
        frame: CGRect,
        isBuiltIn: Bool,
        isMain: Bool
    ) {
        self.id = id
        self.frame = frame
        self.isBuiltIn = isBuiltIn
        self.isMain = isMain
    }
}

public enum OverlayScreenSelector {
    public static func preferredScreen(from screens: [OverlayScreen]) -> OverlayScreen? {
        screens.first(where: \.isBuiltIn)
            ?? screens.first(where: \.isMain)
            ?? screens.first
    }
}
