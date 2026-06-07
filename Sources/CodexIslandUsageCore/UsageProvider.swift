import Foundation

public protocol UsageProviding: Sendable {
    func currentUsage(now: Date) async throws -> UsageSnapshot
}

public struct MockUsageProvider: UsageProviding {
    private let snapshotBuilder: @Sendable (Date) -> UsageSnapshot

    public init(snapshotBuilder: @escaping @Sendable (Date) -> UsageSnapshot = { UsageSnapshot.demo(now: $0) }) {
        self.snapshotBuilder = snapshotBuilder
    }

    public func currentUsage(now: Date) async throws -> UsageSnapshot {
        snapshotBuilder(now)
    }
}
