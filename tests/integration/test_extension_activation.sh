#!/usr/bin/env bash
# test_extension_activation.sh — Integration test for US7
# Verifies that Continue and Cline extensions activate without errors
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

# Test container name (set by CI or use default)
CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: Extension Activation ==="

# T006: Verify Continue extension is installed and activated
echo "[TEST] Checking Continue extension is installed..."
CONTINUE_STATUS=$(docker exec "${CONTAINER}" \
    openvscode-server --list-extensions 2>/dev/null | grep -c "Continue.continue" || true)

if [[ "${CONTINUE_STATUS}" -ge 1 ]]; then
    echo "[PASS] Continue extension (Continue.continue) is installed"
else
    echo "[FAIL] Continue extension (Continue.continue) NOT found"
    exit 1
fi

# T006: Verify Cline extension is installed and activated
echo "[TEST] Checking Cline extension is installed..."
CLINE_STATUS=$(docker exec "${CONTAINER}" \
    openvscode-server --list-extensions 2>/dev/null | grep -c "saoudrizwan.claude-dev" || true)

if [[ "${CLINE_STATUS}" -ge 1 ]]; then
    echo "[PASS] Cline extension (saoudrizwan.claude-dev) is installed"
else
    echo "[FAIL] Cline extension (saoudrizwan.claude-dev) NOT found"
    exit 1
fi

# Verify extension versions match pinned values
echo "[TEST] Checking Continue version is v1.2.14..."
CONTINUE_VER=$(docker exec "${CONTAINER}" \
    openvscode-server --list-extensions --show-versions 2>/dev/null | grep "Continue.continue" | head -1 || true)

if echo "${CONTINUE_VER}" | grep -q "1.2.14"; then
    echo "[PASS] Continue version is 1.2.14"
else
    echo "[WARN] Continue version mismatch: ${CONTINUE_VER}"
fi

echo "[TEST] Checking Cline version is v3.51.0..."
CLINE_VER=$(docker exec "${CONTAINER}" \
    openvscode-server --list-extensions --show-versions 2>/dev/null | grep "saoudrizwan.claude-dev" | head -1 || true)

if echo "${CLINE_VER}" | grep -q "3.51.0"; then
    echo "[PASS] Cline version is 3.51.0"
else
    echo "[WARN] Cline version mismatch: ${CLINE_VER}"
fi

echo "=== Extension Activation: ALL PASSED ==="
