#!/bin/bash
#
# Lints all Swift sources using Apple's swift-format. Fails (non-zero exit) on any
# style violation, so CI catches unformatted code. Run ./tools/format.sh to fix.
#
set -euo pipefail
cd "$(dirname "$0")/.."

swift format lint --strict --recursive Sources Tests
echo "==> Lint passed"
