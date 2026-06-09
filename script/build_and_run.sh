#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
PRODUCT_NAME="CodexIslandUsageWidget"
APP_NAME="${APP_NAME:-Usage Panel}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME"

stop_existing() {
  pkill -x "$PRODUCT_NAME" >/dev/null 2>&1 || true
  pkill -f "$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME" >/dev/null 2>&1 || true
  for _ in {1..20}; do
    if ! pgrep -x "$PRODUCT_NAME" >/dev/null && ! pgrep -f "$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME" >/dev/null; then
      return
    fi
    sleep 0.1
  done
}

verify_process() {
  pgrep -f "$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME" >/dev/null
}

usage() {
  echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package]" >&2
}

cd "$ROOT_DIR"

case "$MODE" in
  --package|package)
    "$ROOT_DIR/script/package_app.sh"
    ;;
  run)
    stop_existing
    "$ROOT_DIR/script/package_app.sh"
    /usr/bin/open -n "$APP_BUNDLE"
    ;;
  --debug|debug)
    stop_existing
    "$ROOT_DIR/script/package_app.sh" --debug
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    stop_existing
    "$ROOT_DIR/script/package_app.sh"
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "process == \"$PRODUCT_NAME\""
    ;;
  --telemetry|telemetry)
    stop_existing
    "$ROOT_DIR/script/package_app.sh"
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"com.codex.CodexIslandUsageWidget\""
    ;;
  --verify|verify)
    stop_existing
    "$ROOT_DIR/script/package_app.sh"
    /usr/bin/open -n "$APP_BUNDLE"
    sleep 2
    verify_process
    stop_existing
    "$ROOT_DIR/script/package_app.sh" >/dev/null
    ;;
  *)
    usage
    exit 2
    ;;
esac
