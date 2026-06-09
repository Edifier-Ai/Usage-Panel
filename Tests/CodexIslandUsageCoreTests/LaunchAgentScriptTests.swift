import Foundation
import XCTest

final class LaunchAgentScriptTests: XCTestCase {
    func testInstallScriptCanDryRunRestartingLaunchAgentPlist() throws {
        let tempHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexIslandUsageWidgetLaunchAgentTests-\(UUID().uuidString)", isDirectory: true)
        let appBundle = tempHome.appendingPathComponent("CodexIslandUsageWidget.app", isDirectory: true)
        let executable = appBundle.appendingPathComponent("Contents/MacOS/CodexIslandUsageWidget")
        try FileManager.default.createDirectory(
            at: executable.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "#!/bin/sh\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let script = repoRoot.appendingPathComponent("script/install_login_item.sh")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script.path, appBundle.path]
        process.environment = [
            "HOME": tempHome.path,
            "LAUNCH_AGENT_DRY_RUN": "1",
            "PATH": "/bin:/usr/bin:/usr/sbin:/sbin"
        ]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0)
        let plistURL = tempHome.appendingPathComponent(
            "Library/LaunchAgents/com.codex.CodexIslandUsageWidget.launcher.plist"
        )
        let data = try Data(contentsOf: plistURL)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )

        XCTAssertEqual(plist["RunAtLoad"] as? Bool, true)
        XCTAssertEqual(plist["ThrottleInterval"] as? Int, 10)
        XCTAssertEqual(plist["LimitLoadToSessionType"] as? String, "Aqua")
        XCTAssertEqual(plist["ProgramArguments"] as? [String], [executable.path])

        let keepAlive = try XCTUnwrap(plist["KeepAlive"] as? [String: Bool])
        XCTAssertEqual(keepAlive["SuccessfulExit"], false)
        XCTAssertEqual(
            plist["StandardOutPath"] as? String,
            tempHome.appendingPathComponent("Library/Logs/CodexIslandUsageWidget/launchd.out.log").path
        )
        XCTAssertEqual(
            plist["StandardErrorPath"] as? String,
            tempHome.appendingPathComponent("Library/Logs/CodexIslandUsageWidget/launchd.err.log").path
        )
    }
}
