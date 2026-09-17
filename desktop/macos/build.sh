#!/bin/bash
# Builds OpenStock.app: a tiny native macOS launcher that wraps the local
# dev/production server in a WKWebView window (no browser chrome, and the
# menu bar shows "OpenStock" instead of a browser). No Xcode project needed.
set -euo pipefail
cd "$(dirname "$0")"

APP="OpenStock.app"
BIN="$APP/Contents/MacOS/OpenStock"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "Compiling..."
swiftc -O Sources/main.swift -o "$BIN" -framework Cocoa -framework WebKit
chmod +x "$BIN"

codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
echo "Run it with: open $APP"
echo "Or copy/symlink it into /Applications and add it to the Dock."
