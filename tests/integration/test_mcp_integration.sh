#!/usr/bin/env bash
# Integration test: MCP protocol integration with mock server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${PROJECT_ROOT}/src/agent/lib/config.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

export HOME="${TEST_DIR}/home"
mkdir -p "${HOME}/.config/agent" "${HOME}/.config/opencode"
export WORKSPACE="${TEST_DIR}/workspace"
mkdir -p "${WORKSPACE}"
export AGENT_STATE_DIR="${TEST_DIR}/state"
mkdir -p "${AGENT_STATE_DIR}"

PASS=0
FAIL=0

check() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "FAIL: ${desc}"
    FAIL=$((FAIL + 1))
  fi
}

# Test: Config without MCP section loads without error
check "Config loads without MCP section" load_config "${WORKSPACE}"

# Test: Config with MCP section parses successfully
cat > "${WORKSPACE}/.agent.json" <<'EOF'
{
  "mode": "auto",
  "mcp": {
    "servers": {
      "docs": {
        "command": "npx",
        "args": ["-y", "@context7/mcp-server"]
      }
    }
  }
}
EOF
check "Config with MCP section loads" load_config "${WORKSPACE}"

# Test: MCP config can be extracted via jq
MCP_SERVERS=$(jq -r '.mcp.servers | keys[]' "${WORKSPACE}/.agent.json" 2>/dev/null)
check "MCP server names extractable" test "${MCP_SERVERS}" = "docs"

# Test: Invalid MCP config (bad JSON) is handled gracefully
cat > "${TEST_DIR}/bad_mcp/.agent.json" <<'EOF'
{ "mcp": { "servers": { broken
EOF
mkdir -p "${TEST_DIR}/bad_mcp"
cat > "${TEST_DIR}/bad_mcp/.agent.json" <<'EOF'
{ "mcp": { "servers": { "broken" }}}
EOF
run_result=0
load_config "${TEST_DIR}/bad_mcp" 2>/dev/null || run_result=$?
check "Invalid MCP config fails gracefully" test "${run_result}" -ne 0

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] || exit 1
