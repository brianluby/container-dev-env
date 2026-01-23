#!/usr/bin/env bash
# test_continue_config_valid.sh — Contract test for US1
# Validates Continue config.yaml.tmpl syntax and required schema fields per Contract 2
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../../src/config/continue/config.yaml.tmpl"

echo "=== Contract Test: Continue Config Validation ==="

ALL_PASSED=true

# Test 1: File exists
echo "[TEST] Config template exists..."
if [[ -f "${CONFIG_FILE}" ]]; then
    echo "[PASS] config.yaml.tmpl exists"
else
    echo "[FAIL] config.yaml.tmpl not found at ${CONFIG_FILE}"
    exit 1
fi

# Test 2: Required top-level fields (schema v1)
echo "[TEST] Required field: name..."
if grep -q "^name:" "${CONFIG_FILE}"; then
    echo "[PASS] 'name' field present"
else
    echo "[FAIL] 'name' field missing"
    ALL_PASSED=false
fi

echo "[TEST] Required field: version..."
if grep -q "^version:" "${CONFIG_FILE}"; then
    echo "[PASS] 'version' field present"
else
    echo "[FAIL] 'version' field missing"
    ALL_PASSED=false
fi

echo "[TEST] Required field: schema: v1..."
if grep -q "^schema: v1" "${CONFIG_FILE}"; then
    echo "[PASS] 'schema: v1' field present"
else
    echo "[FAIL] 'schema: v1' field missing"
    ALL_PASSED=false
fi

# Test 3: At least one model with chat role
echo "[TEST] At least one chat model defined..."
if grep -q "chat" "${CONFIG_FILE}"; then
    echo "[PASS] Chat role model found"
else
    echo "[FAIL] No chat model defined"
    ALL_PASSED=false
fi

# Test 4: At least one model with autocomplete role
echo "[TEST] At least one autocomplete model defined..."
if grep -q "autocomplete" "${CONFIG_FILE}"; then
    echo "[PASS] Autocomplete role model found"
else
    echo "[FAIL] No autocomplete model defined"
    ALL_PASSED=false
fi

# Test 5: API keys use secrets syntax (not literal)
echo "[TEST] API keys use \${{ secrets.* }} syntax..."
KEY_REFS=$(grep -c 'secrets\.' "${CONFIG_FILE}" || echo "0")
if [[ "${KEY_REFS}" -ge 1 ]]; then
    echo "[PASS] Found ${KEY_REFS} secrets references"
else
    echo "[FAIL] No secrets references found"
    ALL_PASSED=false
fi

# Test 6: No literal API keys in config
echo "[TEST] No literal API keys..."
if grep -qE 'apiKey:\s*"?sk-' "${CONFIG_FILE}" 2>/dev/null; then
    echo "[FAIL] Found literal API key(s)"
    ALL_PASSED=false
else
    echo "[PASS] No literal API keys"
fi

# Test 7: YAML syntax validation (basic — check no tab indentation)
echo "[TEST] No tab indentation (YAML requirement)..."
if grep -qP '^\t' "${CONFIG_FILE}" 2>/dev/null; then
    echo "[FAIL] Found tab indentation"
    ALL_PASSED=false
else
    echo "[PASS] No tab indentation"
fi

# Test 8: models section exists
echo "[TEST] models section exists..."
if grep -q "^models:" "${CONFIG_FILE}"; then
    echo "[PASS] 'models' section present"
else
    echo "[FAIL] 'models' section missing"
    ALL_PASSED=false
fi

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== Continue Config: ALL PASSED ==="
else
    echo "=== Continue Config: FAILURES DETECTED ==="
    exit 1
fi
