#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-Usage Panel}"
VOLUME_NAME="${VOLUME_NAME:-Usage Panel}"
VERSION="${VERSION:-0.1.6}"
BUILD_NUMBER="${BUILD_NUMBER:-7}"
BUNDLE_ID="${BUNDLE_ID:-com.codex.CodexIslandUsageWidget}"
SIGN_IDENTITY="${SIGN_IDENTITY:-auto}"
NOTARIZE="${NOTARIZE:-0}"
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_STAGING=""
APP_VERIFY_STAGING=""
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

CONFIGURATION="release"

cleanup() {
  if [[ -n "${DMG_STAGING:-}" ]]; then
    rm -rf "$DMG_STAGING"
  fi
  if [[ -n "${APP_VERIFY_STAGING:-}" ]]; then
    rm -rf "$APP_VERIFY_STAGING"
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

trap cleanup EXIT

usage() {
  cat <<USAGE >&2
usage: $0 [--debug|--release] [--identity SIGN_IDENTITY|--ad-hoc] [--notarize]

Environment:
  VERSION=0.1.6
  BUILD_NUMBER=7
  BUNDLE_ID=com.codex.CodexIslandUsageWidget
  APP_NAME="Usage Panel"
  VOLUME_NAME="Usage Panel"
  SIGN_IDENTITY=auto
      auto finds the first "Developer ID Application" identity.
      use "-" or --ad-hoc for a local-only DMG.

Notarization:
  NOTARIZE=1 or --notarize
  NOTARY_KEYCHAIN_PROFILE=profile-name
    or APPLE_ID, TEAM_ID, APP_SPECIFIC_PASSWORD

Examples:
  $0 --ad-hoc
  SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" $0 --notarize
  NOTARY_KEYCHAIN_PROFILE=codex-island $0 --notarize
USAGE
}

find_developer_id_identity() {
  security find-identity -p codesigning -v | awk -F '"' '/Developer ID Application:/ { print $2; exit }'
}

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
    --ad-hoc)
      SIGN_IDENTITY="-"
      shift
      ;;
    --notarize)
      NOTARIZE="1"
      shift
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

if [[ "$SIGN_IDENTITY" == "auto" ]]; then
  SIGN_IDENTITY="$(find_developer_id_identity || true)"
  if [[ -z "$SIGN_IDENTITY" ]]; then
    SIGN_IDENTITY="-"
    echo "note: no Developer ID Application identity found; creating a local-only ad-hoc DMG." >&2
  else
    echo "Using signing identity: $SIGN_IDENTITY" >&2
  fi
fi

if [[ "$NOTARIZE" == "1" && "$SIGN_IDENTITY" == "-" ]]; then
  cat >&2 <<'ERROR'
error: notarization requires a Developer ID Application signing identity.

Install an Apple Developer ID certificate, then rerun with:
  security find-identity -p codesigning -v
  SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" script/package_dmg.sh --notarize
ERROR
  exit 1
fi

if [[ "$NOTARIZE" == "1" && -z "$NOTARY_KEYCHAIN_PROFILE" ]]; then
  if [[ -z "$APPLE_ID" || -z "$TEAM_ID" || -z "$APP_SPECIFIC_PASSWORD" ]]; then
    cat >&2 <<'ERROR'
error: notarization requires either NOTARY_KEYCHAIN_PROFILE or Apple ID credentials.

Recommended one-time setup:
  xcrun notarytool store-credentials codex-island \
    --apple-id "you@example.com" \
    --team-id "TEAMID" \
    --password "app-specific-password"

Then rerun:
  NOTARY_KEYCHAIN_PROFILE=codex-island script/package_dmg.sh --notarize
ERROR
    exit 1
  fi
fi

env \
  APP_NAME="$APP_NAME" \
  VERSION="$VERSION" \
  BUILD_NUMBER="$BUILD_NUMBER" \
  BUNDLE_ID="$BUNDLE_ID" \
  SIGN_IDENTITY="$SIGN_IDENTITY" \
  "$ROOT_DIR/script/package_app.sh" "--$CONFIGURATION"

DMG_STAGING="$(mktemp -d "${TMPDIR:-/tmp}/Usage-Panel-dmg.XXXXXX")"
ditto --norsrc "$APP_BUNDLE" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"
xattr -cr "$DMG_STAGING"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGING"
DMG_STAGING=""

if [[ "$SIGN_IDENTITY" != "-" ]]; then
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
  codesign --verify --verbose=2 "$DMG_PATH"
else
  echo "note: DMG is not Developer ID signed; other Macs will show Gatekeeper warnings." >&2
fi

hdiutil verify "$DMG_PATH"

if [[ "$NOTARIZE" == "1" ]]; then
  if [[ -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
    xcrun notarytool submit "$DMG_PATH" \
      --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
      --wait
  else
    xcrun notarytool submit "$DMG_PATH" \
      --apple-id "$APPLE_ID" \
      --team-id "$TEAM_ID" \
      --password "$APP_SPECIFIC_PASSWORD" \
      --wait
  fi

  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

if ! spctl -a -t open --context context:primary-signature -vv "$DMG_PATH"; then
  echo "note: Gatekeeper rejected this DMG. For public distribution, use Developer ID signing and notarization." >&2
fi

if ! spctl -a -vv "$APP_BUNDLE"; then
  echo "note: Gatekeeper rejected the app bundle. This is expected for ad-hoc builds." >&2
fi

clear_bundle_detritus "$APP_BUNDLE"
verify_clean_app_copy "$APP_BUNDLE"

echo "$DMG_PATH"
