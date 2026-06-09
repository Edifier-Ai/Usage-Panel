import Foundation

public struct UsageHeartbeat: Codable, Equatable, Sendable {
    public var refreshedAt: Date
    public var sourceLastUpdated: Date
    public var fiveHourRemainingPercent: Int
    public var weeklyRemainingPercent: Int
    public var isFresh: Bool

    public init(
        refreshedAt: Date,
        sourceLastUpdated: Date,
        fiveHourRemainingPercent: Int,
        weeklyRemainingPercent: Int,
        isFresh: Bool
    ) {
        self.refreshedAt = refreshedAt
        self.sourceLastUpdated = sourceLastUpdated
        self.fiveHourRemainingPercent = fiveHourRemainingPercent
        self.weeklyRemainingPercent = weeklyRemainingPercent
        self.isFresh = isFresh
    }
}

public struct UsageHeartbeatStore: Sendable {
    public static let disabled = UsageHeartbeatStore(fileURL: nil)

    public let fileURL: URL?

    public init(fileURL: URL? = Self.defaultFileURL()) {
        self.fileURL = fileURL
    }

    public func recordSuccess(snapshot: UsageSnapshot, refreshedAt: Date) throws {
        guard let fileURL else {
            return
        }

        let heartbeat = UsageHeartbeat(
            refreshedAt: refreshedAt,
            sourceLastUpdated: snapshot.lastUpdated,
            fiveHourRemainingPercent: snapshot.fiveHourRemainingPercent,
            weeklyRemainingPercent: snapshot.weeklyRemainingPercent,
            isFresh: snapshot.isFresh
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(heartbeat)

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    public static func defaultFileURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CodexIslandUsageWidget", isDirectory: true)
            .appendingPathComponent("last_success.json")
    }
}
