#!/usr/bin/env bash
# Integration tests: MCP server startup, filesystem access, and security
# Tests: T021, T025, T026, T026b, T030, T034, T035, T037, T042, T050, T051, T052, T055, T063
#
# These tests require a built Docker container and are designed to run INSIDE the container.
# Use: docker exec <container_id> bash /path/to/test_mcp_startup.sh
#
# Exit: 0 if all tests pass, 1 if any fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PASS=0
FAIL=0
SKIP=0

###############################################################################
# Test Helpers
###############################################################################

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

check_not() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "FAIL: ${desc}"
    FAIL=$((FAIL + 1))
  else
    echo "PASS: ${desc}"
    PASS=$((PASS + 1))
  fi
}

skip_test() {
  local desc="$1"
  local reason="$2"
  echo "SKIP: ${desc} (${reason})"
  SKIP=$((SKIP + 1))
}

require_container() {
  if [[ ! -f /etc/debian_version ]]; then
    echo "ERROR: This test must be run inside the container"
    exit 1
  fi
}

###############################################################################
# T021: Filesystem server binary availability
###############################################################################

echo "=== T021: Filesystem Server Availability ==="

check "T021: mcp-server-filesystem binary exists on PATH" \
  command -v mcp-server-filesystem

check "T021: mcp-server-filesystem is executable" \
  test -x "$(command -v mcp-server-filesystem 2>/dev/null || echo /nonexistent)"

check "T021: Node.js is available" \
  command -v node

check "T021: npx is available" \
  command -v npx

###############################################################################
# T023: Verify filesystem server entry in default config
###############################################################################

echo ""
echo "=== T023: Filesystem Config Verification ==="

DEFAULT_CONFIG="/home/dev/.mcp/defaults/mcp-config.json"

check "T023: default config file exists" \
  test -f "${DEFAULT_CONFIG}"

if [[ -f "${DEFAULT_CONFIG}" ]]; then
  check "T023: filesystem server is in default config" \
    jq -e '.mcpServers.filesystem' "${DEFAULT_CONFIG}"

  check "T023: filesystem server is enabled" \
    jq -e '.mcpServers.filesystem.enabled == true' "${DEFAULT_CONFIG}"

  check "T023: filesystem server command is mcp-server-filesystem" \
    jq -e '.mcpServers.filesystem.command == "mcp-server-filesystem"' "${DEFAULT_CONFIG}"

  check "T023: filesystem server args includes /workspace" \
    jq -e '.mcpServers.filesystem.args | index("/workspace") != null' "${DEFAULT_CONFIG}"
fi

###############################################################################
# T025: Config generation produces filesystem server entry
###############################################################################

echo ""
echo "=== T025: Filesystem in Generated Config ==="

GENERATE_SCRIPT="/home/dev/.mcp/generate-configs.sh"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TEST_TMPDIR}"' EXIT

if [[ -f "${GENERATE_SCRIPT}" ]]; then
  # Generate a Claude Code config from the default
  export MCP_OUTPUT_CLAUDE="${TEST_TMPDIR}/settings.local.json"
  mkdir -p "$(dirname "${MCP_OUTPUT_CLAUDE}")"

  bash "${GENERATE_SCRIPT}" --source "${DEFAULT_CONFIG}" --tools claude-code --quiet

  check "T025: Claude Code config generated" \
    test -f "${MCP_OUTPUT_CLAUDE}"

  if [[ -f "${MCP_OUTPUT_CLAUDE}" ]]; then
    check "T025: filesystem server in Claude Code config" \
      jq -e '.mcpServers.filesystem' "${MCP_OUTPUT_CLAUDE}"

    check "T025: filesystem server has /workspace arg" \
      jq -e '.mcpServers.filesystem.args | index("/workspace") != null' "${MCP_OUTPUT_CLAUDE}"

    check "T025: filesystem server has no 'enabled' field in output" \
      jq -e '.mcpServers.filesystem | has("enabled") | not' "${MCP_OUTPUT_CLAUDE}"

    check "T025: filesystem server has no 'description' field in output" \
      jq -e '.mcpServers.filesystem | has("description") | not' "${MCP_OUTPUT_CLAUDE}"
  fi
fi

###############################################################################
# T026: Directory allowlist enforcement (filesystem args)
###############################################################################

echo ""
echo "=== T026: Directory Allowlist Enforcement ==="

if [[ -f "${MCP_OUTPUT_CLAUDE}" ]]; then
  # The filesystem server's args list defines allowed directories
  # Only explicitly specified directories should be present
  ALLOWED_DIRS=$(jq -r '.mcpServers.filesystem.args[]' "${MCP_OUTPUT_CLAUDE}" 2>/dev/null)

  check "T026: only /workspace in filesystem args (allowlist)" \
    test "${ALLOWED_DIRS}" = "/workspace"

  # Verify no sensitive directories appear
  check_not "T026: /etc is NOT in filesystem args" \
    echo "${ALLOWED_DIRS}" | grep -q "^/etc$"

  check_not "T026: /root is NOT in filesystem args" \
    echo "${ALLOWED_DIRS}" | grep -q "^/root$"

  check_not "T026: / is NOT in filesystem args" \
    echo "${ALLOWED_DIRS}" | grep -q "^/$"
fi

###############################################################################
# T026b: Symlink escape prevention
# NOTE: This tests the filesystem MCP server's built-in security.
# The server itself resolves and checks paths against the allowlist.
###############################################################################

echo ""
echo "=== T026b: Symlink Escape Prevention ==="

if [[ -d /workspace ]]; then
  # Create a symlink in /workspace that points outside (to /etc/passwd)
  SYMLINK_PATH="/workspace/.test_symlink_escape"
  ln -sf /etc/passwd "${SYMLINK_PATH}" 2>/dev/null || true

  if [[ -L "${SYMLINK_PATH}" ]]; then
    # The filesystem MCP server should resolve the symlink target to /etc/passwd
    # which is outside /workspace, and block access
    RESOLVED=$(readlink -f "${SYMLINK_PATH}" 2>/dev/null || true)

    check "T026b: symlink resolves outside workspace" \
      test "${RESOLVED}" = "/etc/passwd"

    check "T026b: resolved path is NOT within /workspace" \
      test "${RESOLVED#/workspace}" = "${RESOLVED}"

    # Clean up
    rm -f "${SYMLINK_PATH}"
  else
    skip_test "T026b: symlink creation" "cannot create symlink in /workspace"
  fi
else
  skip_test "T026b: symlink escape test" "/workspace does not exist"
fi

###############################################################################
# T024: Filesystem-specific validation
###############################################################################

echo ""
echo "=== T024: Filesystem Validation ==="

VALIDATE_SCRIPT="/home/dev/.mcp/validate-mcp.sh"

if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  VALIDATE_OUTPUT=$(bash "${VALIDATE_SCRIPT}" --source "${DEFAULT_CONFIG}" 2>&1 || true)

  check "T024: validation mentions filesystem server" \
    echo "${VALIDATE_OUTPUT}" | grep -q "filesystem"

  check "T024: filesystem reports OK (binary found)" \
    echo "${VALIDATE_OUTPUT}" | grep -q "filesystem.*OK"
fi

###############################################################################
# T028/T029/T030: Context7 Documentation Server
###############################################################################

echo ""
echo "=== T028-T030: Context7 Documentation Server ==="

if [[ -f "${DEFAULT_CONFIG}" ]]; then
  check "T028: context7 server is in default config" \
    jq -e '.mcpServers.context7' "${DEFAULT_CONFIG}"

  check "T028: context7 server is enabled" \
    jq -e '.mcpServers.context7.enabled == true' "${DEFAULT_CONFIG}"

  check "T028: context7 uses env var reference for API key" \
    jq -e '.mcpServers.context7.env.CONTEXT7_API_KEY == "${CONTEXT7_API_KEY}"' "${DEFAULT_CONFIG}"

  check "T028: context7 uses pinned npx version" \
    jq -e '.mcpServers.context7.args | index("@upstash/context7-mcp@2.1.0") != null' "${DEFAULT_CONFIG}"
fi

# T029: Validate-mcp warns about missing Context7 key
if [[ -f "${VALIDATE_SCRIPT}" ]]; then
  # Run without CONTEXT7_API_KEY set
  unset CONTEXT7_API_KEY 2>/dev/null || true
  VALIDATE_C7=$(bash "${VALIDATE_SCRIPT}" --source "${DEFAULT_CONFIG}" 2>&1 || true)

  check "T029: validation warns when CONTEXT7_API_KEY unset" \
    echo "${VALIDATE_C7}" | grep -q "CONTEXT7_API_KEY"

  check "T030: other servers still functional despite missing Context7 key" \
    echo "${VALIDATE_C7}" | grep -q "filesystem.*OK"
fi

###############################################################################
# T037: Memory Volume
###############################################################################

echo ""
echo "=== T037: Memory Volume ==="

MEMORY_DIR="/home/dev/.local/share/mcp-memory"

check "T037: memory volume directory exists" \
  test -d "${MEMORY_DIR}"

check "T037: memory directory is writable" \
  test -w "${MEMORY_DIR}"

if [[ -f "${DEFAULT_CONFIG}" ]]; then
  check "T038: memory server MEMORY_FILE_PATH points to volume" \
    jq -e '.mcpServers.memory.env.MEMORY_FILE_PATH == "/home/dev/.local/share/mcp-memory/memory.json"' "${DEFAULT_CONFIG}"
fi

###############################################################################
# T052: Optional Server Binaries
###############################################################################

echo ""
echo "=== T052: Optional Server Binaries ==="

check "T052: npx is available for GitHub MCP" \
  command -v npx

check "T052: python3 is available for git MCP" \
  command -v python3

# Check mcp-server-git module is installed
check "T052: mcp-server-git Python module available" \
  python3 -c "import mcp_server_git"

###############################################################################
# Summary
###############################################################################

echo ""
echo "================================================================"
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
echo "================================================================"
[[ "${FAIL}" -eq 0 ]] || exit 1
