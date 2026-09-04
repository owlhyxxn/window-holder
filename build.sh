#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="WindowHolder"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "==> Building ${APP_NAME} (release)..."
swift build -c release

echo "==> Assembling ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "==> Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Done."
echo ""
echo "Run:  open ${APP_BUNDLE}"
echo "To launch at login, check 'Launch at Login' in the menu bar icon's menu."
echo ""
echo "Note: on first launch, macOS will ask for Accessibility permission."
echo "      Grant it in System Settings > Privacy & Security > Accessibility > WindowHolder."
