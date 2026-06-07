import Foundation

public struct UsageSnapshot: Equatable, Sendable {
    public var fiveHourUsedFraction: Double
    public var weeklyUsedFraction: Double
    public var fiveHourRefreshDate: Date
    public var lastUpdated: Date
    public var isFresh: Bool

    public init(
        fiveHourUsedFraction: Double,
        weeklyUsedFraction: Double,
        fiveHourRefreshDate: Date,
        lastUpdated: Date,
        isFresh: Bool
    ) {
        self.fiveHourUsedFraction = Self.clamped(fiveHourUsedFraction)
        self.weeklyUsedFraction = Self.clamped(weeklyUsedFraction)
        self.fiveHourRefreshDate = fiveHourRefreshDate
        self.lastUpdated = lastUpdated
        self.isFresh = isFresh
    }

    public static func demo(now: Date = Date()) -> UsageSnapshot {
        UsageSnapshot(
            fiveHourUsedFraction: 0.63,
            weeklyUsedFraction: 0.41,
            fiveHourRefreshDate: now.addingTimeInterval(TimeInterval((3 * 60 * 60) + (42 * 60))),
            lastUpdated: now,
            isFresh: true
        )
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
