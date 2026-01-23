#!/usr/bin/env bash
# test_extension_persistence.sh — Integration test for US7
# Verifies extensions and configs survive container rebuild (volume persistence)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: Extension Persistence Across Rebuild ==="

# Check that extension files exist in the expected directories
echo "[TEST] Checking Continue config directory exists..."
CONFIG_EXISTS=$(docker exec "${CONTAINER}" \
    test -d /root/.continue && echo "yes" || echo "no")

if [[ "${CONFIG_EXISTS}" == "yes" ]]; then
    echo "[PASS] /root/.continue/ directory exists"
else
    echo "[FAIL] /root/.continue/ directory missing"
    exit 1
fi

echo "[TEST] Checking VS Code user settings directory exists..."
VSCODE_EXISTS=$(docker exec "${CONTAINER}" \
    test -d /root/.config/Code/User && echo "yes" || echo "no")

if [[ "${VSCODE_EXISTS}" == "yes" ]]; then
    echo "[PASS] /root/.config/Code/User/ directory exists"
else
    echo "[FAIL] /root/.config/Code/User/ directory missing"
    exit 1
fi

echo "[TEST] Checking Cline globalStorage directory exists..."
CLINE_EXISTS=$(docker exec "${CONTAINER}" \
    test -d /root/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings && echo "yes" || echo "no")

if [[ "${CLINE_EXISTS}" == "yes" ]]; then
    echo "[PASS] Cline globalStorage directory exists"
else
    echo "[FAIL] Cline globalStorage directory missing"
    exit 1
fi

# Verify config files are present
echo "[TEST] Checking settings.json exists..."
SETTINGS_EXISTS=$(docker exec "${CONTAINER}" \
    test -f /root/.config/Code/User/settings.json && echo "yes" || echo "no")

if [[ "${SETTINGS_EXISTS}" == "yes" ]]; then
    echo "[PASS] VS Code settings.json present"
else
    echo "[FAIL] VS Code settings.json missing"
    exit 1
fi

echo "[TEST] Checking cline_mcp_settings.json exists..."
MCP_EXISTS=$(docker exec "${CONTAINER}" \
    test -f /root/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json && echo "yes" || echo "no")

if [[ "${MCP_EXISTS}" == "yes" ]]; then
    echo "[PASS] Cline MCP settings present"
else
    echo "[FAIL] Cline MCP settings missing"
    exit 1
fi

echo "=== Extension Persistence: ALL PASSED ==="
