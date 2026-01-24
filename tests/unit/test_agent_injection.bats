#!/usr/bin/env bats
# test_agent_injection.bats — Command injection prevention tests for agent wrapper
# Verifies: FR-001 (no eval/shell metacharacter interpretation in task descriptions)

# Load BATS helpers
load '../unit/.bats-battery/bats-support/load'
load '../unit/.bats-battery/bats-assert/load'

# Get the project root
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

setup() {
  # Create temp directory for canary files
  TEST_TEMP="$(mktemp -d)"
  export TEST_TEMP

  # Source the provider library to test build_backend_command
  source "${REPO_ROOT}/src/agent/lib/provider.sh"

  # Mock the backend binaries so detect_backend passes
  export PATH="${TEST_TEMP}/bin:${PATH}"
  mkdir -p "${TEST_TEMP}/bin"
  printf '#!/bin/sh\necho "mock opencode: $*"\n' > "${TEST_TEMP}/bin/opencode"
  printf '#!/bin/sh\necho "mock claude: $*"\n' > "${TEST_TEMP}/bin/claude"
  chmod +x "${TEST_TEMP}/bin/opencode" "${TEST_TEMP}/bin/claude"
}

teardown() {
  rm -rf "${TEST_TEMP}"
}

# --- Canary-based injection tests ---

@test "build_backend_command: semicolon injection does not execute" {
  local canary="${TEST_TEMP}/canary_semicolon"
  local hostile_task="; touch ${canary}"

  build_backend_command "opencode" "manual" "${hostile_task}"
  # Execute the resulting command array
  "${AGENT_CMD[@]}" 2>/dev/null || true

  [ ! -f "${canary}" ]
}

@test "build_backend_command: command substitution does not execute" {
  local canary="${TEST_TEMP}/canary_subshell"
  local hostile_task='$(touch '"${TEST_TEMP}"'/canary_subshell)'

  build_backend_command "opencode" "manual" "${hostile_task}"
  "${AGENT_CMD[@]}" 2>/dev/null || true

  [ ! -f "${canary}" ]
}

@test "build_backend_command: backtick injection does not execute" {
  local canary="${TEST_TEMP}/canary_backtick"
  local hostile_task='`touch '"${TEST_TEMP}"'/canary_backtick`'

  build_backend_command "opencode" "manual" "${hostile_task}"
  "${AGENT_CMD[@]}" 2>/dev/null || true

  [ ! -f "${canary}" ]
}

@test "build_backend_command: pipe injection does not execute" {
  local canary="${TEST_TEMP}/canary_pipe"
  local hostile_task="| touch ${canary}"

  build_backend_command "opencode" "manual" "${hostile_task}"
  "${AGENT_CMD[@]}" 2>/dev/null || true

  [ ! -f "${canary}" ]
}

@test "build_backend_command: && injection does not execute" {
  local canary="${TEST_TEMP}/canary_and"
  local hostile_task="&& touch ${canary}"

  build_backend_command "opencode" "manual" "${hostile_task}"
  "${AGENT_CMD[@]}" 2>/dev/null || true

  [ ! -f "${canary}" ]
}

# --- Output-based tests for opencode ---

@test "build_backend_command opencode: task is a single argument" {
  local task='fix the bug; rm -rf /'
  build_backend_command "opencode" "manual" "${task}"

  # AGENT_CMD should have exactly 3 elements: opencode, run, <task>
  assert_equal "${#AGENT_CMD[@]}" 3
  assert_equal "${AGENT_CMD[0]}" "opencode"
  assert_equal "${AGENT_CMD[1]}" "run"
  assert_equal "${AGENT_CMD[2]}" "${task}"
}

@test "build_backend_command opencode: preserves special chars in task" {
  local task='deploy $(whoami) to `hostname` | tee /etc/passwd && echo pwned'
  build_backend_command "opencode" "manual" "${task}"

  assert_equal "${AGENT_CMD[2]}" "${task}"
}

# --- Output-based tests for claude ---

@test "build_backend_command claude manual: task is single argument" {
  local task='analyze; rm -rf /'
  build_backend_command "claude" "manual" "${task}"

  assert_equal "${#AGENT_CMD[@]}" 3
  assert_equal "${AGENT_CMD[0]}" "claude"
  assert_equal "${AGENT_CMD[1]}" "-p"
  assert_equal "${AGENT_CMD[2]}" "${task}"
}

@test "build_backend_command claude auto: includes skip-permissions flag" {
  local task='do the thing'
  build_backend_command "claude" "auto" "${task}"

  assert_equal "${#AGENT_CMD[@]}" 4
  assert_equal "${AGENT_CMD[0]}" "claude"
  assert_equal "${AGENT_CMD[1]}" "--dangerously-skip-permissions"
  assert_equal "${AGENT_CMD[2]}" "-p"
  assert_equal "${AGENT_CMD[3]}" "${task}"
}

@test "build_backend_command claude hybrid: same as manual" {
  local task='review the code'
  build_backend_command "claude" "hybrid" "${task}"

  assert_equal "${#AGENT_CMD[@]}" 3
  assert_equal "${AGENT_CMD[0]}" "claude"
  assert_equal "${AGENT_CMD[1]}" "-p"
  assert_equal "${AGENT_CMD[2]}" "${task}"
}

# --- Multi-vector sweep ---

@test "build_backend_command: multi-vector injection sweep (no canary created)" {
  local hostile_inputs=(
    '; rm -rf /'
    '$(cat /etc/passwd)'
    '`id`'
    '| cat /etc/shadow'
    '&& echo pwned'
    $'\n; echo injected'
    '|| touch /tmp/evil'
    '$(touch '"${TEST_TEMP}"'/sweep_canary)'
  )

  for input in "${hostile_inputs[@]}"; do
    build_backend_command "opencode" "manual" "${input}"
    "${AGENT_CMD[@]}" 2>/dev/null || true
  done

  [ ! -f "${TEST_TEMP}/sweep_canary" ]
}

@test "build_backend_command: newline in task does not split command" {
  local task=$'first line\nsecond line with ; rm -rf /'
  build_backend_command "opencode" "manual" "${task}"

  # Task should remain a single array element despite newlines
  assert_equal "${#AGENT_CMD[@]}" 3
  assert_equal "${AGENT_CMD[2]}" "${task}"
}
