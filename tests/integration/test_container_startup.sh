#!/bin/bash
# =============================================================================
# Integration Tests: Container Startup (US1 - Start Autonomous Coding Session)
# Feature: 006-agentic-assistant
# =============================================================================
# Tests that the container environment is correctly configured for agent use.
# Checks: agent command availability, no GUI dependencies, non-root user,
#          opencode binary presence.
# =============================================================================

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGENT_SCRIPT="${PROJECT_ROOT}/src/agent/agent.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# TEST UTILITIES
# =============================================================================

log_test() {
  echo -e "${YELLOW}[TEST]${NC} $*"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $*"
  ((TESTS_PASSED++)) || true
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $*"
  ((TESTS_FAILED++)) || true
}

run_test() {
  local test_name="$1"
  local test_func="$2"
  ((TESTS_RUN++)) || true
  log_test "${test_name}"
  if ${test_func}; then
    log_pass "${test_name}"
  else
    log_fail "${test_name}"
  fi
}

print_summary() {
  echo ""
  echo "============================================="
  echo -e "Tests run: ${TESTS_RUN}, ${GREEN}Passed: ${TESTS_PASSED}${NC}, ${RED}Failed: ${TESTS_FAILED}${NC}"
  echo "============================================="
  if [[ "${TESTS_FAILED}" -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

# =============================================================================
# TEST CASES
# =============================================================================

# Check: agent command exists and is executable
test_agent_command_exists() {
  if [[ ! -f "${AGENT_SCRIPT}" ]]; then
    echo "  agent.sh not found at: ${AGENT_SCRIPT}" >&2
    return 1
  fi
  if [[ ! -x "${AGENT_SCRIPT}" ]]; then
    # The script may not have execute bit set but should be runnable via bash
    if ! bash "${AGENT_SCRIPT}" --version >/dev/null 2>&1; then
      echo "  agent.sh is not executable and cannot be run via bash" >&2
      return 1
    fi
  fi
  # Verify it produces valid output
  local version_output
  version_output="$(bash "${AGENT_SCRIPT}" --version 2>&1)"
  if [[ -z "${version_output}" ]]; then
    echo "  agent.sh --version produced no output" >&2
    return 1
  fi
  echo "  agent command outputs: ${version_output}"
  return 0
}

# Check: no X11/GUI dependencies (DISPLAY unset, no libX11)
test_no_gui_dependencies() {
  # Check DISPLAY is not set
  if [[ -n "${DISPLAY:-}" ]]; then
    echo "  DISPLAY environment variable is set: '${DISPLAY}'" >&2
    echo "  Agent container should not have X11 dependencies" >&2
    return 1
  fi
  echo "  DISPLAY is unset (good)"

  # Check no libX11 is loaded or available in standard lib paths
  local libx11_found=false
  for lib_path in /usr/lib /usr/lib64 /usr/local/lib /lib; do
    if [[ -d "${lib_path}" ]]; then
      if find "${lib_path}" -name 'libX11*' -type f 2>/dev/null | grep -q .; then
        echo "  Found libX11 in ${lib_path}" >&2
        libx11_found=true
      fi
    fi
  done

  if [[ "${libx11_found}" == "true" ]]; then
    echo "  libX11 libraries found; agent should be headless-only" >&2
    return 1
  fi
  echo "  No libX11 libraries found (good)"
  return 0
}

# Check: running as non-root user
test_non_root_user() {
  local current_uid
  current_uid="$(id -u)"
  if [[ "${current_uid}" -eq 0 ]]; then
    echo "  Running as root (UID=0); agent should run as non-root" >&2
    return 1
  fi
  echo "  Running as UID=${current_uid} (non-root, good)"
  return 0
}

# Check: opencode binary exists (or is expected to be installed in container)
test_opencode_binary_exists() {
  # In the container environment, opencode should be on PATH
  # In development/CI, we check if it is available or if a placeholder exists
  if command -v opencode >/dev/null 2>&1; then
    local opencode_path
    opencode_path="$(command -v opencode)"
    echo "  opencode found at: ${opencode_path}"
    return 0
  fi

  # If not on PATH, check common installation locations
  local search_paths=(
    "/usr/local/bin/opencode"
    "/usr/bin/opencode"
    "${HOME}/.local/bin/opencode"
    "${HOME}/bin/opencode"
  )

  for search_path in "${search_paths[@]}"; do
    if [[ -f "${search_path}" ]]; then
      echo "  opencode found at: ${search_path}"
      return 0
    fi
  done

  echo "  opencode binary not found on PATH or in common locations" >&2
  echo "  Expected locations: /usr/local/bin/opencode, ~/.local/bin/opencode" >&2
  return 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

echo "============================================="
echo " Container Startup Integration Tests"
echo " Feature: 006-agentic-assistant (US1)"
echo "============================================="
echo ""

run_test "Agent command exists and is executable" test_agent_command_exists
run_test "No X11/GUI dependencies present" test_no_gui_dependencies
run_test "Running as non-root user" test_non_root_user
run_test "OpenCode binary exists" test_opencode_binary_exists

print_summary
