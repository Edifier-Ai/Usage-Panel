import CoreGraphics
import XCTest
@testable import CodexIslandUsageCore

final class OverlayLayoutTests: XCTestCase {
    func testDefaultFrameIsCenteredUnderScreenTop() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let frame = layout.frame(in: screenFrame, isExpanded: false)

        XCTAssertEqual(frame, CGRect(x: 661, y: 856, width: 118, height: 13))
    }

    func testExpandedFrameKeepsSameCenter() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let frame = layout.frame(in: screenFrame, isExpanded: true)

        XCTAssertEqual(frame, CGRect(x: 574, y: 609, width: 292, height: 260))
    }
}
