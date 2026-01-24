#!/usr/bin/env bats

# Tests for Slack delivery in notify.sh
# T023 [US3]: Slack delivery tests

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  generate_config "true" "true"
  export NTFY_TOPIC="test-topic"
  export NTFY_TOKEN="tk_testtoken123"
  export NTFY_SERVER="https://ntfy.sh"
  export SLACK_WEBHOOK="https://hooks.slack.com/services/T123/B456/XXX"
  mock_curl
  source_notify
  parse_config
}

teardown() {
  teardown_test_env
}

@test "send_slack: POSTs to SLACK_WEBHOOK URL" {
  NOTIFY_MESSAGE="Task completed"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test Title"

  send_slack

  local url
  url="$(cat "${TEST_TEMP_DIR}/curl_urls")"
  [[ "${url}" == "https://hooks.slack.com/services/T123/B456/XXX" ]]
}

@test "send_slack: sends Content-Type application/json" {
  NOTIFY_MESSAGE="Task completed"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test Title"

  send_slack

  local headers
  headers="$(cat "${TEST_TEMP_DIR}/curl_headers")"
  [[ "${headers}" =~ "Content-Type: application/json" ]]
}

@test "send_slack: payload contains priority emoji, title, and message" {
  NOTIFY_MESSAGE="Build finished"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Build Status"

  send_slack

  local body
  body="$(cat "${TEST_TEMP_DIR}/curl_body")"
  [[ "${body}" =~ "Build finished" ]]
  [[ "${body}" =~ "Build Status" ]]
}

@test "send_slack: priority 5 uses red circle emoji" {
  NOTIFY_MESSAGE="Approval needed"
  NOTIFY_PRIORITY="5"
  NOTIFY_TITLE="Urgent"

  send_slack

  local body
  body="$(cat "${TEST_TEMP_DIR}/curl_body")"
  [[ "${body}" =~ "🔴" ]]
}

@test "send_slack: priority 4 uses orange circle emoji" {
  NOTIFY_MESSAGE="Build failed"
  NOTIFY_PRIORITY="4"
  NOTIFY_TITLE="Build"

  send_slack

  local body
  body="$(cat "${TEST_TEMP_DIR}/curl_body")"
  [[ "${body}" =~ "🟠" ]]
}

@test "send_slack: priority 3 uses green circle emoji" {
  NOTIFY_MESSAGE="Task done"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Task"

  send_slack

  local body
  body="$(cat "${TEST_TEMP_DIR}/curl_body")"
  [[ "${body}" =~ "🟢" ]]
}

@test "send_slack: priority 2 uses white square emoji" {
  NOTIFY_MESSAGE="Progress update"
  NOTIFY_PRIORITY="2"
  NOTIFY_TITLE="Progress"

  send_slack

  local body
  body="$(cat "${TEST_TEMP_DIR}/curl_body")"
  [[ "${body}" =~ "⬜" ]]
}

@test "send_slack: priority 1 uses white square emoji" {
  NOTIFY_MESSAGE="Minor update"
  NOTIFY_PRIORITY="1"
  NOTIFY_TITLE="Info"

  send_slack

  local body
  body="$(cat "${TEST_TEMP_DIR}/curl_body")"
  [[ "${body}" =~ "⬜" ]]
}
