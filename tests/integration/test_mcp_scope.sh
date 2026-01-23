#!/usr/bin/env bash
# test_mcp_scope.sh — Integration test for US5
# Verifies MCP filesystem server reads /workspace, blocked outside
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: MCP Filesystem Scope ==="

ALL_PASSED=true

# Test 1: MCP filesystem binary is available
echo "[TEST] mcp-server-filesystem is installed..."
if docker exec "${CONTAINER}" which mcp-server-filesystem >/dev/null 2>&1; then
    echo "[PASS] mcp-server-filesystem binary found"
else
    echo "[FAIL] mcp-server-filesystem not found in PATH"
    ALL_PASSED=false
fi

# Test 2: MCP git server (Python) is installed
echo "[TEST] mcp-server-git Python package is installed..."
if docker exec "${CONTAINER}" python -m mcp_server_git --help >/dev/null 2>&1; then
    echo "[PASS] mcp-server-git package available"
else
    # Try python3
    if docker exec "${CONTAINER}" python3 -m mcp_server_git --help >/dev/null 2>&1; then
        echo "[PASS] mcp-server-git package available (python3)"
    else
        echo "[FAIL] mcp-server-git package not found"
        ALL_PASSED=false
    fi
fi

# Test 3: Cline MCP settings file exists at correct globalStorage path
echo "[TEST] Cline MCP settings at globalStorage path..."
SETTINGS_PATH="/root/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
if docker exec "${CONTAINER}" test -f "${SETTINGS_PATH}" 2>/dev/null; then
    echo "[PASS] Cline MCP settings file exists"
else
    echo "[FAIL] Cline MCP settings not found at ${SETTINGS_PATH}"
    ALL_PASSED=false
fi

# Test 4: Continue config has mcpServers section with filesystem
echo "[TEST] Continue config has mcpServers section..."
if docker exec "${CONTAINER}" grep -q "mcpServers" /root/.continue/config.yaml 2>/dev/null; then
    echo "[PASS] mcpServers section in Continue config"
else
    echo "[FAIL] mcpServers section missing from Continue config"
    ALL_PASSED=false
fi

# Test 5: MCP filesystem scoped to /workspace in Continue config
echo "[TEST] Continue MCP scoped to /workspace..."
if docker exec "${CONTAINER}" grep -A2 "filesystem" /root/.continue/config.yaml 2>/dev/null | grep -q "/workspace"; then
    echo "[PASS] Continue MCP filesystem scoped to /workspace"
else
    echo "[FAIL] Continue MCP not scoped to /workspace"
    ALL_PASSED=false
fi

# Test 6: MCP filesystem scoped to /workspace in Cline config
echo "[TEST] Cline MCP scoped to /workspace..."
CLINE_SCOPE=$(docker exec "${CONTAINER}" \
    python3 -c "
import json
d = json.load(open('${SETTINGS_PATH}'))
fs = d['mcpServers']['filesystem']
print('/workspace' in fs.get('args', []))
" 2>/dev/null || echo "False")

if [[ "${CLINE_SCOPE}" == "True" ]]; then
    echo "[PASS] Cline MCP filesystem scoped to /workspace"
else
    echo "[FAIL] Cline MCP not properly scoped"
    ALL_PASSED=false
fi

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== MCP Scope: ALL PASSED ==="
else
    echo "=== MCP Scope: FAILURES DETECTED ==="
    exit 1
fi
