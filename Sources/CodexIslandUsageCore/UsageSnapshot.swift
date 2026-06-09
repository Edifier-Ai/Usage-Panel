import Foundation

public struct UsageSnapshot: Equatable, Sendable {
    public var fiveHourUsedFraction: Double
    public var weeklyUsedFraction: Double
    public var fiveHourRefreshDate: Date
    public var weeklyRefreshDate: Date
    public var lastUpdated: Date
    public var isFresh: Bool

    public var fiveHourRemainingPercent: Int {
        Self.remainingPercent(fromUsedFraction: fiveHourUsedFraction)
    }

    public var weeklyRemainingPercent: Int {
        Self.remainingPercent(fromUsedFraction: weeklyUsedFraction)
    }

    public func lastUpdatedAgeText(now: Date) -> String {
        let elapsed = max(0, now.timeIntervalSince(lastUpdated))

        if elapsed < 60 {
            return "刚刚"
        }

        if elapsed < 60 * 60 {
            return "\(Int(elapsed / 60)) 分钟前"
        }

        if elapsed < 24 * 60 * 60 {
            return "\(Int(elapsed / (60 * 60))) 小时前"
        }

        return "\(Int(elapsed / (24 * 60 * 60))) 天前"
    }

    public func dataFreshnessText(now: Date) -> String {
        if isFresh {
            return "数据正常 · 上次更新 \(lastUpdatedAgeText(now: now))"
        }

        return "数据已过期 · 额度变动后自动刷新 · 上次更新 \(lastUpdatedAgeText(now: now))"
    }

    public init(
        fiveHourUsedFraction: Double,
        weeklyUsedFraction: Double,
        fiveHourRefreshDate: Date,
        weeklyRefreshDate: Date,
        lastUpdated: Date,
        isFresh: Bool
    ) {
        self.fiveHourUsedFraction = Self.clamped(fiveHourUsedFraction)
        self.weeklyUsedFraction = Self.clamped(weeklyUsedFraction)
        self.fiveHourRefreshDate = fiveHourRefreshDate
        self.weeklyRefreshDate = weeklyRefreshDate
        self.lastUpdated = lastUpdated
        self.isFresh = isFresh
    }

    public static func demo(now: Date = Date()) -> UsageSnapshot {
        UsageSnapshot(
            fiveHourUsedFraction: 0.63,
            weeklyUsedFraction: 0.41,
            fiveHourRefreshDate: now.addingTimeInterval(TimeInterval((3 * 60 * 60) + (42 * 60))),
            weeklyRefreshDate: now.addingTimeInterval(TimeInterval((4 * 24 * 60 * 60) + (6 * 60 * 60))),
            lastUpdated: now,
            isFresh: true
        )
    }

    public static func loadingPlaceholder(now: Date = Date()) -> UsageSnapshot {
        UsageSnapshot(
            fiveHourUsedFraction: 0,
            weeklyUsedFraction: 0,
            fiveHourRefreshDate: now,
            weeklyRefreshDate: now,
            lastUpdated: now,
            isFresh: false
        )
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func remainingPercent(fromUsedFraction usedFraction: Double) -> Int {
        Int(((1 - clamped(usedFraction)) * 100).rounded())
    }
}
