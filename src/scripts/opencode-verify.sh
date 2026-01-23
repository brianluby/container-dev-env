#!/usr/bin/env bash
# opencode-verify.sh — Validates OpenCode binary SHA256 checksum
#
# Usage: opencode-verify.sh <binary-path> <expected-sha256>
#
# Exits 0 on match, 1 on mismatch or error.

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <binary-path> <expected-sha256>" >&2
    exit 1
fi

BINARY_PATH="$1"
EXPECTED_SHA="$2"

if [[ ! -f "$BINARY_PATH" ]]; then
    echo "ERROR: Binary not found at $BINARY_PATH" >&2
    exit 1
fi

ACTUAL_SHA=$(sha256sum "$BINARY_PATH" | awk '{print $1}')

if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
    echo "ERROR: SHA256 mismatch for $BINARY_PATH" >&2
    echo "  Expected: $EXPECTED_SHA" >&2
    echo "  Actual:   $ACTUAL_SHA" >&2
    exit 1
fi

echo "OK: SHA256 verified for $BINARY_PATH"
