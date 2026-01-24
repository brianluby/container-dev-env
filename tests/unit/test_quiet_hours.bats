#!/usr/bin/env bats

# Tests for quiet hours in notify.sh
# T027 [US6]: Quiet hours tests

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  generate_config "true" "false" "true"
  source_notify
  parse_config
  mock_curl
}

teardown() {
  teardown_test_env
}

@test "quiet hours: during quiet hours, priority 3 is suppressed" {
  mock_date "2300"
  NOTIFY_PRIORITY="3"

  run should_suppress
  [[ "$status" -eq 0 ]] # 0 = suppress
}

@test "quiet hours: during quiet hours, priority 5 is delivered (bypass)" {
  mock_date "2300"
  NOTIFY_PRIORITY="5"

  run should_suppress
  [[ "$status" -eq 1 ]] # 1 = don't suppress
}

@test "quiet hours: outside quiet hours, all priorities delivered" {
  mock_date "1200"
  NOTIFY_PRIORITY="2"

  run should_suppress
  [[ "$status" -eq 1 ]] # 1 = don't suppress
}

@test "quiet hours: overnight window (22:00-08:00) detected at 23:00" {
  mock_date "2300"

  run is_quiet_hours
  [[ "$status" -eq 0 ]] # 0 = in quiet hours
}

@test "quiet hours: overnight window (22:00-08:00) detected at 07:00" {
  mock_date "0700"

  run is_quiet_hours
  [[ "$status" -eq 0 ]] # 0 = in quiet hours
}

@test "quiet hours: overnight window (22:00-08:00) not active at 12:00" {
  mock_date "1200"

  run is_quiet_hours
  [[ "$status" -eq 1 ]] # 1 = not in quiet hours
}

@test "quiet hours: same-day window (09:00-17:00) correctly detected" {
  # Configure same-day quiet hours
  cat > "${TEST_CONFIG_DIR}/notify.yaml" << 'EOF'
services:
  ntfy:
    enabled: true
  slack:
    enabled: false
priorities:
  completed: 3
quiet_hours:
  enabled: true
  start: "09:00"
  end: "17:00"
  min_priority: 5
retry:
  max_attempts: 3
  base_delay: 2
EOF
  export NOTIFY_CONFIG="${TEST_CONFIG_DIR}/notify.yaml"
  parse_config

  mock_date "1200"
  run is_quiet_hours
  [[ "$status" -eq 0 ]] # 0 = in quiet hours
}

@test "quiet hours: disabled quiet hours passes all notifications" {
  # Reconfigure with quiet hours disabled
  generate_config "true" "false" "false"
  parse_config

  mock_date "2300"
  NOTIFY_PRIORITY="1"

  run should_suppress
  [[ "$status" -eq 1 ]] # 1 = don't suppress
}

@test "quiet hours: suppressed notifications log to stderr" {
  mock_date "2300"
  NOTIFY_PRIORITY="3"
  NOTIFY_MESSAGE="Test message"

  run check_quiet_hours
  [[ "$output" =~ "quiet hours" ]] || [[ "$output" =~ "suppressed" ]]
}
