#!/usr/bin/env bats
load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}/sessions" "${AGENT_STATE_DIR}/logs"
  # Create a test session
  cat > "${AGENT_STATE_DIR}/sessions/test-usage.json" <<'EOF'
{
  "id": "test-usage",
  "backend": "opencode",
  "started_at": "2026-01-22T10:00:00Z",
  "ended_at": null,
  "status": "active",
  "task_description": "Test task",
  "approval_mode": "auto",
  "workspace": "/workspace",
  "checkpoints": [],
  "token_usage": {
    "input_tokens": 0,
    "output_tokens": 0,
    "total_tokens": 0,
    "estimated_cost_usd": 0.0,
    "model": "",
    "provider": ""
  },
  "action_log_path": ""
}
EOF
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

@test "usage: compute_cost returns numeric value" {
  source_lib usage
  run compute_cost "claude-sonnet-4-20250514" 1000 500
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ^[0-9] ]]
}

@test "usage: compute_cost uses default pricing for unknown model" {
  source_lib usage
  run compute_cost "unknown-model" 1000000 500000
  [[ "${status}" -eq 0 ]]
  [[ "${output}" != "0.0000" ]]
}

@test "usage: update_session_usage increments tokens" {
  source_lib usage
  update_session_usage "test-usage" 1000 500 "claude-sonnet-4-20250514" "anthropic"
  local input
  input=$(jq -r '.token_usage.input_tokens' "${AGENT_STATE_DIR}/sessions/test-usage.json")
  [[ "${input}" -eq 1000 ]]
}

@test "usage: update_session_usage accumulates across calls" {
  source_lib usage
  update_session_usage "test-usage" 1000 500 "claude-sonnet-4-20250514" "anthropic"
  update_session_usage "test-usage" 2000 1000 "claude-sonnet-4-20250514" "anthropic"
  local total
  total=$(jq -r '.token_usage.total_tokens' "${AGENT_STATE_DIR}/sessions/test-usage.json")
  [[ "${total}" -eq 4500 ]]
}

@test "usage: update_session_usage sets model and provider" {
  source_lib usage
  update_session_usage "test-usage" 100 50 "gpt-4o" "openai"
  local model provider
  model=$(jq -r '.token_usage.model' "${AGENT_STATE_DIR}/sessions/test-usage.json")
  provider=$(jq -r '.token_usage.provider' "${AGENT_STATE_DIR}/sessions/test-usage.json")
  [[ "${model}" == "gpt-4o" ]]
  [[ "${provider}" == "openai" ]]
}

@test "usage: get_session_usage text format shows tokens" {
  source_lib usage
  update_session_usage "test-usage" 5000 2000 "claude-sonnet-4-20250514" "anthropic"
  run get_session_usage "test-usage" "text"
  [[ "${status}" -eq 0 ]]
  assert_output_contains "5000"
  assert_output_contains "2000"
}

@test "usage: get_session_usage json format is valid JSON" {
  source_lib usage
  update_session_usage "test-usage" 1000 500 "claude-sonnet-4-20250514" "anthropic"
  run get_session_usage "test-usage" "json"
  [[ "${status}" -eq 0 ]]
  echo "${output}" | jq empty
}

@test "usage: get_session_usage fails for missing session" {
  source_lib usage
  run get_session_usage "nonexistent" "text"
  [[ "${status}" -ne 0 ]]
}
