#!/usr/bin/env bats

# Tests for multi-service dispatch in notify.sh
# T024 [US3]: Multi-service integration tests

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  export NTFY_TOPIC="test-topic"
  export NTFY_TOKEN="tk_testtoken123"
  export NTFY_SERVER="https://ntfy.sh"
  export SLACK_WEBHOOK="https://hooks.slack.com/services/T123/B456/XXX"
  mock_curl
  source_notify
}

teardown() {
  teardown_test_env
}

@test "multi-service: both services called when both enabled" {
  generate_config "true" "true"
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  dispatch_services

  local urls
  urls="$(cat "${TEST_TEMP_DIR}/curl_urls")"
  [[ "${urls}" =~ "ntfy.sh/test-topic" ]]
  [[ "${urls}" =~ "hooks.slack.com" ]]
}

@test "multi-service: only ntfy called when slack disabled" {
  generate_config "true" "false"
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  dispatch_services

  local urls
  urls="$(cat "${TEST_TEMP_DIR}/curl_urls")"
  [[ "${urls}" =~ "ntfy.sh/test-topic" ]]
  [[ "${urls}" != *"hooks.slack.com"* ]]
}

@test "multi-service: only slack called when ntfy disabled" {
  generate_config "false" "true"
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  dispatch_services

  local urls
  urls="$(cat "${TEST_TEMP_DIR}/curl_urls")"
  [[ "${urls}" != *"ntfy.sh"* ]]
  [[ "${urls}" =~ "hooks.slack.com" ]]
}

@test "multi-service: disabled service is skipped" {
  generate_config "false" "false"
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  dispatch_services

  [[ ! -f "${TEST_TEMP_DIR}/curl_urls" ]]
}

@test "multi-service: ntfy failure doesn't block Slack delivery" {
  generate_config "true" "true"
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  # Mock curl to fail for ntfy but succeed for Slack
  local call_count=0
  curl() {
    call_count=$((call_count + 1))
    local args=("$@")
    local url=""
    for arg in "${args[@]}"; do
      if [[ "${arg}" == http* ]]; then
        url="${arg}"
        break
      fi
    done

    echo "${url}" >> "${TEST_TEMP_DIR}/curl_urls"

    # Check for -w flag and return status
    for i in "${!args[@]}"; do
      if [[ "${args[$i]}" == "-w" ]]; then
        if [[ "${url}" =~ "ntfy.sh" ]]; then
          echo "500"
        else
          echo "200"
        fi
        return 0
      fi
    done
    return 0
  }
  export -f curl

  dispatch_services

  local urls
  urls="$(cat "${TEST_TEMP_DIR}/curl_urls")"
  [[ "${urls}" =~ "hooks.slack.com" ]]
}
