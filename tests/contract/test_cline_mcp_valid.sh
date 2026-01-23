#!/usr/bin/env bash
# test_cline_mcp_valid.sh — Contract test for US5
# Validates Cline MCP settings JSON syntax, autoApprove: [], /workspace scope per Contract 4
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../../src/config/cline/cline_mcp_settings.json"

echo "=== Contract Test: Cline MCP Settings ==="

ALL_PASSED=true

# Test 1: File exists
echo "[TEST] cline_mcp_settings.json exists..."
if [[ -f "${CONFIG_FILE}" ]]; then
    echo "[PASS] File exists"
else
    echo "[FAIL] File not found"
    exit 1
fi

# Test 2: Valid JSON syntax
echo "[TEST] Valid JSON syntax..."
if python3 -m json.tool "${CONFIG_FILE}" > /dev/null 2>&1; then
    echo "[PASS] Valid JSON"
else
    echo "[FAIL] Invalid JSON syntax"
    ALL_PASSED=false
fi

# Test 3: mcpServers key exists
echo "[TEST] mcpServers key present..."
if python3 -c "import json; d=json.load(open('${CONFIG_FILE}')); assert 'mcpServers' in d" 2>/dev/null; then
    echo "[PASS] mcpServers key present"
else
    echo "[FAIL] mcpServers key missing"
    ALL_PASSED=false
fi

# Test 4: autoApprove is empty array for all servers (human-in-the-loop)
echo "[TEST] autoApprove is empty for all servers..."
AUTOAPPROVE_CHECK=$(python3 -c "
import json, sys
d = json.load(open('${CONFIG_FILE}'))
for name, cfg in d.get('mcpServers', {}).items():
    aa = cfg.get('autoApprove', None)
    if aa is None:
        print(f'FAIL: {name} missing autoApprove')
        sys.exit(1)
    if aa != []:
        print(f'FAIL: {name} autoApprove is not empty: {aa}')
        sys.exit(1)
print('OK')
" 2>&1)

if [[ "${AUTOAPPROVE_CHECK}" == "OK" ]]; then
    echo "[PASS] All servers have autoApprove: []"
else
    echo "[FAIL] ${AUTOAPPROVE_CHECK}"
    ALL_PASSED=false
fi

# Test 5: Filesystem server scoped to /workspace only
echo "[TEST] Filesystem server scoped to /workspace..."
FS_SCOPE=$(python3 -c "
import json, sys
d = json.load(open('${CONFIG_FILE}'))
fs = d.get('mcpServers', {}).get('filesystem', {})
args = fs.get('args', [])
if '/workspace' in args and len([a for a in args if a.startswith('/')]) == 1:
    print('OK')
else:
    print(f'FAIL: args={args}')
" 2>&1)

if [[ "${FS_SCOPE}" == "OK" ]]; then
    echo "[PASS] Filesystem scoped to /workspace"
else
    echo "[FAIL] ${FS_SCOPE}"
    ALL_PASSED=false
fi

# Test 6: No npx commands (pre-installed binaries only)
echo "[TEST] No npx runtime downloads..."
if grep -q "npx" "${CONFIG_FILE}"; then
    echo "[FAIL] Found npx command — should use pre-installed binaries"
    ALL_PASSED=false
else
    echo "[PASS] No npx commands"
fi

# Test 7: Git server uses python command
echo "[TEST] Git server uses python command..."
GIT_CMD=$(python3 -c "
import json
d = json.load(open('${CONFIG_FILE}'))
git = d.get('mcpServers', {}).get('git', {})
print(git.get('command', ''))
" 2>&1)

if [[ "${GIT_CMD}" == "python" ]]; then
    echo "[PASS] Git server uses python command"
else
    echo "[FAIL] Git server command is '${GIT_CMD}', expected 'python'"
    ALL_PASSED=false
fi

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== Cline MCP Settings: ALL PASSED ==="
else
    echo "=== Cline MCP Settings: FAILURES DETECTED ==="
    exit 1
fi
