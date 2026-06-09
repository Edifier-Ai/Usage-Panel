#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-Usage Panel}"
PRODUCT_NAME="CodexIslandUsageWidget"
LABEL="com.codex.CodexIslandUsageWidget.launcher"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/dist/$APP_NAME.app}"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOGS_DIR="$HOME/Library/Logs/$PRODUCT_NAME"
PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
STDOUT_LOG="$LOGS_DIR/launchd.out.log"
STDERR_LOG="$LOGS_DIR/launchd.err.log"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "App bundle not found: $APP_BUNDLE" >&2
  echo "Run script/package_app.sh first." >&2
  exit 1
fi

if [[ ! -x "$APP_EXECUTABLE" ]]; then
  echo "App executable not found or not executable: $APP_EXECUTABLE" >&2
  echo "Run script/package_app.sh first." >&2
  exit 1
fi

mkdir -p "$LAUNCH_AGENTS_DIR" "$LOGS_DIR"

cat >"$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$APP_EXECUTABLE</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key>
    <false/>
  </dict>
  <key>ThrottleInterval</key>
  <integer>10</integer>
  <key>LimitLoadToSessionType</key>
  <string>Aqua</string>
  <key>StandardOutPath</key>
  <string>$STDOUT_LOG</string>
  <key>StandardErrorPath</key>
  <string>$STDERR_LOG</string>
</dict>
</plist>
PLIST

if [[ "${LAUNCH_AGENT_DRY_RUN:-0}" == "1" ]]; then
  echo "$PLIST"
  exit 0
fi

launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "$PLIST"
