#!/bin/bash
#
# Regenerates the app icon: renders a main PNG, then builds Resources/AppIcon.icns.
# Run from anywhere; paths are resolved relative to the repo root.
#
set -euo pipefail
cd "$(dirname "$0")/.."

MASTER="docs/images/icon_1024.png"
WORK="$(mktemp -d)"
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET" Resources docs/images

echo "==> Rendering master icon"
swiftc -O tools/make_icon.swift -o "$WORK/make_icon"
"$WORK/make_icon" "$MASTER"

echo "==> Generating iconset"
for s in 16 32 128 256 512; do
  sips -z "$s" "$s" "$MASTER" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z "$((s * 2))" "$((s * 2))" "$MASTER" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done

echo "==> Building icns"
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
rm -rf "$WORK"
echo "==> Wrote Resources/AppIcon.icns and $MASTER"
