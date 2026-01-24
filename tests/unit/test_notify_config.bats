#!/usr/bin/env bats

# Tests for config parsing functions in notify.sh
# TDD: These tests must FAIL before T007 implementation

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
}

teardown() {
  teardown_test_env
}

@test "parse_config: loads notify.yaml and extracts ntfy enabled state" {
  generate_config "true" "false"
  source_notify

  parse_config
  [[ "${NTFY_ENABLED}" == "true" ]]
}

@test "parse_config: loads notify.yaml and extracts slack enabled state" {
  generate_config "true" "true"
  source_notify

  parse_config
  [[ "${SLACK_ENABLED}" == "true" ]]
}

@test "parse_config: extracts priority mappings from config" {
  generate_config
  source_notify

  parse_config
  [[ "${PRIORITY_COMPLETED}" == "3" ]]
  [[ "${PRIORITY_FAILED}" == "4" ]]
  [[ "${PRIORITY_APPROVAL_NEEDED}" == "5" ]]
  [[ "${PRIORITY_PROGRESS}" == "2" ]]
}

@test "parse_config: extracts retry settings" {
  generate_config
  source_notify

  parse_config
  [[ "${RETRY_MAX_ATTEMPTS}" == "3" ]]
  [[ "${RETRY_BASE_DELAY}" == "2" ]]
}

@test "parse_config: extracts quiet hours settings" {
  generate_config "true" "false" "true"
  source_notify

  parse_config
  [[ "${QUIET_ENABLED}" == "true" ]]
  [[ "${QUIET_START}" == "2200" ]]
  [[ "${QUIET_END}" == "0800" ]]
  [[ "${QUIET_MIN_PRIORITY}" == "5" ]]
}

@test "parse_config: exits 1 when config file is missing" {
  export NOTIFY_CONFIG="${TEST_TEMP_DIR}/nonexistent.yaml"
  source_notify

  run parse_config
  [[ "$status" -eq 1 ]]
  [[ "$output" =~ "config" ]] || [[ "$output" =~ "not found" ]]
}

@test "parse_config: exits 1 when config file is malformed" {
  echo "not: valid: yaml: [[[" > "${TEST_CONFIG_DIR}/notify.yaml"
  export NOTIFY_CONFIG="${TEST_CONFIG_DIR}/notify.yaml"
  source_notify

  run parse_config
  [[ "$status" -eq 1 ]]
}

@test "parse_config: defaults ntfy enabled to false when not specified" {
  cat > "${TEST_CONFIG_DIR}/notify.yaml" << 'EOF'
services:
  slack:
    enabled: false
priorities:
  completed: 3
quiet_hours:
  enabled: false
retry:
  max_attempts: 3
  base_delay: 2
EOF
  export NOTIFY_CONFIG="${TEST_CONFIG_DIR}/notify.yaml"
  source_notify

  parse_config
  [[ "${NTFY_ENABLED}" == "false" ]]
}
