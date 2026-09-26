#!/usr/bin/env bash
# Builds and assembles Notchling.app: a menu-bar-only (LSUIElement) bundle with
# a generated creature icon and an ad-hoc signature, ready to `open`.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Notchling"
BUNDLE_ID="com.notchling.pip"
VERSION="1.0.0"
CONFIGURATION="release"
DIST="dist"
APP="$DIST/$APP_NAME.app"
ICONSET="$DIST/AppIcon.iconset"

echo "== building $APP_NAME ($CONFIGURATION) =="
swift build -c "$CONFIGURATION" --product "$APP_NAME"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

echo "== assembling bundle =="
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"

echo "== generating icon =="
rm -rf "$ICONSET"
swift scripts/make-icon.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

echo "== writing Info.plist =="
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>$APP_NAME</string>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
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
	<string>$VERSION</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST

echo "== ad-hoc codesign =="
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=2 "$APP"

echo "packaged: $APP"
