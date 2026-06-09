#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="CodexIslandUsageWidget"
APP_NAME="${APP_NAME:-Usage Panel}"
BUNDLE_ID="${BUNDLE_ID:-com.codex.CodexIslandUsageWidget}"
VERSION="${VERSION:-0.1.6}"
BUILD_NUMBER="${BUILD_NUMBER:-7}"
MIN_SYSTEM_VERSION="14.0"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
FINAL_APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
STAGING_DIR="$(mktemp -d)"
APP_VERIFY_STAGING=""
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$PRODUCT_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_NAME="AppIcon"
APP_ICON="$ROOT_DIR/Assets/$APP_ICON_NAME.icns"

cleanup() {
  rm -rf "$STAGING_DIR"
  if [[ -n "${APP_VERIFY_STAGING:-}" ]]; then
    rm -rf "$APP_VERIFY_STAGING"
  fi
}

trap cleanup EXIT

usage() {
  cat <<USAGE >&2
usage: $0 [--debug|--release] [--identity SIGN_IDENTITY]

Environment:
  VERSION=0.1.6
  BUILD_NUMBER=7
  BUNDLE_ID=com.codex.CodexIslandUsageWidget
  SIGN_IDENTITY=-    ad-hoc by default; use "Developer ID Application: ..." for distribution
  APP_NAME="Usage Panel"
USAGE
}

sign_app() {
  xattr -cr "$APP_BUNDLE"

  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --deep --options runtime --timestamp=none --sign - "$APP_BUNDLE"
  else
    codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
  fi
}

clear_bundle_detritus() {
  local bundle="$1"
  xattr -cr "$bundle"
  xattr -d com.apple.FinderInfo "$bundle" 2>/dev/null || true
  xattr -d 'com.apple.fileprovider.fpfs#P' "$bundle" 2>/dev/null || true
}

verify_clean_app_copy() {
  local source_bundle="$1"
  APP_VERIFY_STAGING="$(mktemp -d "${TMPDIR:-/tmp}/Usage-Panel-verify.XXXXXX")"
  local verify_bundle="$APP_VERIFY_STAGING/$APP_NAME.app"

  ditto --norsrc "$source_bundle" "$verify_bundle"
  clear_bundle_detritus "$verify_bundle"
  codesign --verify --deep --strict --verbose=2 "$verify_bundle"

  rm -rf "$APP_VERIFY_STAGING"
  APP_VERIFY_STAGING=""
}

CONFIGURATION="release"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)
      CONFIGURATION="debug"
      shift
      ;;
    --release)
      CONFIGURATION="release"
      shift
      ;;
    --identity)
      SIGN_IDENTITY="${2:?missing signing identity}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

cd "$ROOT_DIR"

if [[ "$CONFIGURATION" == "release" ]]; then
  swift build -c release --product "$PRODUCT_NAME"
  BUILD_BINARY="$(swift build -c release --show-bin-path)/$PRODUCT_NAME"
else
  swift build --product "$PRODUCT_NAME"
  BUILD_BINARY="$(swift build --show-bin-path)/$PRODUCT_NAME"
fi

mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
if [[ ! -f "$APP_ICON" ]]; then
  echo "error: missing app icon: $APP_ICON" >&2
  exit 1
fi
cp "$APP_ICON" "$APP_RESOURCES/$APP_ICON_NAME.icns"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026</string>
</dict>
</plist>
PLIST

sign_app
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
if ! spctl -a -vv "$APP_BUNDLE"; then
  echo "note: Gatekeeper rejected this local ad-hoc build. Use a Developer ID identity and notarize for public distribution." >&2
fi
sign_app
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

rm -rf "$FINAL_APP_BUNDLE"
ditto --norsrc "$APP_BUNDLE" "$FINAL_APP_BUNDLE"
clear_bundle_detritus "$FINAL_APP_BUNDLE"
verify_clean_app_copy "$FINAL_APP_BUNDLE"

rm -f "$ZIP_PATH"
ditto -c -k --keepParent --norsrc "$FINAL_APP_BUNDLE" "$ZIP_PATH"

echo "$FINAL_APP_BUNDLE"
echo "$ZIP_PATH"
