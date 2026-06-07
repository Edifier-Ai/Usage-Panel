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
