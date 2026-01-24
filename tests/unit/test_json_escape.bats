#!/usr/bin/env bats
# test_json_escape.bats — JSON injection prevention tests
# Verifies: FR-002 (safe JSON construction in session and log management)

load '../unit/.bats-battery/bats-support/load'
load '../unit/.bats-battery/bats-assert/load'

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

setup() {
  TEST_TEMP="$(mktemp -d)"
  export TEST_TEMP
  export AGENT_STATE_DIR="${TEST_TEMP}/agent"
  mkdir -p "${AGENT_STATE_DIR}/sessions" "${AGENT_STATE_DIR}/logs"

  source "${REPO_ROOT}/src/agent/lib/session.sh"
  source "${REPO_ROOT}/src/agent/lib/log.sh"
}

teardown() {
  rm -rf "${TEST_TEMP}"
}

# --- Session creation JSON safety ---

@test "create_session: task with double quotes produces valid JSON" {
  local session_id
  session_id=$(create_session "opencode" 'Task with "quotes" inside' "manual")

  local session_path="${AGENT_STATE_DIR}/sessions/${session_id}.json"
  run jq empty "${session_path}"
  assert_success
}

@test "create_session: task with backslashes produces valid JSON" {
  local session_id
  session_id=$(create_session "opencode" 'Path is C:\Users\dev\file.txt' "manual")

  local session_path="${AGENT_STATE_DIR}/sessions/${session_id}.json"
  run jq empty "${session_path}"
  assert_success

  # Verify the backslashes are preserved in the value
  run jq -r '.task_description' "${session_path}"
  assert_output 'Path is C:\Users\dev\file.txt'
}

@test "create_session: task with newlines produces valid JSON" {
  local task=$'Line one\nLine two\nLine three'
  local session_id
  session_id=$(create_session "opencode" "${task}" "manual")

  local session_path="${AGENT_STATE_DIR}/sessions/${session_id}.json"
  run jq empty "${session_path}"
  assert_success

  # Verify newlines are preserved (jq -r outputs them as actual newlines)
  run jq -r '.task_description' "${session_path}"
  assert_output "${task}"
}

@test "create_session: task with control characters produces valid JSON" {
  local task=$'Tab\there and null\x01 control char'
  local session_id
  session_id=$(create_session "opencode" "${task}" "manual")

  local session_path="${AGENT_STATE_DIR}/sessions/${session_id}.json"
  run jq empty "${session_path}"
  assert_success
}

@test "create_session: all fields are properly typed" {
  local session_id
  session_id=$(create_session "claude" "test task" "auto")

  local session_path="${AGENT_STATE_DIR}/sessions/${session_id}.json"

  # Verify expected fields exist and have correct types
  run jq -e '.id' "${session_path}"
  assert_success
  run jq -e '.backend == "claude"' "${session_path}"
  assert_success
  run jq -e '.status == "active"' "${session_path}"
  assert_success
  run jq -e '.approval_mode == "auto"' "${session_path}"
  assert_success
  run jq -e '.ended_at == null' "${session_path}"
  assert_success
  run jq -e '.checkpoints | type == "array"' "${session_path}"
  assert_success
}

# --- Log action JSON safety ---

@test "log_action: target with quotes produces valid JSONL" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  log_action "${session_id}" "file_edit" '/path/with "special" chars' "edited file" "success"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  # Each line must be valid JSON
  while IFS= read -r line; do
    echo "${line}" | jq empty
  done < "${log_path}"
}

@test "log_action: details with backslashes and newlines produces valid JSONL" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  local details=$'line1\nline2 with C:\\path\\file'
  log_action "${session_id}" "command_exec" "/some/target" "${details}"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  run jq empty "${log_path}"
  assert_success

  # Verify no raw newlines break the JSONL format (one object per line)
  local line_count
  line_count=$(wc -l < "${log_path}" | tr -d ' ')
  assert_equal "${line_count}" "1"
}

@test "log_action: null result produces valid JSON with null value" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  log_action "${session_id}" "decision" "target" "details" "null"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  run jq -e '.result == null' "${log_path}"
  assert_success
}

@test "log_action: non-null result is a string" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  log_action "${session_id}" "file_create" "target" "details" "success"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  run jq -e '.result == "success"' "${log_path}"
  assert_success
}

@test "log_action: checkpoint_id null produces JSON null" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  log_action "${session_id}" "checkpoint" "target" "details" "success" "null"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  run jq -e '.checkpoint_id == null' "${log_path}"
  assert_success
}

@test "log_action: checkpoint_id string is properly quoted" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  log_action "${session_id}" "checkpoint" "target" "details" "success" "cp-123-abc"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  run jq -e '.checkpoint_id == "cp-123-abc"' "${log_path}"
  assert_success
}

@test "log_action: hostile JSON injection in target field" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  # Attempt to break out of JSON structure
  local hostile_target='","evil":"injected","x":"'
  log_action "${session_id}" "file_edit" "${hostile_target}" "normal details"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  run jq empty "${log_path}"
  assert_success

  # The hostile content should be the literal value of target, not parsed as JSON structure
  run jq -r '.target' "${log_path}"
  assert_output "${hostile_target}"
}

@test "log_action: multiple entries maintain JSONL format" {
  local session_id
  session_id=$(create_session "opencode" "test" "manual")

  log_action "${session_id}" "session_start" "s1" "Starting"
  log_action "${session_id}" "file_edit" 'file "with" quotes' "editing"
  log_action "${session_id}" "session_complete" "s1" "Done" "success"

  local log_path="${AGENT_STATE_DIR}/logs/${session_id}.jsonl"
  local line_count
  line_count=$(wc -l < "${log_path}" | tr -d ' ')
  assert_equal "${line_count}" "3"

  # All lines must be valid JSON
  while IFS= read -r line; do
    echo "${line}" | jq empty || fail "Invalid JSON line: ${line}"
  done < "${log_path}"
}
