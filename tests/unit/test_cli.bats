#!/usr/bin/env bats

# Tests for CLI argument parsing in notify.sh
# TDD: These tests must FAIL before T008 implementation

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  generate_config
  # Set required env vars so we don't fail on env validation
  export NTFY_TOPIC="test-topic"
  export NTFY_TOKEN="tk_testtoken123"
  export NTFY_SERVER="https://ntfy.sh"
  mock_curl
}

teardown() {
  teardown_test_env
}

@test "CLI: message is required — exits 2 if missing" {
  source_notify

  run parse_args
  [[ "$status" -eq 2 ]]
  [[ "$output" =~ "message" ]] || [[ "$output" =~ "required" ]]
}

@test "CLI: empty string message — exits 2" {
  source_notify

  run parse_args ""
  [[ "$status" -eq 2 ]]
}

@test "CLI: priority defaults to 3 when not specified" {
  source_notify

  parse_args "Test message"
  [[ "${NOTIFY_PRIORITY}" == "3" ]]
}

@test "CLI: priority validates 1-5 range — exits 2 if 0" {
  source_notify

  run parse_args "Test message" "0"
  [[ "$status" -eq 2 ]]
  [[ "$output" =~ "priority" ]] || [[ "$output" =~ "1-5" ]]
}

@test "CLI: priority validates 1-5 range — exits 2 if 6" {
  source_notify

  run parse_args "Test message" "6"
  [[ "$status" -eq 2 ]]
}

@test "CLI: priority validates 1-5 range — exits 2 if non-numeric" {
  source_notify

  run parse_args "Test message" "abc"
  [[ "$status" -eq 2 ]]
}

@test "CLI: priority 1 is valid" {
  source_notify

  parse_args "Test message" "1"
  [[ "${NOTIFY_PRIORITY}" == "1" ]]
}

@test "CLI: priority 5 is valid" {
  source_notify

  parse_args "Test message" "5"
  [[ "${NOTIFY_PRIORITY}" == "5" ]]
}

@test "CLI: title defaults to 'Agent Notification' when not specified" {
  source_notify

  parse_args "Test message"
  [[ "${NOTIFY_TITLE}" == "Agent Notification" ]]
}

@test "CLI: title accepts custom value" {
  source_notify

  parse_args "Test message" "3" "Custom Title"
  [[ "${NOTIFY_TITLE}" == "Custom Title" ]]
}

@test "CLI: --help flag shows usage" {
  source_notify

  run parse_args "--help"
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ "Usage" ]] || [[ "$output" =~ "notify.sh" ]]
}

@test "CLI: message with spaces is preserved" {
  source_notify

  parse_args "This is a message with spaces"
  [[ "${NOTIFY_MESSAGE}" == "This is a message with spaces" ]]
}
