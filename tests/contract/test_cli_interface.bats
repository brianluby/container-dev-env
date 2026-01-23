#!/usr/bin/env bats
# =============================================================================
# Contract Tests: CLI Interface (US1 - Start Autonomous Coding Session)
# Feature: 006-agentic-assistant
# =============================================================================
# Tests for CLI startup flags and exit codes as specified in the CLI contract.
# Verifies: --help, --version, missing API key, missing backend, valid invocation.
# =============================================================================

load '../test_helper'

# =============================================================================
# --help flag tests
# =============================================================================

@test "--help outputs usage information" {
  run bash "${AGENT_SCRIPT}" --help
  assert_output_contains "Usage:"
  assert_output_contains "agent"
  assert_output_contains "Options:"
}

@test "--help exits with code 0" {
  run bash "${AGENT_SCRIPT}" --help
  [ "${status}" -eq 0 ]
}

@test "-h short flag also outputs usage" {
  run bash "${AGENT_SCRIPT}" -h
  assert_output_contains "Usage:"
  [ "${status}" -eq 0 ]
}

# =============================================================================
# --version flag tests
# =============================================================================

@test "--version outputs version string" {
  run bash "${AGENT_SCRIPT}" --version
  assert_output_contains "agent"
  # Version should match semver pattern (digits.digits.digits)
  [[ "${output}" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "--version exits with code 0" {
  run bash "${AGENT_SCRIPT}" --version
  [ "${status}" -eq 0 ]
}

@test "-V short flag also outputs version" {
  run bash "${AGENT_SCRIPT}" -V
  assert_output_contains "agent"
  [ "${status}" -eq 0 ]
}

# =============================================================================
# Missing API key tests (exit code 3)
# =============================================================================

@test "missing API key exits with code 3 when running a task" {
  # Unset all API keys to guarantee none are present
  unset ANTHROPIC_API_KEY 2>/dev/null || true
  unset OPENAI_API_KEY 2>/dev/null || true
  unset GOOGLE_API_KEY 2>/dev/null || true

  # Create a mock backend so we pass the backend detection step
  local mock_bin="${TEST_TMPDIR}/bin"
  mkdir -p "${mock_bin}"
  printf '#!/bin/bash\nexit 0\n' > "${mock_bin}/opencode"
  chmod +x "${mock_bin}/opencode"

  export PATH="${mock_bin}:${PATH}"
  export AGENT_BACKEND="opencode"

  run bash "${AGENT_SCRIPT}" "fix the bug"
  [ "${status}" -eq 3 ]
}

@test "missing API key error message mentions key variable names" {
  unset ANTHROPIC_API_KEY 2>/dev/null || true
  unset OPENAI_API_KEY 2>/dev/null || true
  unset GOOGLE_API_KEY 2>/dev/null || true

  local mock_bin="${TEST_TMPDIR}/bin"
  mkdir -p "${mock_bin}"
  printf '#!/bin/bash\nexit 0\n' > "${mock_bin}/opencode"
  chmod +x "${mock_bin}/opencode"

  export PATH="${mock_bin}:${PATH}"
  export AGENT_BACKEND="opencode"

  run bash "${AGENT_SCRIPT}" "fix the bug"
  assert_output_contains "API"
}

# =============================================================================
# Missing backend binary tests (exit code 4)
# =============================================================================

@test "missing backend binary exits with code 4" {
  # Set PATH to exclude real binaries; only keep essential system commands
  local empty_bin="${TEST_TMPDIR}/empty_bin"
  mkdir -p "${empty_bin}"

  # Provide essential commands needed by the script (bash, jq, etc.)
  # but NOT opencode or claude
  for cmd in bash cat grep mkdir mktemp rm jq git; do
    local cmd_path
    cmd_path="$(command -v "${cmd}" 2>/dev/null || true)"
    if [[ -n "${cmd_path}" ]]; then
      ln -sf "${cmd_path}" "${empty_bin}/${cmd}"
    fi
  done

  export PATH="${empty_bin}"
  export AGENT_BACKEND="opencode"
  export ANTHROPIC_API_KEY="test-key-for-validation"

  run bash "${AGENT_SCRIPT}" "fix the bug"
  [ "${status}" -eq 4 ]
}

@test "missing backend error message suggests rebuilding container" {
  local empty_bin="${TEST_TMPDIR}/empty_bin"
  mkdir -p "${empty_bin}"

  for cmd in bash cat grep mkdir mktemp rm jq git; do
    local cmd_path
    cmd_path="$(command -v "${cmd}" 2>/dev/null || true)"
    if [[ -n "${cmd_path}" ]]; then
      ln -sf "${cmd_path}" "${empty_bin}/${cmd}"
    fi
  done

  export PATH="${empty_bin}"
  export AGENT_BACKEND="opencode"
  export ANTHROPIC_API_KEY="test-key-for-validation"

  run bash "${AGENT_SCRIPT}" "fix the bug"
  assert_output_contains "not installed"
}

# =============================================================================
# Valid invocation with mock backend (exit code 0)
# =============================================================================

@test "valid invocation with mock backend exits 0" {
  # Create mock opencode binary that succeeds
  local mock_bin="${TEST_TMPDIR}/bin"
  mkdir -p "${mock_bin}"
  cat > "${mock_bin}/opencode" << 'MOCKEOF'
#!/bin/bash
# Mock opencode: accept any args and exit successfully
echo "mock opencode executed: $*"
exit 0
MOCKEOF
  chmod +x "${mock_bin}/opencode"

  export PATH="${mock_bin}:${PATH}"
  export AGENT_BACKEND="opencode"
  export OPENAI_API_KEY="test-key-for-validation"

  run bash "${AGENT_SCRIPT}" "write hello world"
  [ "${status}" -eq 0 ]
}

@test "valid invocation launches the correct backend" {
  local mock_bin="${TEST_TMPDIR}/bin"
  mkdir -p "${mock_bin}"
  cat > "${mock_bin}/opencode" << 'MOCKEOF'
#!/bin/bash
echo "BACKEND_INVOKED=opencode"
echo "ARGS=$*"
exit 0
MOCKEOF
  chmod +x "${mock_bin}/opencode"

  export PATH="${mock_bin}:${PATH}"
  export AGENT_BACKEND="opencode"
  export OPENAI_API_KEY="test-key-for-validation"

  run bash "${AGENT_SCRIPT}" "write tests"
  assert_output_contains "BACKEND_INVOKED=opencode"
}

@test "valid invocation with --claude flag uses claude backend" {
  local mock_bin="${TEST_TMPDIR}/bin"
  mkdir -p "${mock_bin}"
  cat > "${mock_bin}/claude" << 'MOCKEOF'
#!/bin/bash
echo "BACKEND_INVOKED=claude"
echo "ARGS=$*"
exit 0
MOCKEOF
  chmod +x "${mock_bin}/claude"

  export PATH="${mock_bin}:${PATH}"
  export ANTHROPIC_API_KEY="test-key-for-validation"

  run bash "${AGENT_SCRIPT}" --claude "refactor module"
  [ "${status}" -eq 0 ]
  assert_output_contains "BACKEND_INVOKED=claude"
}
