#!/bin/bash
#
# Builds Latissandra.app from source using swiftc (no full Xcode required —
# Command Line Tools are enough). Produces build/Latissandra.app, ad-hoc signed
# so macOS launches it without complaint.
#
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Latissandra"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RES_DIR="$APP_BUNDLE/Contents/Resources"

echo "==> Cleaning previous build"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RES_DIR"

echo "==> Compiling"
swiftc -O \
	-target "$(uname -m)-apple-macos13.0" \
	-o "$MACOS_DIR/$APP_NAME" \
	Sources/*.swift

echo "==> Assembling bundle"
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
	cp Resources/AppIcon.icns "$RES_DIR/AppIcon.icns"
else
	echo "    (no Resources/AppIcon.icns — run ./tools/make_icons.sh to generate it)"
fi

echo "==> Ad-hoc code signing"
codesign --force --sign - "$APP_BUNDLE"

echo "==> Built $APP_BUNDLE"
echo "    Run it:  open \"$APP_BUNDLE\""
echo "    Probe:   \"$MACOS_DIR/$APP_NAME\" --probe"
