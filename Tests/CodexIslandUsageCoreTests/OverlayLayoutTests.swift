import CoreGraphics
import XCTest
@testable import CodexIslandUsageCore

final class OverlayLayoutTests: XCTestCase {
    func testDefaultFrameIsCenteredUnderScreenTop() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let frame = layout.frame(in: screenFrame, isExpanded: false)

        XCTAssertEqual(frame, CGRect(x: 574, y: 856, width: 292, height: 13))
    }

    func testExpandedFrameKeepsSameHorizontalPosition() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let defaultFrame = layout.frame(in: screenFrame, isExpanded: false)
        let frame = layout.frame(in: screenFrame, isExpanded: true)

        XCTAssertEqual(frame, CGRect(x: 574, y: 609, width: 292, height: 260))
        XCTAssertEqual(frame.minX, defaultFrame.minX)
        XCTAssertEqual(frame.width, defaultFrame.width)
    }

    func testDefaultPanelFrameStaysSmallWhenExpandedPopoverIsShownSeparately() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        XCTAssertEqual(layout.defaultPanelFrame(in: screenFrame), CGRect(x: 574, y: 856, width: 292, height: 13))
    }

    func testPopoverPanelFrameSitsBelowDefaultPanel() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 304, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        XCTAssertEqual(layout.popoverPanelFrame(in: screenFrame), CGRect(x: 574, y: 565, width: 292, height: 279))
    }

    func testHostedContentWidthStaysStableToAvoidSideJump() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)

        XCTAssertEqual(layout.hostedContentWidth, 292)
    }

    func testHostedContentHeightMatchesCurrentPanelState() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 304, topOffset: 31)

        XCTAssertEqual(layout.hostedContentHeight(isExpanded: false), 13)
        XCTAssertEqual(layout.hostedContentHeight(isExpanded: true), 304)
        XCTAssertEqual(layout.popoverPanelHeight, 279)
    }

    func testDefaultCapsuleHitRectIsCenteredInStablePanelWidth() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)

        XCTAssertEqual(layout.defaultCapsuleHitRect, CGRect(x: 87, y: 0, width: 118, height: 13))
    }

    func testDefaultCapsuleFrameIsOffsetInsidePanelFrame() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let panelFrame = CGRect(x: 610, y: 936, width: 292, height: 13)

        XCTAssertEqual(layout.defaultCapsuleFrame(in: panelFrame), CGRect(x: 697, y: 936, width: 118, height: 13))
    }

    func testDefaultClickFrameMatchesVisibleCapsuleInsteadOfTransparentPanelWidth() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 304, topOffset: 31)
        let panelFrame = CGRect(x: 574, y: 856, width: 292, height: 13)

        XCTAssertEqual(layout.defaultCapsuleClickFrame(in: panelFrame), CGRect(x: 661, y: 856, width: 118, height: 13))
        XCTAssertFalse(layout.defaultCapsuleClickFrame(in: panelFrame).contains(CGPoint(x: 600, y: 862)))
        XCTAssertTrue(layout.defaultCapsuleClickFrame(in: panelFrame).contains(CGPoint(x: 720, y: 862)))
    }

    func testScreenSelectionPrefersBuiltInDisplayOverMainDisplay() {
        let external = OverlayScreen(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
            isBuiltIn: false,
            isMain: true
        )
        let builtIn = OverlayScreen(
            id: 2,
            frame: CGRect(x: 2560, y: 0, width: 1512, height: 982),
            isBuiltIn: true,
            isMain: false
        )

        let selected = OverlayScreenSelector.preferredScreen(from: [external, builtIn])

        XCTAssertEqual(selected, builtIn)
    }

    func testScreenSelectionFallsBackToMainWhenNoBuiltInDisplayExists() {
        let secondary = OverlayScreen(
            id: 1,
            frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080),
            isBuiltIn: false,
            isMain: false
        )
        let main = OverlayScreen(
            id: 2,
            frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
            isBuiltIn: false,
            isMain: true
        )

        let selected = OverlayScreenSelector.preferredScreen(from: [secondary, main])

        XCTAssertEqual(selected, main)
    }
}
