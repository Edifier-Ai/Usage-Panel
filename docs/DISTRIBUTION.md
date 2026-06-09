# Usage Panel Distribution

## Build A Local App Or DMG

Build a signed local `.app` bundle:

```bash
script/package_app.sh
```

Build a local `.dmg`:

```bash
script/package_dmg.sh --ad-hoc
```

Output:

```text
dist/Usage Panel.app
dist/Usage Panel-0.1.6.zip
dist/Usage Panel-0.1.6.dmg
```

By default the app is ad-hoc signed with hardened runtime enabled. This is suitable for local use on this Mac.

The ad-hoc DMG is useful for quick testing, but it is not suitable as a smooth public distribution artifact. Other Macs will usually show Gatekeeper warnings because there is no Developer ID signature or notarization ticket.

## Run Or Verify

```bash
script/build_and_run.sh run
script/build_and_run.sh --verify
```

The app is an accessory app (`LSUIElement=true`), so it does not show a Dock icon. Restore/hide/quit are available from the menu bar item.

## Start At Login

Install the user LaunchAgent:

```bash
script/install_login_item.sh
```

Remove it:

```bash
script/uninstall_login_item.sh
```

The LaunchAgent is installed at:

```text
~/Library/LaunchAgents/com.codex.CodexIslandUsageWidget.launcher.plist
```

It starts the built app from the current `dist/` path by launching the app executable directly:

```text
dist/Usage Panel.app/Contents/MacOS/CodexIslandUsageWidget
```

The LaunchAgent uses `KeepAlive` for non-successful exits, so a crash or system-level termination is restarted after launchd throttling. A normal Quit exits successfully and is not force-restarted.

LaunchAgent logs are written to:

```text
~/Library/Logs/CodexIslandUsageWidget/launchd.out.log
~/Library/Logs/CodexIslandUsageWidget/launchd.err.log
```

If the project folder moves, run `script/install_login_item.sh` again.

## Permissions

The app currently reads local Codex session logs from:

```text
~/.codex/sessions
~/.codex/archived_sessions
```

The app reads the newest `event_msg` / `token_count` record. If the newest token-count record no longer exposes `rate_limits.primary` and `rate_limits.secondary`, the provider reports a schema-change failure instead of silently treating the data as missing.

On every successful refresh, the app writes a heartbeat file:

```text
~/Library/Application Support/CodexIslandUsageWidget/last_success.json
```

This file records the app refresh time, source log timestamp, remaining 5-hour quota, remaining weekly quota, and whether the source data was fresh.

No Accessibility, Screen Recording, microphone, camera, or network permission is required for the current implementation.

Local notification permission is requested so the app can alert once when usage data becomes stale. The expanded widget also displays stale data explicitly as `数据已过期 · 上次更新 X 分钟前`.

The app is intentionally not sandboxed. A sandboxed build would need a different data-source strategy because sandboxing would block direct reads of `~/.codex` by default.

## Developer ID Distribution

For distribution to other Macs, use a Developer ID Application certificate and notarize the DMG.

You need:

- A paid Apple Developer Program membership.
- A `Developer ID Application` certificate installed in this Mac's login keychain.
- Apple notary credentials, usually an app-specific password saved through `notarytool store-credentials`.

Use a stable reverse-DNS bundle identifier for public builds:

```bash
export BUNDLE_ID="com.yourcompany.CodexIslandUsageWidget"
```

Check whether this Mac has a usable certificate:

```bash
security find-identity -p codesigning -v
```

If it lists a `Developer ID Application: ...` identity, build a signed DMG:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" script/package_dmg.sh
```

For notarization, first save Apple notary credentials once:

```bash
xcrun notarytool store-credentials codex-island \
  --apple-id "you@example.com" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD"
```

Then create, sign, notarize, staple, and verify the DMG:

```bash
NOTARY_KEYCHAIN_PROFILE=codex-island \
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
script/package_dmg.sh --notarize
```

If there is only one Developer ID Application certificate on this Mac, the script can find it automatically:

```bash
NOTARY_KEYCHAIN_PROFILE=codex-island script/package_dmg.sh --notarize
```

Send this file to other people:

```text
dist/Usage Panel-0.1.6.dmg
```

The script validates with:

```bash
hdiutil verify "dist/Usage Panel-0.1.6.dmg"
spctl -a -t open --context context:primary-signature -vv "dist/Usage Panel-0.1.6.dmg"
spctl -a -vv "dist/Usage Panel.app"
```

Current local environment note: no Developer ID signing identity was found, so local packaging uses ad-hoc signing. To make a DMG that friends or coworkers can open normally, install an Apple Developer ID Application certificate and provide notary credentials.
