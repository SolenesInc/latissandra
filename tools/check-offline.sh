#!/bin/bash
#
# Offline guarantee: fails if anything that could require an internet connection
# is introduced. Three checks:
#   1. networking APIs / hardcoded URLs in the Swift sources
#   2. a dependency manager (SPM / CocoaPods / Carthage) — third-party deps are
#      fetched over the internet and could do anything, including networking
#   3. the built binary linking any non-system or networking framework
#
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
note() { echo "  ✗ $1"; }

echo "==> [1/3] Scanning sources for networking APIs"
NET_PATTERN='import[[:space:]]+(Network|CFNetwork|NIO|AsyncHTTPClient|Alamofire|Starscream)|URLSession|URLRequest|URLConnection|NWConnection|NWListener|NWBrowser|NWPath|CFSocket|CFStream|CFHTTPMessage|getaddrinfo|gethostbyname|socket[[:space:]]*\(|https?://'
if grep -rEn "$NET_PATTERN" Sources Tests; then
    note "networking API or URL found in source (see matches above)"
    fail=1
else
    echo "    none found"
fi

echo "==> [2/3] Checking for dependency managers"
deps_found=0
for f in Package.swift Package.resolved Podfile Podfile.lock Cartfile Cartfile.resolved; do
    if [ -e "$f" ]; then
        note "dependency manifest present: $f"
        deps_found=1
        fail=1
    fi
done
if grep -rEn 'XCRemoteSwiftPackageReference|\.package\([[:space:]]*url:' . \
    --include='*.swift' --include='*.pbxproj' 2>/dev/null; then
    note "remote Swift package reference found"
    deps_found=1
    fail=1
fi
[ "$deps_found" -eq 0 ] && echo "    none found"

echo "==> [3/3] Inspecting linked frameworks"
BIN="build/Latissandra.app/Contents/MacOS/Latissandra"
if [ ! -x "$BIN" ]; then
    echo "    binary not built yet — building..."
    ./build.sh >/dev/null
fi
while read -r lib; do
    [ -z "$lib" ] && continue
    case "$lib" in
        /usr/lib/* | /System/Library/Frameworks/*) ;;  # Apple system library — ok so far
        *) note "non-system dependency linked: $lib"; fail=1 ;;
    esac
    case "$lib" in
        *CFNetwork* | */Network.framework/* | *NetworkExtension*)
            note "networking framework linked: $lib"; fail=1 ;;
    esac
done < <(otool -L "$BIN" | tail -n +2 | awk '{print $1}')
echo "    linked: $(otool -L "$BIN" | tail -n +2 | awk '{print $1}' | xargs -n1 basename | paste -sd' ' -)"

echo ""
if [ "$fail" -ne 0 ]; then
    echo "❌ Offline guarantee violated — see the ✗ lines above."
    echo "   Latissandra must stay local-only. If this dependency is truly necessary"
    echo "   and does NOT touch the network, update tools/check-offline.sh deliberately."
    exit 1
fi
echo "✅ Offline guarantee holds: no networking code, no dependency managers, no networking frameworks."
