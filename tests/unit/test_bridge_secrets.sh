#!/usr/bin/env bash
# test_bridge_secrets.sh — Unit test for US3
# Tests bridge-secrets.sh edge cases: missing vars, empty values, whitespace, multiple keys
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_SCRIPT="${SCRIPT_DIR}/../../src/scripts/bridge-secrets.sh"
TEST_HOME=$(mktemp -d)
TESTS_PASSED=0
TESTS_FAILED=0

pass() { TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() { TESTS_FAILED=$((TESTS_FAILED + 1)); }

cleanup() {
    rm -rf "${TEST_HOME}"
}
trap cleanup EXIT

run_bridge() {
    HOME="${TEST_HOME}" bash "${BRIDGE_SCRIPT}" "$@" 2>&1
    return $?
}

reset_env() {
    rm -rf "${TEST_HOME}/.continue"
}

echo "=== Unit Test: bridge-secrets.sh ==="

# Test 1: Error when no API keys are set at all
echo "[TEST] No keys set → should error..."
unset ANTHROPIC_API_KEY OPENAI_API_KEY MISTRAL_API_KEY 2>/dev/null || true
if run_bridge; then
    echo "[FAIL] Script should have exited with error when no keys are set"
    fail
else
    echo "[PASS] Script errors when no API keys are available"
    pass
fi
reset_env

# Test 2: Only ANTHROPIC_API_KEY set → should succeed
echo "[TEST] Only ANTHROPIC_API_KEY set → should succeed..."
export ANTHROPIC_API_KEY="sk-ant-test123"
unset OPENAI_API_KEY MISTRAL_API_KEY 2>/dev/null || true
if run_bridge; then
    if grep -q "ANTHROPIC_API_KEY=sk-ant-test123" "${TEST_HOME}/.continue/.env"; then
        echo "[PASS] ANTHROPIC_API_KEY written correctly"
        pass
    else
        echo "[FAIL] ANTHROPIC_API_KEY not found in .env"
        fail
    fi
else
    echo "[FAIL] Script should succeed with at least one key"
    fail
fi
reset_env

# Test 3: All keys set → all should be written
echo "[TEST] All three keys set → all should appear..."
export ANTHROPIC_API_KEY="sk-ant-all"
export OPENAI_API_KEY="sk-openai-all"
export MISTRAL_API_KEY="mistral-all"
if run_bridge; then
    PASS=true
    grep -q "ANTHROPIC_API_KEY=sk-ant-all" "${TEST_HOME}/.continue/.env" || PASS=false
    grep -q "OPENAI_API_KEY=sk-openai-all" "${TEST_HOME}/.continue/.env" || PASS=false
    grep -q "MISTRAL_API_KEY=mistral-all" "${TEST_HOME}/.continue/.env" || PASS=false
    if [[ "${PASS}" == "true" ]]; then
        echo "[PASS] All three keys written"
        pass
    else
        echo "[FAIL] Not all keys found in .env"
        fail
    fi
else
    echo "[FAIL] Script failed unexpectedly"
    fail
fi
reset_env

# Test 4: Empty value → should be skipped
echo "[TEST] Empty OPENAI_API_KEY → should be skipped..."
export ANTHROPIC_API_KEY="sk-ant-valid"
export OPENAI_API_KEY=""
unset MISTRAL_API_KEY 2>/dev/null || true
if run_bridge; then
    if grep -q "OPENAI_API_KEY=" "${TEST_HOME}/.continue/.env"; then
        echo "[FAIL] Empty key should not be written"
        fail
    else
        echo "[PASS] Empty key skipped correctly"
        pass
    fi
else
    echo "[FAIL] Script failed unexpectedly"
    fail
fi
reset_env

# Test 5: File permissions should be 600
echo "[TEST] File permissions should be 600..."
export ANTHROPIC_API_KEY="sk-ant-perms"
unset OPENAI_API_KEY MISTRAL_API_KEY 2>/dev/null || true
if run_bridge; then
    PERMS=$(stat -f "%Lp" "${TEST_HOME}/.continue/.env" 2>/dev/null || \
            stat -c "%a" "${TEST_HOME}/.continue/.env" 2>/dev/null || echo "unknown")
    if [[ "${PERMS}" == "600" ]]; then
        echo "[PASS] File permissions are 600"
        pass
    else
        echo "[FAIL] File permissions are ${PERMS}, expected 600"
        fail
    fi
else
    echo "[FAIL] Script failed unexpectedly"
    fail
fi
reset_env

# Test 6: Whitespace-only key → should be skipped
echo "[TEST] Whitespace-only key → should be skipped..."
export ANTHROPIC_API_KEY="sk-ant-ws"
export OPENAI_API_KEY="   "
unset MISTRAL_API_KEY 2>/dev/null || true
if run_bridge; then
    if grep -q "OPENAI_API_KEY=" "${TEST_HOME}/.continue/.env"; then
        echo "[FAIL] Whitespace-only key should not be written"
        fail
    else
        echo "[PASS] Whitespace-only key skipped"
        pass
    fi
else
    echo "[FAIL] Script failed unexpectedly"
    fail
fi

# Summary
echo ""
echo "=== Results: ${TESTS_PASSED} passed, ${TESTS_FAILED} failed ==="
if [[ "${TESTS_FAILED}" -gt 0 ]]; then
    exit 1
fi
