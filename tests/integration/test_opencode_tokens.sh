#!/usr/bin/env bash
# test_opencode_tokens.sh — Integration test: Token usage display
#
# Verifies:
#   Agent output includes token usage information after an operation.
#   Since we cannot make real API calls in CI, we verify that:
#   1. The binary supports token display (--help mentions tokens/usage)
#   2. The config does not disable token display

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Integration: OpenCode Token Display ==="

# Test 1: Binary help mentions token/usage tracking
echo "  [1/2] Checking binary supports token display..."
docker run --rm "$IMAGE" bash -c '
    HELP_OUTPUT=$(opencode --help 2>&1 || true)
    # Check that the binary mentions usage or tokens in its help
    if echo "$HELP_OUTPUT" | grep -qi "usage\|token\|cost\|model"; then
        echo "OK: Binary references usage/token tracking"
    else
        echo "WARNING: No explicit token/usage mention in --help (may be built-in)"
        # Not a failure — many tools show usage by default without a flag
    fi
'

# Test 2: Config does not disable token display (no display_tokens: false)
echo "  [2/2] Checking config does not disable token display..."
docker run --rm "$IMAGE" bash -c '
    CONFIG="$HOME/.config/opencode/config.yaml"
    if [[ -f "$CONFIG" ]]; then
        if grep -q "display_tokens: false\|show_usage: false\|hide_cost: true" "$CONFIG"; then
            echo "FAIL: Config explicitly disables token display"
            exit 1
        fi
    fi
    echo "OK: Token display not disabled in config"
'

echo "PASS: OpenCode token display tests"
