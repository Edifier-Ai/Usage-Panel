import Foundation
import XCTest
@testable import CodexIslandUsageCore

final class CodexSessionUsageProviderTests: XCTestCase {
    private var codexHome: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        codexHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexSessionUsageProviderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let codexHome {
            try? FileManager.default.removeItem(at: codexHome)
        }
        try super.tearDownWithError()
    }

    func testLoadsNewestTokenCountRateLimitsFromSessionFiles() async throws {
        let sessions = codexHome.appendingPathComponent("sessions/2026/06/08", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        try writeJSONL(
            """
            {"timestamp":"2026-06-08T00:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":20.0,"window_minutes":300,"resets_at":1780840000},"secondary":{"used_percent":30.0,"window_minutes":10080,"resets_at":1781440000}}}}
            {"timestamp":"2026-06-08T01:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":64.0,"window_minutes":300,"resets_at":1780850000},"secondary":{"used_percent":42.0,"window_minutes":10080,"resets_at":1781450000}}}}
            """,
            to: sessions.appendingPathComponent("rollout.jsonl")
        )
        let provider = CodexSessionUsageProvider(
            codexHome: codexHome,
            freshnessInterval: 15 * 60
        )
        let now = date("2026-06-08T01:05:00.000Z")

        let snapshot = try await provider.currentUsage(now: now)

        XCTAssertEqual(snapshot.fiveHourUsedFraction, 0.64, accuracy: 0.0001)
        XCTAssertEqual(snapshot.weeklyUsedFraction, 0.42, accuracy: 0.0001)
        XCTAssertEqual(snapshot.fiveHourRefreshDate, Date(timeIntervalSince1970: 1_780_850_000))
        XCTAssertEqual(snapshot.weeklyRefreshDate, Date(timeIntervalSince1970: 1_781_450_000))
        XCTAssertEqual(snapshot.lastUpdated, date("2026-06-08T01:00:00.000Z"))
        XCTAssertTrue(snapshot.isFresh)
    }

    func testMarksOldTokenCountAsStale() async throws {
        let sessions = codexHome.appendingPathComponent("sessions/2026/06/08", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        try writeJSONL(
            """
            {"timestamp":"2026-06-08T00:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":20.0,"window_minutes":300,"resets_at":1780840000},"secondary":{"used_percent":30.0,"window_minutes":10080,"resets_at":1781440000}}}}
            """,
            to: sessions.appendingPathComponent("rollout.jsonl")
        )
        let provider = CodexSessionUsageProvider(
            codexHome: codexHome,
            freshnessInterval: 15 * 60
        )
        let now = date("2026-06-08T00:20:01.000Z")

        let snapshot = try await provider.currentUsage(now: now)

        XCTAssertFalse(snapshot.isFresh)
    }

    func testThrowsWhenNoTokenCountRateLimitsExist() async throws {
        let sessions = codexHome.appendingPathComponent("sessions/2026/06/08", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        try writeJSONL(
            """
            {"timestamp":"2026-06-08T00:00:00.000Z","type":"event_msg","payload":{"type":"other"}}
            """,
            to: sessions.appendingPathComponent("rollout.jsonl")
        )
        let provider = CodexSessionUsageProvider(codexHome: codexHome)

        do {
            _ = try await provider.currentUsage(now: Date())
            XCTFail("Expected missing usage data to throw")
        } catch CodexSessionUsageProvider.Error.noUsageEventsFound {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testThrowsSchemaChangedWhenLatestTokenCountLacksRateLimits() async throws {
        let sessions = codexHome.appendingPathComponent("sessions/2026/06/08", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        try writeJSONL(
            """
            {"timestamp":"2026-06-08T00:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":20.0,"window_minutes":300,"resets_at":1780840000},"secondary":{"used_percent":30.0,"window_minutes":10080,"resets_at":1781440000}}}}
            {"timestamp":"2026-06-08T01:00:00.000Z","type":"event_msg","payload":{"type":"token_count","usage":{"primary":{"used_percent":40.0}}}}
            """,
            to: sessions.appendingPathComponent("rollout.jsonl")
        )
        let provider = CodexSessionUsageProvider(codexHome: codexHome)

        do {
            _ = try await provider.currentUsage(now: Date())
            XCTFail("Expected schema change to throw")
        } catch CodexSessionUsageProvider.Error.usageSchemaChanged {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testScansRecentlyModifiedUsageLogsForPerformance() async throws {
        let sessions = codexHome.appendingPathComponent("sessions/2026/06/08", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        let staleFile = sessions.appendingPathComponent("stale.jsonl")
        let freshFile = sessions.appendingPathComponent("fresh.jsonl")
        try writeJSONL(
            """
            {"timestamp":"2026-06-08T02:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":80.0,"window_minutes":300,"resets_at":1780840000},"secondary":{"used_percent":60.0,"window_minutes":10080,"resets_at":1781440000}}}}
            """,
            to: staleFile
        )
        try writeJSONL(
            """
            {"timestamp":"2026-06-08T01:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":9.0,"window_minutes":300,"resets_at":1780850000},"secondary":{"used_percent":67.0,"window_minutes":10080,"resets_at":1781450000}}}}
            """,
            to: freshFile
        )
        try setModificationDate(date("2026-06-08T00:00:00.000Z"), for: staleFile)
        try setModificationDate(date("2026-06-08T02:30:00.000Z"), for: freshFile)
        let provider = CodexSessionUsageProvider(codexHome: codexHome, maxLogFilesToScan: 1)

        let snapshot = try await provider.currentUsage(now: date("2026-06-08T02:31:00.000Z"))

        XCTAssertEqual(snapshot.fiveHourRemainingPercent, 91)
        XCTAssertEqual(snapshot.weeklyRemainingPercent, 33)
    }

    func testReadsLatestTokenCountFromEndOfFile() async throws {
        let sessions = codexHome.appendingPathComponent("sessions/2026/06/08", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        let filler = String(
            repeating: #"{"timestamp":"2026-06-08T00:00:00.000Z","type":"event_msg","payload":{"type":"other"}}"# + "\n",
            count: 2_000
        )
        try writeJSONL(
            filler + """
            {"timestamp":"2026-06-08T01:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":25.0,"window_minutes":300,"resets_at":1780840000},"secondary":{"used_percent":50.0,"window_minutes":10080,"resets_at":1781440000}}}}
            {"timestamp":"2026-06-08T02:00:00.000Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"primary":{"used_percent":9.0,"window_minutes":300,"resets_at":1780850000},"secondary":{"used_percent":67.0,"window_minutes":10080,"resets_at":1781450000}}}}
            """,
            to: sessions.appendingPathComponent("rollout.jsonl")
        )
        let provider = CodexSessionUsageProvider(codexHome: codexHome)

        let snapshot = try await provider.currentUsage(now: date("2026-06-08T02:01:00.000Z"))

        XCTAssertEqual(snapshot.fiveHourRemainingPercent, 91)
        XCTAssertEqual(snapshot.weeklyRemainingPercent, 33)
    }

    private func writeJSONL(_ contents: String, to url: URL) throws {
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private func setModificationDate(_ date: Date, for url: URL) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }

    private func date(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)!
    }
}
