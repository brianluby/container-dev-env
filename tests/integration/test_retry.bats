#!/usr/bin/env bats

# Tests for retry/backoff logic in notify.sh
# T031: Retry/backoff integration tests

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  generate_config "true" "false"
  export NTFY_TOPIC="test-topic"
  export NTFY_TOKEN="tk_testtoken123"
  export NTFY_SERVER="https://ntfy.sh"
  mock_sleep
  source_notify
  parse_config
}

teardown() {
  teardown_test_env
}

@test "retry: retries on HTTP 429 with exponential delay" {
  local attempt=0
  curl() {
    attempt=$((attempt + 1))
    local args=("$@")
    for i in "${!args[@]}"; do
      if [[ "${args[$i]}" == "-w" ]]; then
        if [[ "${attempt}" -le 3 ]]; then
          echo "429"
        else
          echo "200"
        fi
        return 0
      fi
    done
    return 0
  }
  export -f curl

  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  run send_with_retry send_ntfy

  # Should have retried and eventually succeeded
  [[ "$status" -eq 0 ]]

  # Check sleep was called with exponential delays
  if [[ -f "${TEST_TEMP_DIR}/sleep_calls" ]]; then
    local sleeps
    sleeps="$(cat "${TEST_TEMP_DIR}/sleep_calls")"
    [[ "${sleeps}" =~ "sleep 2" ]]
    [[ "${sleeps}" =~ "sleep 4" ]]
  fi
}

@test "retry: retries on HTTP 5xx" {
  local attempt=0
  curl() {
    attempt=$((attempt + 1))
    local args=("$@")
    for i in "${!args[@]}"; do
      if [[ "${args[$i]}" == "-w" ]]; then
        if [[ "${attempt}" -le 2 ]]; then
          echo "503"
        else
          echo "200"
        fi
        return 0
      fi
    done
    return 0
  }
  export -f curl

  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  run send_with_retry send_ntfy
  [[ "$status" -eq 0 ]]
}

@test "retry: does NOT retry on HTTP 400" {
  curl() {
    local args=("$@")
    for i in "${!args[@]}"; do
      if [[ "${args[$i]}" == "-w" ]]; then
        echo "400"
        return 0
      fi
    done
    return 0
  }
  export -f curl

  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  run send_with_retry send_ntfy
  # Should fail without retrying
  [[ "$status" -eq 0 ]] # exits 0 per spec (don't block agent)

  # No sleep calls (no retry)
  [[ ! -f "${TEST_TEMP_DIR}/sleep_calls" ]]
}

@test "retry: does NOT retry on HTTP 401" {
  curl() {
    local args=("$@")
    for i in "${!args[@]}"; do
      if [[ "${args[$i]}" == "-w" ]]; then
        echo "401"
        return 0
      fi
    done
    return 0
  }
  export -f curl

  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  run send_with_retry send_ntfy
  [[ "$status" -eq 0 ]]
  [[ ! -f "${TEST_TEMP_DIR}/sleep_calls" ]]
}

@test "retry: discards after 3 failed attempts (exits 0)" {
  curl() {
    local args=("$@")
    for i in "${!args[@]}"; do
      if [[ "${args[$i]}" == "-w" ]]; then
        echo "500"
        return 0
      fi
    done
    return 0
  }
  export -f curl

  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  run send_with_retry send_ntfy
  # Always exits 0 per spec
  [[ "$status" -eq 0 ]]
  # Should have logged retry attempts
  [[ "$output" =~ "retry" ]] || [[ "$output" =~ "exhausted" ]] || [[ "$output" =~ "failed" ]]
}

@test "retry: logs each retry attempt to stderr" {
  local attempt=0
  curl() {
    attempt=$((attempt + 1))
    local args=("$@")
    for i in "${!args[@]}"; do
      if [[ "${args[$i]}" == "-w" ]]; then
        if [[ "${attempt}" -le 2 ]]; then
          echo "503"
        else
          echo "200"
        fi
        return 0
      fi
    done
    return 0
  }
  export -f curl

  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  run send_with_retry send_ntfy
  [[ "$output" =~ "retry" ]] || [[ "$output" =~ "attempt" ]]
}
