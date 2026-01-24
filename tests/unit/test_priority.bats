#!/usr/bin/env bats

# Tests for priority mapping in notify.sh
# T020 [US4]: Priority-based delivery tests

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  generate_config
  source_notify
  parse_config
}

teardown() {
  teardown_test_env
}

@test "resolve_priority: 'completed' maps to priority 3" {
  local result
  result="$(resolve_priority "completed")"
  [[ "${result}" == "3" ]]
}

@test "resolve_priority: 'failed' maps to priority 4" {
  local result
  result="$(resolve_priority "failed")"
  [[ "${result}" == "4" ]]
}

@test "resolve_priority: 'approval_needed' maps to priority 5" {
  local result
  result="$(resolve_priority "approval_needed")"
  [[ "${result}" == "5" ]]
}

@test "resolve_priority: 'progress' maps to priority 2" {
  local result
  result="$(resolve_priority "progress")"
  [[ "${result}" == "2" ]]
}

@test "resolve_priority: numeric priority 1-5 passes through" {
  local result
  result="$(resolve_priority "4")"
  [[ "${result}" == "4" ]]
}

@test "resolve_priority: numeric priority 1 passes through" {
  local result
  result="$(resolve_priority "1")"
  [[ "${result}" == "1" ]]
}

@test "resolve_priority: custom mapping in notify.yaml overrides defaults" {
  # Override config with custom mapping
  cat > "${TEST_CONFIG_DIR}/notify.yaml" << 'EOF'
services:
  ntfy:
    enabled: true
  slack:
    enabled: false
priorities:
  progress: 1
  completed: 2
  failed: 5
  approval_needed: 5
quiet_hours:
  enabled: false
retry:
  max_attempts: 3
  base_delay: 2
EOF
  export NOTIFY_CONFIG="${TEST_CONFIG_DIR}/notify.yaml"
  parse_config

  local result
  result="$(resolve_priority "completed")"
  [[ "${result}" == "2" ]]

  result="$(resolve_priority "failed")"
  [[ "${result}" == "5" ]]
}

@test "resolve_priority: unknown event type defaults to priority 3" {
  local result
  result="$(resolve_priority "unknown_event")"
  [[ "${result}" == "3" ]]
}

@test "resolve_priority: empty string defaults to priority 3" {
  local result
  result="$(resolve_priority "")"
  [[ "${result}" == "3" ]]
}
