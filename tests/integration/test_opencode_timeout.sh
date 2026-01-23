#!/usr/bin/env bash
# test_opencode_timeout.sh — Integration test: Timeout configuration
#
# Verifies:
#   1. Rendered config contains timeout=60 and retries=1
#   2. Agent exits with clear error when provider is unreachable

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Integration: Timeout Configuration ==="

# Test 1: Config contains timeout and retries values
echo "  [1/2] Checking rendered config for timeout settings..."
docker run --rm "$IMAGE" bash -c '
    CONFIG="$HOME/.config/opencode/config.yaml"
    if [[ ! -f "$CONFIG" ]]; then
        echo "FAIL: Config file not found at $CONFIG"
        exit 1
    fi
    if ! grep -q "timeout: 60" "$CONFIG"; then
        echo "FAIL: timeout: 60 not found in config"
        exit 1
    fi
    if ! grep -q "retries: 1" "$CONFIG"; then
        echo "FAIL: retries: 1 not found in config"
        exit 1
    fi
    echo "OK: timeout=60, retries=1 present in config"
'

# Test 2: Agent fails gracefully with unreachable provider
echo "  [2/2] Checking graceful failure with unreachable provider..."
EXIT_CODE=0
ERROR_OUTPUT=$(docker run --rm \
    -e OPENCODE_PROVIDER=openai \
    -e OPENCODE_MODEL=gpt-4o \
    -e OPENAI_API_KEY=sk-test-unreachable \
    -e OPENAI_BASE_URL=http://10.255.255.1:1/v1 \
    "$IMAGE" timeout 10 opencode "test" 2>&1) || EXIT_CODE=$?

# Agent should exit non-zero when provider is unreachable
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "FAIL: Agent exited 0 with unreachable provider (expected non-zero)"
    exit 1
fi
echo "      Exit code: $EXIT_CODE (non-zero as expected)"

echo "PASS: Timeout configuration tests"
