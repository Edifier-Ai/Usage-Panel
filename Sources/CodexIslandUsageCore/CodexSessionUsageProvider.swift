import Foundation

public struct CodexSessionUsageProvider: UsageProviding {
    public enum Error: Swift.Error, Equatable {
        case noUsageEventsFound
        case usageSchemaChanged
    }

    private let codexHome: URL
    private let freshnessInterval: TimeInterval
    private let maxLogFilesToScan: Int
    private let cache = UsageCandidateCache()

    public init(
        codexHome: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true),
        freshnessInterval: TimeInterval = 15 * 60,
        maxLogFilesToScan: Int = 24
    ) {
        self.codexHome = codexHome
        self.freshnessInterval = freshnessInterval
        self.maxLogFilesToScan = maxLogFilesToScan
    }

    public func currentUsage(now: Date) async throws -> UsageSnapshot {
        let files = usageLogFiles()
        let newestModifiedAt = files.first?.modifiedAt ?? .distantPast

        // The on-disk data only changes when Codex appends a new event, which
        // bumps a file's modification date. If nothing is newer than what we
        // last parsed, reuse the cached candidate and only recompute freshness
        // (which drifts with `now`) instead of re-reading every log file.
        let candidate: UsageCandidate?
        switch cache.candidate(ifNewestModifiedAtMatches: newestModifiedAt) {
        case .hit(let cached):
            candidate = cached
        case .miss:
            candidate = latestUsageCandidate(in: files.map(\.url))
            cache.store(candidate, newestModifiedAt: newestModifiedAt)
        }

        switch candidate {
        case .valid(let event):
            return UsageSnapshot(
                fiveHourUsedFraction: event.payload.rateLimits.primary.usedPercent / 100,
                weeklyUsedFraction: event.payload.rateLimits.secondary.usedPercent / 100,
                fiveHourRefreshDate: Date(timeIntervalSince1970: event.payload.rateLimits.primary.resetsAt),
                weeklyRefreshDate: Date(timeIntervalSince1970: event.payload.rateLimits.secondary.resetsAt),
                lastUpdated: event.timestamp,
                isFresh: now.timeIntervalSince(event.timestamp) <= freshnessInterval
            )
        case .malformed:
            throw Error.usageSchemaChanged
        case nil:
            throw Error.noUsageEventsFound
        }
    }

    private func latestUsageCandidate(in files: [URL]) -> UsageCandidate? {
        let decoder = JSONDecoder()
        return files
            .compactMap { latestUsageCandidate(in: $0, decoder: decoder) }
            .max { $0.timestamp < $1.timestamp }
    }

    private func usageLogFiles() -> [UsageLogFile] {
        var files: [UsageLogFile] = []

        for root in [
            codexHome.appendingPathComponent("sessions", isDirectory: true),
            codexHome.appendingPathComponent("archived_sessions", isDirectory: true)
        ] {
            let keys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                guard url.pathExtension == "jsonl" else {
                    continue
                }
                let values = try? url.resourceValues(forKeys: Set(keys))
                guard values?.isRegularFile != false else {
                    continue
                }
                files.append(UsageLogFile(url: url, modifiedAt: values?.contentModificationDate ?? .distantPast))
            }
        }

        return files
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(maxLogFilesToScan)
            .map { $0 }
    }

    private func latestUsageCandidate(in file: URL, decoder: JSONDecoder) -> UsageCandidate? {
        for line in reverseLines(in: file) {
            guard let probe = try? decoder.decode(UsageEventProbe.self, from: line),
                  probe.type == "event_msg",
                  probe.payload.type == "token_count"
            else {
                continue
            }

            if let event = try? decoder.decode(UsageEvent.self, from: line) {
                return .valid(event)
            }

            return .malformed(timestamp: probe.timestamp)
        }

        return nil
    }

    private func reverseLines(in file: URL) -> AnySequence<Data> {
        AnySequence {
            ReverseLineIterator(file: file)
        }
    }
}

private struct UsageLogFile {
    var url: URL
    var modifiedAt: Date
}

/// Caches the last parsed candidate so repeated refreshes can skip re-reading
/// every log file while nothing on disk has changed. Guarded by a lock because
/// the scheduled tick and a manual force-refresh can race.
private final class UsageCandidateCache: @unchecked Sendable {
    private let lock = NSLock()
    private var storedNewestModifiedAt: Date?
    private var storedCandidate: UsageCandidate?

    func candidate(ifNewestModifiedAtMatches newestModifiedAt: Date) -> UsageCandidateCacheLookup {
        lock.lock()
        defer { lock.unlock() }
        guard let storedNewestModifiedAt, storedNewestModifiedAt == newestModifiedAt else {
            return .miss
        }
        return .hit(storedCandidate)
    }

    func store(_ candidate: UsageCandidate?, newestModifiedAt: Date) {
        lock.lock()
        defer { lock.unlock() }
        storedNewestModifiedAt = newestModifiedAt
        storedCandidate = candidate
    }
}

private enum UsageCandidateCacheLookup {
    case hit(UsageCandidate?)
    case miss
}

private struct ReverseLineIterator: IteratorProtocol {
    private let handle: FileHandle?
    private var offset: UInt64
    private var pendingPrefix = Data()
    private var pendingLines: [Data] = []
    private var reachedStart = false

    init(file: URL) {
        self.handle = try? FileHandle(forReadingFrom: file)
        self.offset = (try? handle?.seekToEnd()) ?? 0
    }

    mutating func next() -> Data? {
        while pendingLines.isEmpty {
            guard loadPreviousChunk() else {
                try? handle?.close()
                return nil
            }
        }

        return pendingLines.removeLast()
    }

    private mutating func loadPreviousChunk() -> Bool {
        if offset == 0 {
            guard !reachedStart else {
                return false
            }
            reachedStart = true
            if pendingPrefix.isEmpty {
                return false
            }
            pendingLines = [pendingPrefix]
            pendingPrefix = Data()
            return true
        }

        let chunkSize = min(UInt64(64 * 1024), offset)
        offset -= chunkSize

        do {
            try handle?.seek(toOffset: offset)
            var data = try handle?.read(upToCount: Int(chunkSize)) ?? Data()
            data.append(pendingPrefix)

            let parts = data.split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: true)
            guard !parts.isEmpty else {
                pendingPrefix = data
                return true
            }

            if offset > 0 {
                pendingPrefix = Data(parts[0])
                pendingLines = Array(parts.dropFirst()).map { Data($0) }
            } else {
                pendingPrefix = Data()
                pendingLines = parts.map { Data($0) }
            }

            return true
        } catch {
            return false
        }
    }
}

private enum UsageCandidate {
    case valid(UsageEvent)
    case malformed(timestamp: Date)

    var timestamp: Date {
        switch self {
        case .valid(let event):
            event.timestamp
        case .malformed(let timestamp):
            timestamp
        }
    }
}

private struct UsageEventProbe: Decodable {
    var timestamp: Date
    var type: String
    var payload: PayloadProbe

    enum CodingKeys: String, CodingKey {
        case timestamp
        case type
        case payload
    }
}

private struct PayloadProbe: Decodable {
    var type: String
}

private struct UsageEvent: Decodable {
    var timestamp: Date
    var type: String
    var payload: Payload

    enum CodingKeys: String, CodingKey {
        case timestamp
        case type
        case payload
    }
}

private struct Payload: Decodable {
    var type: String
    var rateLimits: RateLimits

    enum CodingKeys: String, CodingKey {
        case type
        case rateLimits = "rate_limits"
    }
}

private struct RateLimits: Decodable {
    var primary: RateLimitWindow
    var secondary: RateLimitWindow
}

private struct RateLimitWindow: Decodable {
    var usedPercent: Double
    var resetsAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case resetsAt = "resets_at"
    }
}

private func parseCodexTimestamp(_ string: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: string)
}

private extension UsageEventProbe {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestampString = try container.decode(String.self, forKey: .timestamp)

        guard let timestamp = parseCodexTimestamp(timestampString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .timestamp,
                in: container,
                debugDescription: "Expected ISO-8601 timestamp with fractional seconds"
            )
        }

        self.timestamp = timestamp
        self.type = try container.decode(String.self, forKey: .type)
        self.payload = try container.decode(PayloadProbe.self, forKey: .payload)
    }
}

private extension UsageEvent {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestampString = try container.decode(String.self, forKey: .timestamp)

        guard let timestamp = parseCodexTimestamp(timestampString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .timestamp,
                in: container,
                debugDescription: "Expected ISO-8601 timestamp with fractional seconds"
            )
        }

        self.timestamp = timestamp
        self.type = try container.decode(String.self, forKey: .type)
        self.payload = try container.decode(Payload.self, forKey: .payload)
    }
}
