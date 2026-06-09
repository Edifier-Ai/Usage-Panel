import CodexIslandUsageCore
import Foundation
import UserNotifications

@MainActor
final class StaleUsageNotificationController {
    private var notifiedLastUpdated: Date?

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyIfNeeded(snapshot: UsageSnapshot, hasLoadedUsage: Bool, isAwaitingInitialUsage: Bool, now: Date) {
        guard hasLoadedUsage else {
            return
        }

        guard !isAwaitingInitialUsage else {
            return
        }

        guard !snapshot.isFresh else {
            notifiedLastUpdated = nil
            return
        }

        guard notifiedLastUpdated != snapshot.lastUpdated else {
            return
        }

        notifiedLastUpdated = snapshot.lastUpdated

        let content = UNMutableNotificationContent()
        content.title = "Codex 用量数据已过期"
        content.body = "上次更新 \(snapshot.lastUpdatedAgeText(now: now))，请打开 Codex 产生新的用量事件。"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "codex-usage-stale-\(Int(snapshot.lastUpdated.timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
