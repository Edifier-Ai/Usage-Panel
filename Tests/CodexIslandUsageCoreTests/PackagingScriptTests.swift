import Foundation
import XCTest

final class PackagingScriptTests: XCTestCase {
    func testPackagingScriptsDefaultToNextPatchVersion() throws {
        let repoRoot = Self.repoRoot()
        let packageApp = try String(contentsOf: repoRoot.appendingPathComponent("script/package_app.sh"))
        let packageDMG = try String(contentsOf: repoRoot.appendingPathComponent("script/package_dmg.sh"))

        XCTAssertTrue(packageApp.contains("VERSION=\"${VERSION:-0.1.6}\""))
        XCTAssertTrue(packageApp.contains("BUILD_NUMBER=\"${BUILD_NUMBER:-7}\""))
        XCTAssertTrue(packageDMG.contains("VERSION=\"${VERSION:-0.1.6}\""))
        XCTAssertTrue(packageDMG.contains("BUILD_NUMBER=\"${BUILD_NUMBER:-7}\""))
    }

    func testPackagingScriptsUseUsagePanelDisplayName() throws {
        let repoRoot = Self.repoRoot()
        let packageApp = try String(contentsOf: repoRoot.appendingPathComponent("script/package_app.sh"))
        let packageDMG = try String(contentsOf: repoRoot.appendingPathComponent("script/package_dmg.sh"))

        XCTAssertTrue(packageApp.contains("APP_NAME=\"${APP_NAME:-Usage Panel}\""))
        XCTAssertTrue(packageApp.contains("<string>$APP_NAME</string>"))
        XCTAssertTrue(packageDMG.contains("VOLUME_NAME=\"${VOLUME_NAME:-Usage Panel}\""))
    }

    func testAppPackagingIncludesApplicationIcon() throws {
        let repoRoot = Self.repoRoot()
        let packageApp = try String(contentsOf: repoRoot.appendingPathComponent("script/package_app.sh"))
        let icon = repoRoot.appendingPathComponent("Assets/AppIcon.icns")

        XCTAssertTrue(FileManager.default.fileExists(atPath: icon.path))
        XCTAssertTrue(packageApp.contains("APP_ICON_NAME=\"AppIcon\""))
        XCTAssertTrue(packageApp.contains("<key>CFBundleIconFile</key>"))
        XCTAssertTrue(packageApp.contains("<string>$APP_ICON_NAME</string>"))
        XCTAssertTrue(packageApp.contains("cp \"$APP_ICON\" \"$APP_RESOURCES/$APP_ICON_NAME.icns\""))
    }

    func testFinalAppBundleXattrsAreClearedBeforeVerification() throws {
        let repoRoot = Self.repoRoot()
        let packageApp = try String(contentsOf: repoRoot.appendingPathComponent("script/package_app.sh"))

        XCTAssertTrue(packageApp.contains("clear_bundle_detritus \"$FINAL_APP_BUNDLE\""))
        XCTAssertTrue(packageApp.contains("verify_clean_app_copy \"$FINAL_APP_BUNDLE\""))
        XCTAssertTrue(packageApp.contains("codesign --verify --deep --strict --verbose=2 \"$verify_bundle\""))
        XCTAssertTrue(packageApp.contains("xattr -d com.apple.FinderInfo \"$bundle\""))
        XCTAssertTrue(packageApp.contains("xattr -d 'com.apple.fileprovider.fpfs#P' \"$bundle\""))
    }

    func testDMGPackagingLeavesAppBundleCleanAfterGatekeeperAssessment() throws {
        let repoRoot = Self.repoRoot()
        let packageDMG = try String(contentsOf: repoRoot.appendingPathComponent("script/package_dmg.sh"))

        XCTAssertTrue(packageDMG.contains("clear_bundle_detritus \"$APP_BUNDLE\""))
        XCTAssertTrue(packageDMG.contains("verify_clean_app_copy \"$APP_BUNDLE\""))
        XCTAssertTrue(packageDMG.contains("codesign --verify --deep --strict --verbose=2 \"$verify_bundle\""))
    }

    func testDMGStagingUsesTemporaryDirectoryAwayFromWorkspaceMetadata() throws {
        let repoRoot = Self.repoRoot()
        let packageDMG = try String(contentsOf: repoRoot.appendingPathComponent("script/package_dmg.sh"))

        XCTAssertTrue(packageDMG.contains("DMG_STAGING=\"$(mktemp -d"))
        XCTAssertTrue(packageDMG.contains("trap cleanup EXIT"))
        XCTAssertFalse(packageDMG.contains("DMG_STAGING=\"$DIST_DIR/dmg-staging\""))
    }

    private static func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
