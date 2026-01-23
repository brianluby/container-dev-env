#!/usr/bin/env bats
# Contract test: Action log JSONL format matches contract schema
load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}/logs"
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.config/agent"
  export WORKSPACE="${TEST_TMPDIR}/workspace"
  mkdir -p "${WORKSPACE}"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

_write_log() {
  source_lib log
  log_action "$@"
}

@test "action_log_format: entry is valid JSON" {
  _write_log "sess-001" "file_edit" "src/main.rs" "Edited main file" "success"
  local line
  line=$(head -1 "${AGENT_STATE_DIR}/logs/sess-001.jsonl")
  echo "${line}" | jq empty
}

@test "action_log_format: required fields present (timestamp, action, target, result)" {
  _write_log "sess-002" "command_exec" "cargo test" "Running tests" "success"
  local line
  line=$(head -1 "${AGENT_STATE_DIR}/logs/sess-002.jsonl")
  echo "${line}" | jq -e '.timestamp' > /dev/null
  echo "${line}" | jq -e '.action' > /dev/null
  echo "${line}" | jq -e '.target' > /dev/null
  echo "${line}" | jq -e '.result' > /dev/null
}

@test "action_log_format: timestamp is ISO 8601 UTC" {
  _write_log "sess-003" "decision" "backend" "Selected opencode" "success"
  local ts
  ts=$(head -1 "${AGENT_STATE_DIR}/logs/sess-003.jsonl" | jq -r '.timestamp')
  # Match YYYY-MM-DDTHH:MM:SSZ pattern
  [[ "${ts}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "action_log_format: action is valid enum" {
  _write_log "sess-004" "file_create" "new.txt" "Created file" "success"
  local action
  action=$(head -1 "${AGENT_STATE_DIR}/logs/sess-004.jsonl" | jq -r '.action')
  [[ "${action}" == "file_create" ]]
}

@test "action_log_format: result is valid enum (success/failure/skipped)" {
  _write_log "sess-005" "error" "api" "Rate limited" "failure"
  local result
  result=$(head -1 "${AGENT_STATE_DIR}/logs/sess-005.jsonl" | jq -r '.result')
  [[ "${result}" == "failure" || "${result}" == "success" || "${result}" == "skipped" ]]
}

@test "action_log_format: details field preserved" {
  _write_log "sess-006" "checkpoint" "stash@{0}" "Pre-task checkpoint" "success"
  local details
  details=$(head -1 "${AGENT_STATE_DIR}/logs/sess-006.jsonl" | jq -r '.details')
  [[ "${details}" == "Pre-task checkpoint" ]]
}

@test "action_log_format: sub_agent_spawn includes sub-agent ID as target" {
  _write_log "sess-007" "sub_agent_spawn" "sub-001" "Backend work: src/api/" "success"
  local target
  target=$(head -1 "${AGENT_STATE_DIR}/logs/sess-007.jsonl" | jq -r '.target')
  [[ "${target}" == "sub-001" ]]
}

@test "action_log_format: multiple entries form valid JSONL" {
  _write_log "sess-008" "session_start" "sess-008" "Starting" "success"
  _write_log "sess-008" "file_edit" "main.rs" "Edited" "success"
  _write_log "sess-008" "session_complete" "sess-008" "Done" "success"
  # Each line must be valid JSON
  while IFS= read -r line; do
    echo "${line}" | jq empty
  done < "${AGENT_STATE_DIR}/logs/sess-008.jsonl"
  # Must have exactly 3 lines
  local count
  count=$(wc -l < "${AGENT_STATE_DIR}/logs/sess-008.jsonl" | tr -d ' ')
  [[ "${count}" -eq 3 ]]
}

@test "action_log_format: credentials are redacted" {
  export ANTHROPIC_API_KEY="sk-ant-secret-key-12345"
  _write_log "sess-009" "error" "api" "Failed with key sk-ant-secret-key-12345" "failure"
  local details
  details=$(head -1 "${AGENT_STATE_DIR}/logs/sess-009.jsonl" | jq -r '.details')
  [[ "${details}" != *"sk-ant-secret-key-12345"* ]]
  [[ "${details}" == *"[REDACTED]"* ]]
}
