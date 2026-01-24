#!/usr/bin/env bats

# Tests for ntfy.sh delivery in notify.sh
# T011 [US1]: Core delivery tests
# T012 [US2]: Priority-5 delivery tests

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  generate_config "true" "false"
  export NTFY_TOPIC="test-topic"
  export NTFY_TOKEN="tk_testtoken123"
  export NTFY_SERVER="https://ntfy.sh"
  mock_curl
  source_notify
}

teardown() {
  teardown_test_env
}

# ─── T011 [US1]: ntfy.sh delivery tests ─────────────────────────────────────

@test "send_ntfy: POSTs to correct URL (NTFY_SERVER/NTFY_TOPIC)" {
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test Title"

  send_ntfy

  local url
  url="$(cat "${TEST_TEMP_DIR}/curl_urls")"
  [[ "${url}" == "https://ntfy.sh/test-topic" ]]
}

@test "send_ntfy: includes Authorization Bearer header" {
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test Title"

  send_ntfy

  local headers
  headers="$(cat "${TEST_TEMP_DIR}/curl_headers")"
  [[ "${headers}" =~ "Authorization: Bearer tk_testtoken123" ]]
}

@test "send_ntfy: includes X-Priority header matching priority argument" {
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="4"
  NOTIFY_TITLE="Test Title"

  send_ntfy

  local headers
  headers="$(cat "${TEST_TEMP_DIR}/curl_headers")"
  [[ "${headers}" =~ "X-Priority: 4" ]]
}

@test "send_ntfy: includes X-Title header matching title argument" {
  parse_config
  NOTIFY_MESSAGE="Test message"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Build Failed"

  send_ntfy

  local headers
  headers="$(cat "${TEST_TEMP_DIR}/curl_headers")"
  [[ "${headers}" =~ "X-Title: Build Failed" ]]
}

@test "send_ntfy: sends message in request body" {
  parse_config
  NOTIFY_MESSAGE="Refactoring complete: 12 files updated"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test Title"

  send_ntfy

  local body
  body="$(cat "${TEST_TEMP_DIR}/curl_body")"
  [[ "${body}" =~ "Refactoring complete: 12 files updated" ]]
}

@test "send_ntfy: uses custom NTFY_SERVER when configured" {
  export NTFY_SERVER="https://my-ntfy.example.com"
  parse_config
  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  send_ntfy

  local url
  url="$(cat "${TEST_TEMP_DIR}/curl_urls")"
  [[ "${url}" == "https://my-ntfy.example.com/test-topic" ]]
}

@test "send_ntfy: rejects http:// URLs (HTTPS enforced)" {
  export NTFY_SERVER="http://insecure.example.com"
  parse_config
  NOTIFY_MESSAGE="Test"
  NOTIFY_PRIORITY="3"
  NOTIFY_TITLE="Test"

  run send_ntfy
  [[ "$status" -ne 0 ]]
  [[ "$output" =~ "HTTPS" ]] || [[ "$output" =~ "https" ]]
}

# ─── T012 [US2]: Priority-5 delivery tests ──────────────────────────────────

@test "send_ntfy: priority 5 sends X-Priority: 5" {
  parse_config
  NOTIFY_MESSAGE="Delete 47 test files? Awaiting approval"
  NOTIFY_PRIORITY="5"
  NOTIFY_TITLE="Approval Needed"

  send_ntfy

  local headers
  headers="$(cat "${TEST_TEMP_DIR}/curl_headers")"
  [[ "${headers}" =~ "X-Priority: 5" ]]
}

@test "send_ntfy: priority 5 with 'Approval Needed' title maps to X-Title correctly" {
  parse_config
  NOTIFY_MESSAGE="Deploy to staging?"
  NOTIFY_PRIORITY="5"
  NOTIFY_TITLE="Approval Needed"

  send_ntfy

  local headers
  headers="$(cat "${TEST_TEMP_DIR}/curl_headers")"
  [[ "${headers}" =~ "X-Title: Approval Needed" ]]
}
