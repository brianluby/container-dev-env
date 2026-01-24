#!/usr/bin/env bash
# Common test setup for notify.sh bats tests

# Create temporary directory for test artifacts
setup_test_env() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
  export TEST_CONFIG_DIR="${TEST_TEMP_DIR}/config"
  mkdir -p "${TEST_CONFIG_DIR}"
}

# Clean up temporary directory
teardown_test_env() {
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "${TEST_TEMP_DIR}" ]]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Generate a valid notify.yaml config file
# Usage: generate_config [ntfy_enabled] [slack_enabled] [quiet_enabled]
generate_config() {
  local ntfy_enabled="${1:-true}"
  local slack_enabled="${2:-false}"
  local quiet_enabled="${3:-false}"

  cat > "${TEST_CONFIG_DIR}/notify.yaml" << EOF
services:
  ntfy:
    enabled: ${ntfy_enabled}
  slack:
    enabled: ${slack_enabled}

priorities:
  progress: 2
  completed: 3
  failed: 4
  approval_needed: 5

quiet_hours:
  enabled: ${quiet_enabled}
  start: "22:00"
  end: "08:00"
  min_priority: 5

retry:
  max_attempts: 3
  base_delay: 2
EOF
  export NOTIFY_CONFIG="${TEST_CONFIG_DIR}/notify.yaml"
}

# Mock curl function that records calls
# Captures: URL, headers, body to files in TEST_TEMP_DIR
mock_curl() {
  curl() {
    local args=("$@")
    local url=""
    local headers=()
    local body=""
    local i=0

    while [[ $i -lt ${#args[@]} ]]; do
      case "${args[$i]}" in
        -H)
          i=$((i + 1))
          headers+=("${args[$i]}")
          ;;
        -d|--data)
          i=$((i + 1))
          body="${args[$i]}"
          ;;
        -o)
          i=$((i + 1))
          ;;
        -w)
          i=$((i + 1))
          # Return HTTP status code
          echo "200"
          ;;
        -s|-S|--fail-with-body)
          ;;
        *)
          if [[ "${args[$i]}" == http* ]]; then
            url="${args[$i]}"
          fi
          ;;
      esac
      i=$((i + 1))
    done

    # Record the call
    echo "${url}" >> "${TEST_TEMP_DIR}/curl_urls"
    printf '%s\n' "${headers[@]}" >> "${TEST_TEMP_DIR}/curl_headers"
    echo "${body}" >> "${TEST_TEMP_DIR}/curl_body"

    return 0
  }
  export -f curl
}

# Mock curl that returns a specific HTTP status code
# Usage: mock_curl_status 429
mock_curl_status() {
  local status_code="${1:-200}"
  export MOCK_HTTP_STATUS="${status_code}"

  curl() {
    local args=("$@")
    local url=""
    local headers=()
    local body=""
    local i=0

    while [[ $i -lt ${#args[@]} ]]; do
      case "${args[$i]}" in
        -H)
          i=$((i + 1))
          headers+=("${args[$i]}")
          ;;
        -d|--data)
          i=$((i + 1))
          body="${args[$i]}"
          ;;
        -w)
          i=$((i + 1))
          echo "${MOCK_HTTP_STATUS}"
          ;;
        -s|-S|--fail-with-body|-o)
          if [[ "${args[$i]}" == "-o" ]]; then
            i=$((i + 1))
          fi
          ;;
        *)
          if [[ "${args[$i]}" == http* ]]; then
            url="${args[$i]}"
          fi
          ;;
      esac
      i=$((i + 1))
    done

    echo "${url}" >> "${TEST_TEMP_DIR}/curl_urls"
    printf '%s\n' "${headers[@]}" >> "${TEST_TEMP_DIR}/curl_headers"
    echo "${body}" >> "${TEST_TEMP_DIR}/curl_body"

    return 0
  }
  export -f curl
}

# Mock sleep to avoid test delays
mock_sleep() {
  sleep() {
    echo "sleep $1" >> "${TEST_TEMP_DIR}/sleep_calls"
  }
  export -f sleep
}

# Mock date for quiet hours testing
# Usage: mock_date "2300" (sets current time to 23:00)
mock_date() {
  local mock_time="${1:-1200}"
  export MOCK_DATE_HHMM="${mock_time}"

  date() {
    if [[ "${1:-}" == "+%H%M" ]]; then
      echo "${MOCK_DATE_HHMM}"
    else
      command date "$@"
    fi
  }
  export -f date
}

# Get the project source directory
get_src_dir() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "${script_dir}/../../src" && pwd
}

# Source notify.sh functions without executing main
source_notify() {
  local src_dir
  src_dir="$(get_src_dir)"
  # shellcheck source=/dev/null
  NOTIFY_SOURCED=1 source "${src_dir}/notify.sh"
}

# Source notify-sanitize.sh functions
source_sanitize() {
  local src_dir
  src_dir="$(get_src_dir)"
  # shellcheck source=/dev/null
  source "${src_dir}/notify-sanitize.sh"
}
