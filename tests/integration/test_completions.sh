#!/usr/bin/env bash
# test_completions.sh — Integration test for US1
# Verifies inline completion configuration is in place for supported languages
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: Inline Completions Configuration ==="

ALL_PASSED=true

# Test 1: Continue config has autocomplete model
echo "[TEST] Continue config has autocomplete role model..."
AUTOCOMPLETE=$(docker exec "${CONTAINER}" \
    grep -c "autocomplete" /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${AUTOCOMPLETE}" -ge 1 ]]; then
    echo "[PASS] Autocomplete model configured"
else
    echo "[FAIL] No autocomplete model in config"
    ALL_PASSED=false
fi

# Test 2: Autocomplete options configured
echo "[TEST] debounceDelay is set..."
DEBOUNCE=$(docker exec "${CONTAINER}" \
    grep -c "debounceDelay" /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${DEBOUNCE}" -ge 1 ]]; then
    echo "[PASS] debounceDelay configured"
else
    echo "[FAIL] debounceDelay not found"
    ALL_PASSED=false
fi

# Test 3: FIM-trained model is configured (Codestral or Qwen)
echo "[TEST] FIM-trained model configured (codestral or qwen)..."
FIM_MODEL=$(docker exec "${CONTAINER}" \
    grep -cE "(codestral|qwen)" /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${FIM_MODEL}" -ge 1 ]]; then
    echo "[PASS] FIM-trained model found"
else
    echo "[WARN] No FIM-specific model found (completions may be suboptimal)"
fi

# Test 4: Continue extension is active (prerequisite for completions)
echo "[TEST] Continue extension is installed..."
CONTINUE_EXT=$(docker exec "${CONTAINER}" \
    openvscode-server --list-extensions 2>/dev/null | grep -c "Continue.continue" || echo "0")

if [[ "${CONTINUE_EXT}" -ge 1 ]]; then
    echo "[PASS] Continue extension available for completions"
else
    echo "[FAIL] Continue extension not installed"
    ALL_PASSED=false
fi

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== Completions Config: ALL PASSED ==="
else
    echo "=== Completions Config: FAILURES DETECTED ==="
    exit 1
fi
