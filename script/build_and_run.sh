#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-run}"
APP_PACKAGE="$ROOT_DIR/apps/apple/macOS"
BUILD_DIR="$ROOT_DIR/build/macOS"
APP_BUNDLE="$ROOT_DIR/build/Novel Engine.app"

case "$MODE" in run|--build|--build-qa|--debug|--logs|--telemetry|--verify) ;; *) echo "usage: $0 [--build|--build-qa QA_ROOT|--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;; esac
if [ "$MODE" = "--build-qa" ]; then
    [ -n "${2:-}" ] && [[ "$2" = /* ]] || { echo "--build-qa requires an absolute isolated library path" >&2; exit 2; }
    APP_BUNDLE="$ROOT_DIR/build/Novel Engine QA.app"
fi
swift build --package-path "$APP_PACKAGE" --scratch-path "$BUILD_DIR"
BIN_DIR="$(swift build --package-path "$APP_PACKAGE" --scratch-path "$BUILD_DIR" --show-bin-path)"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BIN_DIR/NovelEngine" "$APP_BUNDLE/Contents/MacOS/NovelEngine"
cp "$APP_PACKAGE/Configuration/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ "$MODE" = "--build-qa" ]; then
    /usr/bin/plutil -replace CFBundleIdentifier -string com.diamondfountain.novelengine.dev.qa "$APP_BUNDLE/Contents/Info.plist"
    /usr/bin/plutil -replace CFBundleName -string "Novel Engine QA" "$APP_BUNDLE/Contents/Info.plist"
    /usr/bin/plutil -replace CFBundleDisplayName -string "Novel Engine QA" "$APP_BUNDLE/Contents/Info.plist"
    /usr/bin/plutil -replace NovelEngineQARoot -string "$2" "$APP_BUNDLE/Contents/Info.plist"
    /usr/bin/plutil -replace CFBundleDocumentTypes.0.LSHandlerRank -string Alternate "$APP_BUNDLE/Contents/Info.plist"
fi
for RESOURCE in "$BIN_DIR"/*.bundle; do
    [ -d "$RESOURCE" ] || continue
    /usr/bin/ditto "$RESOURCE" "$APP_BUNDLE/Contents/Resources/$(basename "$RESOURCE")"
done
chmod +x "$APP_BUNDLE/Contents/MacOS/NovelEngine"
/usr/bin/codesign --force --sign - "$APP_BUNDLE"
/usr/bin/codesign --verify --strict "$APP_BUNDLE"
echo "$APP_BUNDLE"
case "$MODE" in
    --build|--build-qa) ;;
    --debug) /usr/bin/lldb "$APP_BUNDLE/Contents/MacOS/NovelEngine" ;;
    --logs|--telemetry) /usr/bin/open "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "NovelEngine"' ;;
    --verify) /usr/bin/open "$APP_BUNDLE"; sleep 1; /usr/bin/pgrep -f "$APP_BUNDLE/Contents/MacOS/NovelEngine" >/dev/null ;;
    run) /usr/bin/open "$APP_BUNDLE" ;;
esac
