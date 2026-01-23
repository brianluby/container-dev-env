#!/usr/bin/env bats
load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}/sessions" "${AGENT_STATE_DIR}/logs"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

@test "session: creates session with valid JSON" {
  source_lib session
  local id
  id=$(create_session "opencode" "Fix bug" "manual")
  [[ -n "${id}" ]]
  assert_file_exists "${AGENT_STATE_DIR}/sessions/${id}.json"
  jq empty "${AGENT_STATE_DIR}/sessions/${id}.json"
}

@test "session: created session has active status" {
  source_lib session
  local id
  id=$(create_session "opencode" "Test task" "auto")
  local status
  status=$(jq -r '.status' "${AGENT_STATE_DIR}/sessions/${id}.json")
  [[ "${status}" == "active" ]]
}

@test "session: created session stores backend and mode" {
  source_lib session
  local id
  id=$(create_session "claude" "Complex task" "hybrid")
  local backend mode
  backend=$(jq -r '.backend' "${AGENT_STATE_DIR}/sessions/${id}.json")
  mode=$(jq -r '.approval_mode' "${AGENT_STATE_DIR}/sessions/${id}.json")
  [[ "${backend}" == "claude" ]]
  [[ "${mode}" == "hybrid" ]]
}

@test "session: update status to completed sets ended_at" {
  source_lib session
  local id
  id=$(create_session "opencode" "Task" "manual")
  update_session_status "${id}" "completed"
  local status ended
  status=$(jq -r '.status' "${AGENT_STATE_DIR}/sessions/${id}.json")
  ended=$(jq -r '.ended_at' "${AGENT_STATE_DIR}/sessions/${id}.json")
  [[ "${status}" == "completed" ]]
  [[ "${ended}" != "null" ]]
}

@test "session: update status to paused does not set ended_at" {
  source_lib session
  local id
  id=$(create_session "opencode" "Task" "manual")
  update_session_status "${id}" "paused"
  local ended
  ended=$(jq -r '.ended_at' "${AGENT_STATE_DIR}/sessions/${id}.json")
  [[ "${ended}" == "null" ]]
}

@test "session: list sessions returns all" {
  source_lib session
  create_session "opencode" "Task 1" "manual" > /dev/null
  create_session "claude" "Task 2" "auto" > /dev/null
  run list_sessions "all"
  [[ "${status}" -eq 0 ]]
  local count
  count=$(echo "${output}" | wc -l | tr -d ' ')
  [[ "${count}" -eq 2 ]]
}

@test "session: list sessions filters by status" {
  source_lib session
  local id1 id2
  id1=$(create_session "opencode" "Active task" "manual")
  id2=$(create_session "claude" "Done task" "auto")
  update_session_status "${id2}" "completed"
  run list_sessions "active"
  [[ "${status}" -eq 0 ]]
  local count
  count=$(echo "${output}" | wc -l | tr -d ' ')
  [[ "${count}" -eq 1 ]]
}

@test "session: get_session fails for non-existent session" {
  source_lib session
  run get_session "nonexistent-id"
  [[ "${status}" -ne 0 ]]
}

@test "session: handles corrupted session file" {
  source_lib session
  echo "not json" > "${AGENT_STATE_DIR}/sessions/corrupt.json"
  run get_session "corrupt"
  [[ "${status}" -ne 0 ]]
  assert_output_contains "corrupted"
}

@test "session: find_latest_session returns most recent active" {
  source_lib session
  local id1 id2
  id1=$(create_session "opencode" "First" "manual")
  sleep 1
  id2=$(create_session "opencode" "Second" "manual")
  run find_latest_session "active"
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${id2}" ]]
}
