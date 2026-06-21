#!/bin/bash
#
# Formats all Swift sources in place using Apple's swift-format (bundled with the
# Swift toolchain — no install needed).
#
set -euo pipefail
cd "$(dirname "$0")/.."

swift format --in-place --recursive Sources Tests
echo "==> Formatted Sources and Tests"
