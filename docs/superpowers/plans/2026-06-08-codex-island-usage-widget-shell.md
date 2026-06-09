# Codex Island Usage Widget Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable native macOS prototype of the Codex notch-attached usage widget with static usage data, Liquid Glass visual shell, expandable details, appearance settings, and default weekly-quota visibility control.

**Architecture:** Use a SwiftPM macOS package with a testable core library and a small AppKit/SwiftUI executable. The core library owns data models, threshold rules, settings persistence, mock usage provider, view model, and overlay geometry; the executable owns the NSPanel overlay, status menu recovery entry, and SwiftUI views.

**Tech Stack:** Swift 6-compatible SwiftPM, macOS 14+, AppKit `NSPanel`, SwiftUI, Combine, XCTest, `UserDefaults`.

---

## Scope

This plan implements the visual shell described in `docs/superpowers/specs/2026-06-08-codex-island-usage-widget-design.md`.

Included:

- Native always-on-top notch-centered overlay.
- Ultra-thin default capsule with no text.
- Liquid Glass material treatment for capsule, popover, settings, and controls.
- 5-hour and weekly quota rails using static mock data.
- 5-hour refresh countdown color policy: urgent red, soon yellow, normal green.
- Expanded popover with usage details, last update time, appearance mode, weekly default toggle, and hide action.
- Status menu entry to restore the widget after hiding.

Excluded from this plan:

- Real Codex usage data integration.
- Distribution packaging, notarization, and auto-update.
- Exact hardware notch detection beyond a configurable notch-width constant.

## File Structure

- Create: `Package.swift`
  - Defines `CodexIslandUsageCore`, `CodexIslandUsageWidget`, and `CodexIslandUsageCoreTests`.
- Create: `.gitignore`
  - Ignores SwiftPM build output and visual brainstorming artifacts.
- Create: `Sources/CodexIslandUsageCore/UsageSnapshot.swift`
  - Usage values and demo snapshot factory.
- Create: `Sources/CodexIslandUsageCore/UsageRefreshState.swift`
  - 5-hour refresh countdown threshold policy.
- Create: `Sources/CodexIslandUsageCore/WidgetSettings.swift`
  - Appearance mode and default visibility preferences.
- Create: `Sources/CodexIslandUsageCore/WidgetSettingsStore.swift`
  - UserDefaults persistence.
- Create: `Sources/CodexIslandUsageCore/OverlayLayout.swift`
  - Testable notch-centered frame math.
- Create: `Sources/CodexIslandUsageCore/UsageProvider.swift`
  - Usage provider protocol and static mock provider.
- Create: `Sources/CodexIslandUsageCore/WidgetViewModel.swift`
  - Main actor observable state for UI.
- Create: `Tests/CodexIslandUsageCoreTests/UsageRefreshStateTests.swift`
  - Verifies color-state thresholds.
- Create: `Tests/CodexIslandUsageCoreTests/WidgetSettingsStoreTests.swift`
  - Verifies settings defaults and persistence.
- Create: `Tests/CodexIslandUsageCoreTests/OverlayLayoutTests.swift`
  - Verifies default and expanded overlay placement.
- Create: `Tests/CodexIslandUsageCoreTests/WidgetViewModelTests.swift`
  - Verifies expansion, settings mutation, hidden state, and refresh.
- Create: `Sources/CodexIslandUsageWidget/main.swift`
  - Starts as a minimal SwiftPM executable, then is replaced with the `NSApplication` entry point.
- Create: `Sources/CodexIslandUsageWidget/AppDelegate.swift`
  - Wires app lifecycle, view model, overlay, and status menu.
- Create: `Sources/CodexIslandUsageWidget/OverlayPanelController.swift`
  - Owns borderless always-on-top NSPanel and outside-click collapse.
- Create: `Sources/CodexIslandUsageWidget/StatusMenuController.swift`
  - Provides hide/show/quit recovery controls.
- Create: `Sources/CodexIslandUsageWidget/LiquidGlass.swift`
  - Shared SwiftUI Liquid Glass modifier.
- Create: `Sources/CodexIslandUsageWidget/UsageRail.swift`
  - Reusable progress rail.
- Create: `Sources/CodexIslandUsageWidget/DefaultCapsuleView.swift`
  - Ultra-thin no-text default state.
- Create: `Sources/CodexIslandUsageWidget/ExpandedPopoverView.swift`
  - Detailed usage and settings popover.
- Create: `Sources/CodexIslandUsageWidget/RootWidgetView.swift`
  - Composes default and expanded states.

---

### Task 1: Initialize Repository And SwiftPM Package

**Files:**
- Create: `.gitignore`
- Create: `Package.swift`
- Create: `Sources/CodexIslandUsageWidget/main.swift`

- [ ] **Step 1: Initialize git for frequent commits**

Run:

```bash
git init
```

Expected: output contains `Initialized empty Git repository`.

- [ ] **Step 2: Write `.gitignore`**

Create `.gitignore`:

```gitignore
.build/
.swiftpm/
.DS_Store
.superpowers/
DerivedData/
```

- [ ] **Step 3: Write `Package.swift`**

Create `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexIslandUsageWidget",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CodexIslandUsageCore",
            targets: ["CodexIslandUsageCore"]
        ),
        .executable(
            name: "CodexIslandUsageWidget",
            targets: ["CodexIslandUsageWidget"]
        )
    ],
    targets: [
        .target(
            name: "CodexIslandUsageCore"
        ),
        .executableTarget(
            name: "CodexIslandUsageWidget",
            dependencies: ["CodexIslandUsageCore"]
        ),
        .testTarget(
            name: "CodexIslandUsageCoreTests",
            dependencies: ["CodexIslandUsageCore"]
        )
    ]
)
```

- [ ] **Step 4: Write baseline executable entry point**

Create `Sources/CodexIslandUsageWidget/main.swift`:

```swift
print("CodexIslandUsageWidget package is ready.")
```

- [ ] **Step 5: Verify package graph**

Run:

```bash
swift package describe
```

Expected: output lists the `CodexIslandUsageCore` library product and `CodexIslandUsageWidget` executable product.

- [ ] **Step 6: Build baseline package**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 7: Commit**

Run:

```bash
git add .gitignore Package.swift Sources/CodexIslandUsageWidget/main.swift
git commit -m "chore: initialize macOS widget package"
```

Expected: commit succeeds.

---

### Task 2: Add Core Usage Models And Refresh Color Policy

**Files:**
- Create: `Sources/CodexIslandUsageCore/UsageSnapshot.swift`
- Create: `Sources/CodexIslandUsageCore/UsageRefreshState.swift`
- Create: `Tests/CodexIslandUsageCoreTests/UsageRefreshStateTests.swift`

- [ ] **Step 1: Write failing refresh-state tests**

Create `Tests/CodexIslandUsageCoreTests/UsageRefreshStateTests.swift`:

```swift
import Foundation
import XCTest
@testable import CodexIslandUsageCore

final class UsageRefreshStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_780_849_600)

    func testRefreshAtOrAfterThreeHoursIsNormal() {
        let refreshDate = now.addingTimeInterval(3 * 60 * 60)

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .normal
        )
    }

    func testRefreshUnderThreeHoursAndAtLeastOneHourIsSoon() {
        let refreshDate = now.addingTimeInterval((2 * 60 * 60) + (59 * 60))

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .soon
        )
    }

    func testRefreshUnderOneHourIsUrgent() {
        let refreshDate = now.addingTimeInterval((59 * 60) + 59)

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .urgent
        )
    }

    func testPastRefreshDateIsUrgent() {
        let refreshDate = now.addingTimeInterval(-60)

        XCTAssertEqual(
            UsageColorPolicy.state(refreshDate: refreshDate, now: now),
            .urgent
        )
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter UsageRefreshStateTests
```

Expected: build fails because `UsageColorPolicy` and `UsageRefreshState` do not exist.

- [ ] **Step 3: Implement `UsageSnapshot.swift`**

Create `Sources/CodexIslandUsageCore/UsageSnapshot.swift`:

```swift
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
```

- [ ] **Step 4: Implement `UsageRefreshState.swift`**

Create `Sources/CodexIslandUsageCore/UsageRefreshState.swift`:

```swift
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
```

- [ ] **Step 5: Run tests to verify pass**

Run:

```bash
swift test --filter UsageRefreshStateTests
```

Expected: all 4 tests pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/CodexIslandUsageCore Tests/CodexIslandUsageCoreTests
git commit -m "feat: add usage refresh state policy"
```

Expected: commit succeeds.

---

### Task 3: Add Settings Model And UserDefaults Store

**Files:**
- Create: `Sources/CodexIslandUsageCore/WidgetSettings.swift`
- Create: `Sources/CodexIslandUsageCore/WidgetSettingsStore.swift`
- Create: `Tests/CodexIslandUsageCoreTests/WidgetSettingsStoreTests.swift`

- [ ] **Step 1: Write failing settings-store tests**

Create `Tests/CodexIslandUsageCoreTests/WidgetSettingsStoreTests.swift`:

```swift
import Foundation
import XCTest
@testable import CodexIslandUsageCore

final class WidgetSettingsStoreTests: XCTestCase {
    private let suiteName = "CodexIslandUsageWidgetTests.SettingsStore"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testLoadReturnsDefaultSettingsWhenEmpty() {
        let store = WidgetSettingsStore(defaults: UserDefaults(suiteName: suiteName)!)

        XCTAssertEqual(store.load(), WidgetSettings())
    }

    func testSaveAndLoadRoundTripsSettings() {
        let store = WidgetSettingsStore(defaults: UserDefaults(suiteName: suiteName)!)
        let settings = WidgetSettings(
            appearanceMode: .light,
            showsWeeklyQuotaInDefault: false,
            isHidden: true
        )

        store.save(settings)

        XCTAssertEqual(store.load(), settings)
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter WidgetSettingsStoreTests
```

Expected: build fails because `WidgetSettingsStore`, `WidgetSettings`, and `WidgetAppearanceMode` do not exist.

- [ ] **Step 3: Implement `WidgetSettings.swift`**

Create `Sources/CodexIslandUsageCore/WidgetSettings.swift`:

```swift
import Foundation

public enum WidgetAppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case dark
    case light
}

public struct WidgetSettings: Equatable, Codable, Sendable {
    public var appearanceMode: WidgetAppearanceMode
    public var showsWeeklyQuotaInDefault: Bool
    public var isHidden: Bool

    public init(
        appearanceMode: WidgetAppearanceMode = .system,
        showsWeeklyQuotaInDefault: Bool = true,
        isHidden: Bool = false
    ) {
        self.appearanceMode = appearanceMode
        self.showsWeeklyQuotaInDefault = showsWeeklyQuotaInDefault
        self.isHidden = isHidden
    }
}
```

- [ ] **Step 4: Implement `WidgetSettingsStore.swift`**

Create `Sources/CodexIslandUsageCore/WidgetSettingsStore.swift`:

```swift
import Foundation

public final class WidgetSettingsStore {
    private enum Keys {
        static let appearanceMode = "CodexIslandUsageWidget.appearanceMode"
        static let showsWeeklyQuotaInDefault = "CodexIslandUsageWidget.showsWeeklyQuotaInDefault"
        static let isHidden = "CodexIslandUsageWidget.isHidden"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> WidgetSettings {
        let appearanceMode = defaults.string(forKey: Keys.appearanceMode)
            .flatMap(WidgetAppearanceMode.init(rawValue:)) ?? .system

        let showsWeeklyQuotaInDefault: Bool
        if defaults.object(forKey: Keys.showsWeeklyQuotaInDefault) == nil {
            showsWeeklyQuotaInDefault = true
        } else {
            showsWeeklyQuotaInDefault = defaults.bool(forKey: Keys.showsWeeklyQuotaInDefault)
        }

        return WidgetSettings(
            appearanceMode: appearanceMode,
            showsWeeklyQuotaInDefault: showsWeeklyQuotaInDefault,
            isHidden: defaults.bool(forKey: Keys.isHidden)
        )
    }

    public func save(_ settings: WidgetSettings) {
        defaults.set(settings.appearanceMode.rawValue, forKey: Keys.appearanceMode)
        defaults.set(settings.showsWeeklyQuotaInDefault, forKey: Keys.showsWeeklyQuotaInDefault)
        defaults.set(settings.isHidden, forKey: Keys.isHidden)
    }
}
```

- [ ] **Step 5: Run tests to verify pass**

Run:

```bash
swift test --filter WidgetSettingsStoreTests
```

Expected: both settings-store tests pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/CodexIslandUsageCore/WidgetSettings.swift Sources/CodexIslandUsageCore/WidgetSettingsStore.swift Tests/CodexIslandUsageCoreTests/WidgetSettingsStoreTests.swift
git commit -m "feat: persist widget settings"
```

Expected: commit succeeds.

---

### Task 4: Add Overlay Geometry And View Model

**Files:**
- Create: `Sources/CodexIslandUsageCore/OverlayLayout.swift`
- Create: `Sources/CodexIslandUsageCore/UsageProvider.swift`
- Create: `Sources/CodexIslandUsageCore/WidgetViewModel.swift`
- Create: `Tests/CodexIslandUsageCoreTests/OverlayLayoutTests.swift`
- Create: `Tests/CodexIslandUsageCoreTests/WidgetViewModelTests.swift`

- [ ] **Step 1: Write failing overlay layout tests**

Create `Tests/CodexIslandUsageCoreTests/OverlayLayoutTests.swift`:

```swift
import CoreGraphics
import XCTest
@testable import CodexIslandUsageCore

final class OverlayLayoutTests: XCTestCase {
    func testDefaultFrameIsCenteredUnderScreenTop() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let frame = layout.frame(in: screenFrame, isExpanded: false)

        XCTAssertEqual(frame, CGRect(x: 661, y: 856, width: 118, height: 13))
    }

    func testExpandedFrameKeepsSameCenter() {
        let layout = OverlayLayout(notchWidth: 118, defaultHeight: 13, expandedWidth: 292, expandedHeight: 260, topOffset: 31)
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let frame = layout.frame(in: screenFrame, isExpanded: true)

        XCTAssertEqual(frame, CGRect(x: 574, y: 609, width: 292, height: 260))
    }
}
```

- [ ] **Step 2: Write failing view-model tests**

Create `Tests/CodexIslandUsageCoreTests/WidgetViewModelTests.swift`:

```swift
import Foundation
import XCTest
@testable import CodexIslandUsageCore

@MainActor
final class WidgetViewModelTests: XCTestCase {
    private let suiteName = "CodexIslandUsageWidgetTests.ViewModel"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testToggleExpandedChangesExpandedState() {
        let viewModel = makeViewModel()

        viewModel.toggleExpanded()

        XCTAssertTrue(viewModel.isExpanded)
    }

    func testSettingsMutationsPersist() {
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = WidgetSettingsStore(defaults: defaults)
        let viewModel = makeViewModel(store: store)

        viewModel.setAppearanceMode(.dark)
        viewModel.setShowsWeeklyQuotaInDefault(false)
        viewModel.setHidden(true)

        XCTAssertEqual(
            store.load(),
            WidgetSettings(
                appearanceMode: .dark,
                showsWeeklyQuotaInDefault: false,
                isHidden: true
            )
        )
    }

    func testRefreshLoadsProviderSnapshot() async {
        let now = Date(timeIntervalSince1970: 1_780_849_600)
        let expected = UsageSnapshot(
            fiveHourUsedFraction: 0.2,
            weeklyUsedFraction: 0.8,
            fiveHourRefreshDate: now.addingTimeInterval(60),
            lastUpdated: now,
            isFresh: true
        )
        let viewModel = makeViewModel(
            provider: MockUsageProvider { _ in expected },
            now: now
        )

        await viewModel.refresh(now: now)

        XCTAssertEqual(viewModel.snapshot, expected)
        XCTAssertEqual(viewModel.refreshState(now: now), .urgent)
    }

    private func makeViewModel(
        provider: UsageProviding = MockUsageProvider(),
        store: WidgetSettingsStore? = nil,
        now: Date = Date(timeIntervalSince1970: 1_780_849_600)
    ) -> WidgetViewModel {
        WidgetViewModel(
            provider: provider,
            settingsStore: store ?? WidgetSettingsStore(defaults: UserDefaults(suiteName: suiteName)!),
            now: now
        )
    }
}
```

- [ ] **Step 3: Run tests to verify failure**

Run:

```bash
swift test --filter OverlayLayoutTests
swift test --filter WidgetViewModelTests
```

Expected: build fails because overlay layout, provider, and view model types do not exist.

- [ ] **Step 4: Implement `OverlayLayout.swift`**

Create `Sources/CodexIslandUsageCore/OverlayLayout.swift`:

```swift
import CoreGraphics

public struct OverlayLayout: Equatable, Sendable {
    public var notchWidth: Double
    public var defaultHeight: Double
    public var expandedWidth: Double
    public var expandedHeight: Double
    public var topOffset: Double

    public init(
        notchWidth: Double = 118,
        defaultHeight: Double = 13,
        expandedWidth: Double = 292,
        expandedHeight: Double = 260,
        topOffset: Double = 31
    ) {
        self.notchWidth = notchWidth
        self.defaultHeight = defaultHeight
        self.expandedWidth = expandedWidth
        self.expandedHeight = expandedHeight
        self.topOffset = topOffset
    }

    public func frame(in screenFrame: CGRect, isExpanded: Bool) -> CGRect {
        let width = isExpanded ? expandedWidth : notchWidth
        let height = isExpanded ? expandedHeight : defaultHeight
        let x = screenFrame.midX - (width / 2)
        let y = screenFrame.maxY - topOffset - height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
```

- [ ] **Step 5: Implement `UsageProvider.swift`**

Create `Sources/CodexIslandUsageCore/UsageProvider.swift`:

```swift
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
```

- [ ] **Step 6: Implement `WidgetViewModel.swift`**

Create `Sources/CodexIslandUsageCore/WidgetViewModel.swift`:

```swift
import Combine
import Foundation

@MainActor
public final class WidgetViewModel: ObservableObject {
    @Published public private(set) var snapshot: UsageSnapshot
    @Published public var settings: WidgetSettings {
        didSet {
            settingsStore.save(settings)
        }
    }
    @Published public private(set) var isExpanded: Bool

    private let provider: UsageProviding
    private let settingsStore: WidgetSettingsStore

    public init(
        provider: UsageProviding = MockUsageProvider(),
        settingsStore: WidgetSettingsStore = WidgetSettingsStore(),
        now: Date = Date()
    ) {
        self.provider = provider
        self.settingsStore = settingsStore
        self.settings = settingsStore.load()
        self.snapshot = UsageSnapshot.demo(now: now)
        self.isExpanded = false
    }

    public func refresh(now: Date = Date()) async {
        if let nextSnapshot = try? await provider.currentUsage(now: now) {
            snapshot = nextSnapshot
        }
    }

    public func toggleExpanded() {
        isExpanded.toggle()
    }

    public func collapse() {
        isExpanded = false
    }

    public func setAppearanceMode(_ mode: WidgetAppearanceMode) {
        settings.appearanceMode = mode
    }

    public func setShowsWeeklyQuotaInDefault(_ value: Bool) {
        settings.showsWeeklyQuotaInDefault = value
    }

    public func setHidden(_ hidden: Bool) {
        settings.isHidden = hidden
        if hidden {
            collapse()
        }
    }

    public func refreshState(now: Date = Date()) -> UsageRefreshState {
        UsageColorPolicy.state(refreshDate: snapshot.fiveHourRefreshDate, now: now)
    }
}
```

- [ ] **Step 7: Run tests to verify pass**

Run:

```bash
swift test --filter OverlayLayoutTests
swift test --filter WidgetViewModelTests
swift test
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

Run:

```bash
git add Sources/CodexIslandUsageCore Tests/CodexIslandUsageCoreTests
git commit -m "feat: add widget state and overlay layout"
```

Expected: commit succeeds.

---

### Task 5: Build Liquid Glass Default Capsule UI

**Files:**
- Create: `Sources/CodexIslandUsageWidget/LiquidGlass.swift`
- Create: `Sources/CodexIslandUsageWidget/UsageRail.swift`
- Create: `Sources/CodexIslandUsageWidget/DefaultCapsuleView.swift`

- [ ] **Step 1: Create shared Liquid Glass modifier**

Create `Sources/CodexIslandUsageWidget/LiquidGlass.swift`:

```swift
import SwiftUI

enum GlassProminence {
    case capsule
    case popover
    case control
}

struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let prominence: GlassProminence

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(tintColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(topHighlight)
                    .frame(height: 1)
                    .padding(.horizontal, prominence == .capsule ? 9 : 14)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }

    private var tintColor: Color {
        switch (colorScheme, prominence) {
        case (.light, .capsule):
            return Color.white.opacity(0.22)
        case (.light, .popover):
            return Color.white.opacity(0.30)
        case (.light, .control):
            return Color.white.opacity(0.18)
        case (.dark, .capsule):
            return Color.white.opacity(0.10)
        case (.dark, .popover):
            return Color.white.opacity(0.12)
        case (.dark, .control):
            return Color.white.opacity(0.09)
        @unknown default:
            return Color.white.opacity(0.12)
        }
    }

    private var borderColor: Color {
        colorScheme == .light ? Color.white.opacity(0.42) : Color.white.opacity(0.20)
    }

    private var topHighlight: Color {
        colorScheme == .light ? Color.white.opacity(0.72) : Color.white.opacity(0.52)
    }

    private var shadowColor: Color {
        colorScheme == .light ? Color.black.opacity(0.14) : Color.black.opacity(0.38)
    }

    private var shadowRadius: CGFloat {
        prominence == .capsule ? 18 : 36
    }

    private var shadowY: CGFloat {
        prominence == .capsule ? 6 : 18
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat, prominence: GlassProminence) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, prominence: prominence))
    }
}
```

- [ ] **Step 2: Create progress rail component**

Create `Sources/CodexIslandUsageWidget/UsageRail.swift`:

```swift
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
            return LinearGradient(colors: [Color(red: 1.0, green: 0.84, blue: 0.28), .white], startPoint: .leading, endPoint: .trailing)
        case .fiveHour(.urgent):
            return LinearGradient(colors: [Color(red: 1.0, green: 0.36, blue: 0.42), .white], startPoint: .leading, endPoint: .trailing)
        case .week:
            return LinearGradient(colors: [Color.white.opacity(0.48), Color.white.opacity(0.96)], startPoint: .leading, endPoint: .trailing)
        }
    }
}
```

- [ ] **Step 3: Create no-text default capsule**

Create `Sources/CodexIslandUsageWidget/DefaultCapsuleView.swift`:

```swift
import CodexIslandUsageCore
import SwiftUI

struct DefaultCapsuleView: View {
    let snapshot: UsageSnapshot
    let settings: WidgetSettings
    let refreshState: UsageRefreshState

    var body: some View {
        HStack(spacing: 5) {
            UsageRail(
                fraction: snapshot.fiveHourUsedFraction,
                kind: .fiveHour(refreshState)
            )

            if settings.showsWeeklyQuotaInDefault {
                UsageRail(
                    fraction: snapshot.weeklyUsedFraction,
                    kind: .week
                )
            }

            Circle()
                .fill(snapshot.isFresh ? Color(red: 0.54, green: 0.96, blue: 0.74) : Color.white.opacity(0.38))
                .frame(width: 3, height: 3)
                .shadow(color: snapshot.isFresh ? Color(red: 0.54, green: 0.96, blue: 0.74).opacity(0.8) : .clear, radius: 5)
        }
        .padding(.horizontal, 8)
        .frame(width: 118, height: 13)
        .liquidGlass(cornerRadius: 6.5, prominence: .capsule)
    }
}
```

- [ ] **Step 4: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

Run:

```bash
git add Sources/CodexIslandUsageWidget/LiquidGlass.swift Sources/CodexIslandUsageWidget/UsageRail.swift Sources/CodexIslandUsageWidget/DefaultCapsuleView.swift
git commit -m "feat: add liquid glass default capsule"
```

Expected: commit succeeds.

---

### Task 6: Add Expanded Popover And Root SwiftUI Composition

**Files:**
- Create: `Sources/CodexIslandUsageWidget/ExpandedPopoverView.swift`
- Create: `Sources/CodexIslandUsageWidget/RootWidgetView.swift`

- [ ] **Step 1: Create expanded popover view**

Create `Sources/CodexIslandUsageWidget/ExpandedPopoverView.swift`:

```swift
import CodexIslandUsageCore
import SwiftUI

struct ExpandedPopoverView: View {
    @ObservedObject var viewModel: WidgetViewModel
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Codex Usage")
                .font(.system(size: 12, weight: .semibold))

            metricBlock(
                title: "5 小时额度",
                value: "\(Int(viewModel.snapshot.fiveHourUsedFraction * 100))% used",
                detailTitle: "刷新倒计时",
                detailValue: refreshCountdownText,
                rail: UsageRail(
                    fraction: viewModel.snapshot.fiveHourUsedFraction,
                    kind: .fiveHour(viewModel.refreshState(now: now))
                )
            )

            metricBlock(
                title: "本周额度",
                value: "\(Int(viewModel.snapshot.weeklyUsedFraction * 100))% used",
                detailTitle: "数据更新",
                detailValue: lastUpdatedText,
                rail: UsageRail(
                    fraction: viewModel.snapshot.weeklyUsedFraction,
                    kind: .week
                )
            )

            Divider().opacity(0.25)

            HStack {
                Text("外观")
                    .font(.system(size: 11))
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.settings.appearanceMode },
                    set: { viewModel.setAppearanceMode($0) }
                )) {
                    Text("系统").tag(WidgetAppearanceMode.system)
                    Text("暗").tag(WidgetAppearanceMode.dark)
                    Text("亮").tag(WidgetAppearanceMode.light)
                }
                .pickerStyle(.segmented)
                .frame(width: 126)
            }

            HStack {
                Text("默认态显示周额度")
                    .font(.system(size: 11))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.settings.showsWeeklyQuotaInDefault },
                    set: { viewModel.setShowsWeeklyQuotaInDefault($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            Button("隐藏") {
                viewModel.setHidden(true)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding(13)
        .frame(width: 292)
        .liquidGlass(cornerRadius: 20, prominence: .popover)
    }

    private func metricBlock(
        title: String,
        value: String,
        detailTitle: String,
        detailValue: String,
        rail: UsageRail
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
            }

            rail

            HStack {
                Text(detailTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(detailValue)
                    .font(.system(size: 11, weight: .semibold))
            }
        }
    }

    private var refreshCountdownText: String {
        let remaining = max(0, viewModel.snapshot.fiveHourRefreshDate.timeIntervalSince(now))
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private var lastUpdatedText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: viewModel.snapshot.lastUpdated)
    }
}
```

- [ ] **Step 2: Create root composition view**

Create `Sources/CodexIslandUsageWidget/RootWidgetView.swift`:

```swift
import CodexIslandUsageCore
import SwiftUI

struct RootWidgetView: View {
    @ObservedObject var viewModel: WidgetViewModel

    var body: some View {
        VStack(spacing: 12) {
            if !viewModel.settings.isHidden {
                DefaultCapsuleView(
                    snapshot: viewModel.snapshot,
                    settings: viewModel.settings,
                    refreshState: viewModel.refreshState()
                )
                .onTapGesture {
                    viewModel.toggleExpanded()
                }

                if viewModel.isExpanded {
                    ExpandedPopoverView(viewModel: viewModel, now: Date())
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(width: viewModel.isExpanded ? 292 : 118, alignment: .top)
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: viewModel.isExpanded)
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: viewModel.settings.showsWeeklyQuotaInDefault)
    }
}
```

- [ ] **Step 3: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

Run:

```bash
git add Sources/CodexIslandUsageWidget/ExpandedPopoverView.swift Sources/CodexIslandUsageWidget/RootWidgetView.swift
git commit -m "feat: add expanded usage popover"
```

Expected: commit succeeds.

---

### Task 7: Add Native Overlay Panel, Status Menu, And App Entry Point

**Files:**
- Modify: `Sources/CodexIslandUsageWidget/main.swift`
- Create: `Sources/CodexIslandUsageWidget/AppDelegate.swift`
- Create: `Sources/CodexIslandUsageWidget/OverlayPanelController.swift`
- Create: `Sources/CodexIslandUsageWidget/StatusMenuController.swift`

- [ ] **Step 1: Create overlay panel controller**

Create `Sources/CodexIslandUsageWidget/OverlayPanelController.swift`:

```swift
import AppKit
import CodexIslandUsageCore
import Combine
import SwiftUI

@MainActor
final class OverlayPanelController {
    private let viewModel: WidgetViewModel
    private let panel: NSPanel
    private let layout = OverlayLayout()
    private var cancellables = Set<AnyCancellable>()
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    init(viewModel: WidgetViewModel) {
        self.viewModel = viewModel
        self.panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        observeState()
        installOutsideClickCollapse()
    }

    func showOrHideForCurrentState() {
        if viewModel.settings.isHidden {
            panel.orderOut(nil)
        } else {
            reposition()
            panel.orderFrontRegardless()
        }
    }

    func reposition() {
        guard let screen = NSScreen.main else {
            return
        }

        panel.setFrame(
            layout.frame(in: screen.frame, isExpanded: viewModel.isExpanded),
            display: true,
            animate: false
        )
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = NSHostingView(rootView: RootWidgetView(viewModel: viewModel))
    }

    private func observeState() {
        viewModel.$isExpanded
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.showOrHideForCurrentState()
                }
            }
            .store(in: &cancellables)

        viewModel.$settings
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.showOrHideForCurrentState()
                }
            }
            .store(in: &cancellables)
    }

    private func installOutsideClickCollapse() {
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.collapseIfClickIsOutsidePanel()
            }
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.collapseIfClickIsOutsidePanel()
            }
            return event
        }
    }

    private func collapseIfClickIsOutsidePanel() {
        guard viewModel.isExpanded else {
            return
        }

        if !panel.frame.contains(NSEvent.mouseLocation) {
            viewModel.collapse()
        }
    }
}
```

- [ ] **Step 2: Create status menu controller**

Create `Sources/CodexIslandUsageWidget/StatusMenuController.swift`:

```swift
import AppKit
import CodexIslandUsageCore

@MainActor
final class StatusMenuController: NSObject {
    private let viewModel: WidgetViewModel
    private let overlayPanelController: OverlayPanelController
    private let statusItem: NSStatusItem

    init(viewModel: WidgetViewModel, overlayPanelController: OverlayPanelController) {
        self.viewModel = viewModel
        self.overlayPanelController = overlayPanelController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureMenu()
    }

    private func configureMenu() {
        statusItem.button?.title = "Codex"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Widget", action: #selector(showWidget), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Hide Widget", action: #selector(hideWidget), keyEquivalent: "h"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { item in
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func showWidget() {
        viewModel.setHidden(false)
        overlayPanelController.showOrHideForCurrentState()
    }

    @objc private func hideWidget() {
        viewModel.setHidden(true)
        overlayPanelController.showOrHideForCurrentState()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
```

- [ ] **Step 3: Create app delegate**

Create `Sources/CodexIslandUsageWidget/AppDelegate.swift`:

```swift
import AppKit
import CodexIslandUsageCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var viewModel: WidgetViewModel?
    private var overlayPanelController: OverlayPanelController?
    private var statusMenuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let viewModel = WidgetViewModel()
        let overlayPanelController = OverlayPanelController(viewModel: viewModel)
        let statusMenuController = StatusMenuController(
            viewModel: viewModel,
            overlayPanelController: overlayPanelController
        )

        self.viewModel = viewModel
        self.overlayPanelController = overlayPanelController
        self.statusMenuController = statusMenuController

        overlayPanelController.showOrHideForCurrentState()
        Task {
            await viewModel.refresh()
        }
    }
}
```

- [ ] **Step 4: Replace executable entry point**

Replace `Sources/CodexIslandUsageWidget/main.swift` with:

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 5: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 6: Run the app**

Run:

```bash
swift run CodexIslandUsageWidget
```

Expected: a tiny no-text Liquid Glass capsule appears centered under the MacBook notch or top screen center. The menu bar shows `Codex`.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/CodexIslandUsageWidget
git commit -m "feat: add native overlay shell"
```

Expected: commit succeeds.

---

### Task 8: Manual Product QA And Polish Pass

**Files:**
- Modify: files created in `Sources/CodexIslandUsageWidget/` only if QA reveals sizing, contrast, or interaction issues.
- Modify: files created in `Sources/CodexIslandUsageCore/` only if QA reveals a tested state-rule issue.

- [ ] **Step 1: Run full test suite**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 2: Launch the prototype**

Run:

```bash
swift run CodexIslandUsageWidget
```

Expected: app stays running, default capsule is visible, and the status menu exists.

- [ ] **Step 3: Verify default-state requirements**

Inspect the running app and confirm:

```text
Default capsule has no text.
Default capsule width visually matches the notch width.
Default capsule height is extremely short.
Default capsule shows 5-hour rail, weekly rail when enabled, and freshness dot.
Default capsule uses translucent Liquid Glass material instead of a solid black card.
```

- [ ] **Step 4: Verify expanded-state requirements**

Click the default capsule and confirm:

```text
Popover opens beneath the notch.
Popover displays 5-hour usage percentage.
Popover displays 5-hour refresh countdown.
Popover displays weekly usage percentage.
Popover displays last updated time.
Popover includes System, Dark, and Light appearance options.
Popover includes the default weekly quota visibility toggle.
Clicking outside the popover collapses it.
```

- [ ] **Step 5: Verify weekly default toggle**

In the expanded popover:

```text
Turn off 默认态显示周额度.
Close the popover.
Confirm the default capsule only shows the 5-hour rail and freshness dot.
Open the popover again.
Confirm weekly usage remains visible in the popover.
Turn on 默认态显示周额度.
Confirm the default capsule shows both rails.
```

- [ ] **Step 6: Verify hide and restore**

In the expanded popover and menu bar:

```text
Click 隐藏 in the popover.
Confirm the overlay disappears.
Open the Codex menu bar item.
Click Show Widget.
Confirm the overlay reappears.
Click Hide Widget.
Confirm the overlay disappears.
Click Show Widget.
Confirm the overlay reappears.
```

- [ ] **Step 7: Verify appearance modes**

In the expanded popover:

```text
Select 系统.
Confirm the app follows current macOS appearance.
Select 暗.
Confirm the material becomes dark while remaining translucent.
Select 亮.
Confirm the material becomes light while remaining translucent.
```

If the view does not visually change when selecting modes, modify `RootWidgetView.swift` to apply a preferred color scheme:

```swift
.preferredColorScheme(preferredColorScheme)
```

Add this helper inside `RootWidgetView`:

```swift
private var preferredColorScheme: ColorScheme? {
    switch viewModel.settings.appearanceMode {
    case .system:
        return nil
    case .dark:
        return .dark
    case .light:
        return .light
    }
}
```

- [ ] **Step 8: Re-run verification after any polish edits**

Run:

```bash
swift test
swift build
```

Expected: tests and build pass.

- [ ] **Step 9: Commit**

Run:

```bash
git add Sources Tests Package.swift .gitignore
git commit -m "polish: verify widget shell interactions"
```

Expected: commit succeeds if QA required edits. If QA required no edits, run `git status --short` and confirm there are no uncommitted source changes.

---

### Task 9: Record Data Integration Boundary

**Files:**
- Create: `docs/superpowers/specs/2026-06-08-codex-usage-data-boundary.md`

- [ ] **Step 1: Create data-boundary notes**

Create `docs/superpowers/specs/2026-06-08-codex-usage-data-boundary.md`:

```markdown
# Codex Usage Data Boundary

## Shell Prototype Data Contract

- The shell prototype uses `MockUsageProvider`.
- The mock provider returns a static `UsageSnapshot`.
- The UI must not read local Codex files directly.
- The UI must depend only on the `UsageProviding` protocol.

## Real Data Adapter Boundary

- A real adapter must implement `UsageProviding`.
- A real adapter must return the same `UsageSnapshot` model as the mock provider.
- A real adapter must not expose credentials, API keys, tokens, cookies, account identifiers, or raw response bodies to SwiftUI views.
- A real adapter must map unavailable data to a non-fresh snapshot rather than crashing the widget.

## Separate Plan Required

- Discovering the real Codex usage source is a separate implementation plan.
- That plan should identify the source contract before writing adapter code.
```

- [ ] **Step 2: Commit**

Run:

```bash
git add docs/superpowers/specs/2026-06-08-codex-usage-data-boundary.md
git commit -m "docs: record codex usage data boundary"
```

Expected: commit succeeds.

---

## Self-Review Checklist

- Spec coverage:
  - Default no-text capsule: Task 5.
  - Liquid Glass visual language: Task 5 and Task 6.
  - Weekly quota default toggle: Task 3, Task 4, Task 6, Task 8.
  - Refresh countdown color rules: Task 2 and Task 5.
  - Expanded popover details: Task 6.
  - System/dark/light appearance: Task 3, Task 6, Task 8.
  - Hide and restore: Task 7 and Task 8.
  - Real data uncertainty: Task 9 records the adapter boundary without blocking shell prototype.
- Red-flag scan:
  - No task uses undefined work.
  - Real data integration is explicitly excluded from the shell build and captured as discovery notes.
- Type consistency:
  - `WidgetSettings`, `UsageSnapshot`, `UsageRefreshState`, `OverlayLayout`, `UsageProviding`, and `WidgetViewModel` names are introduced before use in UI tasks.
  - `RootWidgetView`, `OverlayPanelController`, and `StatusMenuController` are introduced before the app delegate wires them together.
