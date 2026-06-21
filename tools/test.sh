#!/bin/bash
#
# Compiles and runs the test suite. The samplers are compiled together with the
# test runner (the UI sources are excluded so nothing launches a GUI).
#
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Compiling tests"
swiftc -O \
	Sources/CPUSampler.swift \
	Sources/MemorySampler.swift \
	Tests/Tests.swift \
	-o "$WORK/tests"

echo "==> Running tests"
"$WORK/tests"
