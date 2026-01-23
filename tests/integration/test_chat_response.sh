#!/usr/bin/env bash
# test_chat_response.sh — Integration test for US2
# Verifies chat model is configured in Continue for code assistance
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: Chat Response Configuration ==="

ALL_PASSED=true

# Test 1: Chat role model exists in config
echo "[TEST] Chat role model configured..."
CHAT_MODEL=$(docker exec "${CONTAINER}" \
    grep -c "chat" /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${CHAT_MODEL}" -ge 1 ]]; then
    echo "[PASS] Chat model configured"
else
    echo "[FAIL] No chat model in config"
    ALL_PASSED=false
fi

# Test 2: Claude Sonnet is configured for chat
echo "[TEST] Claude Sonnet chat model present..."
CLAUDE=$(docker exec "${CONTAINER}" \
    grep -c "claude-sonnet" /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${CLAUDE}" -ge 1 ]]; then
    echo "[PASS] Claude Sonnet model configured"
else
    echo "[FAIL] Claude Sonnet not found in config"
    ALL_PASSED=false
fi

# Test 3: Edit role configured (for code modifications)
echo "[TEST] Edit role model configured..."
EDIT_MODEL=$(docker exec "${CONTAINER}" \
    grep -c "edit" /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${EDIT_MODEL}" -ge 1 ]]; then
    echo "[PASS] Edit model configured"
else
    echo "[WARN] No edit role model — chat may not support code edits"
fi

# Test 4: Anthropic provider configured
echo "[TEST] Anthropic provider configured..."
ANTHROPIC=$(docker exec "${CONTAINER}" \
    grep -c "anthropic" /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${ANTHROPIC}" -ge 1 ]]; then
    echo "[PASS] Anthropic provider configured"
else
    echo "[FAIL] Anthropic provider not found"
    ALL_PASSED=false
fi

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== Chat Response Config: ALL PASSED ==="
else
    echo "=== Chat Response Config: FAILURES DETECTED ==="
    exit 1
fi
