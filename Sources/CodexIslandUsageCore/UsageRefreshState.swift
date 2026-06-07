import Foundation

public enum UsageRefreshState: String, Equatable, Sendable {
    case normal
    case soon
    case urgent
}

public enum UsageColorPolicy {
    public static func state(refreshDate: Date, now: Date) -> UsageRefreshState {
        let remaining = refreshDate.timeIntervalSince(now)

        if remaining < 60 * 60 {
            return .urgent
        }

        if remaining < 3 * 60 * 60 {
            return .soon
        }

        return .normal
    }
}
