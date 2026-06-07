import CodexIslandUsageCore
import SwiftUI

struct UsageRail: View {
    enum Kind {
        case fiveHour(UsageRefreshState)
        case week
    }

    let fraction: Double
    let kind: Kind

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.16))

                Capsule()
                    .fill(gradient)
                    .frame(width: proxy.size.width * clampedFraction)
            }
        }
        .frame(height: 2)
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }

    private var gradient: LinearGradient {
        switch kind {
        case .fiveHour(.normal):
            return LinearGradient(colors: [Color(red: 0.37, green: 0.94, blue: 0.64), .white], startPoint: .leading, endPoint: .trailing)
        case .fiveHour(.soon):
            return LinearGradient(colors: [Color(red: 0.36, green: 0.78, blue: 1.0), .white], startPoint: .leading, endPoint: .trailing)
        case .fiveHour(.urgent):
            return LinearGradient(colors: [Color(red: 1.0, green: 0.36, blue: 0.42), Color(red: 1.0, green: 0.97, blue: 0.98)], startPoint: .leading, endPoint: .trailing)
        case .week:
            return LinearGradient(colors: [Color.white.opacity(0.48), Color.white.opacity(0.96)], startPoint: .leading, endPoint: .trailing)
        }
    }
}
