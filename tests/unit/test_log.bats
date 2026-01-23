#!/usr/bin/env bats
# Unit tests for src/agent/lib/log.sh
# Tests JSONL action log writing, reading, and credential filtering

load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}/logs"
  TEST_SESSION_ID="test-session-001"
  TEST_LOG_FILE="${AGENT_STATE_DIR}/logs/${TEST_SESSION_ID}.jsonl"
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- Append Entry ---

@test "log: appends valid JSONL entry to log file" {
  source_lib log
  run log_action "${TEST_SESSION_ID}" "file_edit" "src/main.sh" "Added error handling" "success"
  [[ "${status}" -eq 0 ]]
  assert_file_exists "${TEST_LOG_FILE}"
}

@test "log: entry contains required fields" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "src/main.sh" "Added error handling" "success"
  local entry
  entry=$(tail -1 "${TEST_LOG_FILE}")
  echo "${entry}" | jq -e '.timestamp' > /dev/null
  echo "${entry}" | jq -e '.action' > /dev/null
  echo "${entry}" | jq -e '.target' > /dev/null
  echo "${entry}" | jq -e '.details' > /dev/null
  echo "${entry}" | jq -e '.result' > /dev/null
}

@test "log: entry has ISO 8601 timestamp" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "src/main.sh" "test" "success"
  local ts
  ts=$(tail -1 "${TEST_LOG_FILE}" | jq -r '.timestamp')
  # ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
  [[ "${ts}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "log: entry action matches valid enum values" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "command_exec" "cargo test" "Running tests" "success"
  local action
  action=$(tail -1 "${TEST_LOG_FILE}" | jq -r '.action')
  [[ "${action}" == "command_exec" ]]
}

@test "log: appends multiple entries to same file" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "a.sh" "first" "success"
  log_action "${TEST_SESSION_ID}" "file_edit" "b.sh" "second" "success"
  local count
  count=$(wc -l < "${TEST_LOG_FILE}" | tr -d ' ')
  [[ "${count}" -eq 2 ]]
}

@test "log: each line is valid JSON" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "a.sh" "first" "success"
  log_action "${TEST_SESSION_ID}" "command_exec" "make test" "second" "failure"
  log_action "${TEST_SESSION_ID}" "checkpoint" "stash@{0}" "third" "success"
  assert_valid_jsonl "${TEST_LOG_FILE}"
}

# --- Read / Filter / Tail ---

@test "log: reads all entries from log file" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "a.sh" "first" "success"
  log_action "${TEST_SESSION_ID}" "file_edit" "b.sh" "second" "success"
  run read_log "${TEST_SESSION_ID}"
  [[ "${status}" -eq 0 ]]
  local line_count
  line_count=$(echo "${output}" | wc -l | tr -d ' ')
  [[ "${line_count}" -eq 2 ]]
}

@test "log: tail returns last N entries" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "a.sh" "one" "success"
  log_action "${TEST_SESSION_ID}" "file_edit" "b.sh" "two" "success"
  log_action "${TEST_SESSION_ID}" "file_edit" "c.sh" "three" "success"
  run tail_log "${TEST_SESSION_ID}" 2
  [[ "${status}" -eq 0 ]]
  local line_count
  line_count=$(echo "${output}" | wc -l | tr -d ' ')
  [[ "${line_count}" -eq 2 ]]
}

@test "log: filter by action type" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "a.sh" "edit" "success"
  log_action "${TEST_SESSION_ID}" "command_exec" "make" "cmd" "success"
  log_action "${TEST_SESSION_ID}" "file_edit" "b.sh" "edit2" "success"
  run filter_log "${TEST_SESSION_ID}" "file_edit"
  [[ "${status}" -eq 0 ]]
  local line_count
  line_count=$(echo "${output}" | wc -l | tr -d ' ')
  [[ "${line_count}" -eq 2 ]]
}

# --- Credential Filtering ---

@test "log: redacts ANTHROPIC_API_KEY from details" {
  export ANTHROPIC_API_KEY="sk-ant-api03-secret123"
  source_lib log
  log_action "${TEST_SESSION_ID}" "error" "api" "Error with key sk-ant-api03-secret123 failed" "failure"
  local entry
  entry=$(tail -1 "${TEST_LOG_FILE}")
  assert_output_not_contains "sk-ant-api03-secret123"
  echo "${entry}" | grep -qv "sk-ant-api03-secret123"
}

@test "log: redacts OPENAI_API_KEY from details" {
  export OPENAI_API_KEY="sk-proj-abc123xyz"
  source_lib log
  log_action "${TEST_SESSION_ID}" "error" "api" "Key sk-proj-abc123xyz is invalid" "failure"
  local entry
  entry=$(tail -1 "${TEST_LOG_FILE}")
  echo "${entry}" | grep -qv "sk-proj-abc123xyz"
}

@test "log: redacts any sk- prefixed token from target field" {
  export ANTHROPIC_API_KEY="sk-ant-longtoken456"
  source_lib log
  log_action "${TEST_SESSION_ID}" "error" "sk-ant-longtoken456" "api error" "failure"
  local entry
  entry=$(tail -1 "${TEST_LOG_FILE}")
  echo "${entry}" | grep -qv "sk-ant-longtoken456"
}

# --- Output Format ---

@test "log: text format outputs human-readable lines" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "src/main.sh" "Added handler" "success"
  run format_log_text "${TEST_SESSION_ID}"
  [[ "${status}" -eq 0 ]]
  assert_output_contains "file_edit"
  assert_output_contains "src/main.sh"
}

@test "log: json format outputs valid JSON array" {
  source_lib log
  log_action "${TEST_SESSION_ID}" "file_edit" "src/main.sh" "Added handler" "success"
  run format_log_json "${TEST_SESSION_ID}"
  [[ "${status}" -eq 0 ]]
  echo "${output}" | jq -e 'type == "array"' > /dev/null
}

@test "log: handles non-existent session gracefully" {
  source_lib log
  run read_log "nonexistent-session"
  [[ "${status}" -ne 0 ]]
}
