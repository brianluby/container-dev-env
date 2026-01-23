#!/usr/bin/env bash
# BATS test helper for agent wrapper tests
# Provides common setup, teardown, and assertion functions

# Resolve paths relative to the test file location
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/src/agent"
AGENT_SCRIPT="${SRC_DIR}/agent.sh"

# Temporary directory for test state
export TEST_TMPDIR=""

# Setup: Create isolated temp directory for each test
setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}/sessions" "${AGENT_STATE_DIR}/logs" "${AGENT_STATE_DIR}/bg"
}

# Teardown: Clean up temp directory
teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# Assert command exits with expected code
# Usage: assert_exit_code <expected> <command> [args...]
assert_exit_code() {
  local expected="$1"
  shift
  run "$@"
  if [[ "${status}" -ne "${expected}" ]]; then
    echo "Expected exit code ${expected}, got ${status}" >&2
    echo "Output: ${output}" >&2
    return 1
  fi
}

# Assert output contains expected string
# Usage: assert_output_contains <expected_substring>
assert_output_contains() {
  local expected="$1"
  if [[ "${output}" != *"${expected}"* ]]; then
    echo "Expected output to contain: ${expected}" >&2
    echo "Actual output: ${output}" >&2
    return 1
  fi
}

# Assert output does NOT contain a string (useful for credential checks)
# Usage: assert_output_not_contains <forbidden_substring>
assert_output_not_contains() {
  local forbidden="$1"
  if [[ "${output}" == *"${forbidden}"* ]]; then
    echo "Output must NOT contain: ${forbidden}" >&2
    echo "Actual output: ${output}" >&2
    return 1
  fi
}

# Assert file exists
# Usage: assert_file_exists <path>
assert_file_exists() {
  local filepath="$1"
  if [[ ! -f "${filepath}" ]]; then
    echo "Expected file to exist: ${filepath}" >&2
    return 1
  fi
}

# Assert file contains expected content
# Usage: assert_file_contains <path> <expected_substring>
assert_file_contains() {
  local filepath="$1"
  local expected="$2"
  if ! grep -q "${expected}" "${filepath}" 2>/dev/null; then
    echo "Expected file ${filepath} to contain: ${expected}" >&2
    return 1
  fi
}

# Assert valid JSON
# Usage: echo '{"key":"val"}' | assert_valid_json
assert_valid_json() {
  if ! jq empty 2>/dev/null; then
    echo "Output is not valid JSON" >&2
    echo "Input: $(cat)" >&2
    return 1
  fi
}

# Assert valid JSONL (each line is valid JSON)
# Usage: assert_valid_jsonl <filepath>
assert_valid_jsonl() {
  local filepath="$1"
  local line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ -n "${line}" ]] && ! echo "${line}" | jq empty 2>/dev/null; then
      echo "Invalid JSON on line ${line_num} of ${filepath}" >&2
      echo "Content: ${line}" >&2
      return 1
    fi
  done < "${filepath}"
}

# Create a mock git repository for checkpoint tests
# Usage: create_mock_repo <directory>
create_mock_repo() {
  local dir="$1"
  mkdir -p "${dir}"
  cd "${dir}" || return 1
  git init --quiet
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "initial" > file.txt
  git add file.txt
  git commit --quiet -m "initial commit"
  cd - > /dev/null || return 1
}

# Source agent library module for unit testing
# Usage: source_lib <module_name>  (e.g., source_lib config)
source_lib() {
  local module="$1"
  local lib_path="${SRC_DIR}/lib/${module}.sh"
  if [[ -f "${lib_path}" ]]; then
    # shellcheck source=/dev/null
    source "${lib_path}"
  else
    echo "Library module not found: ${lib_path}" >&2
    return 1
  fi
}
