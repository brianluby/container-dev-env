#!/usr/bin/env bash
# verify-voice-input.sh — Health check for voice input system
# Usage: ./verify-voice-input.sh [--json]
# Verifies that the voice input system is properly configured.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/config-validator.sh
source "${SCRIPT_DIR}/lib/config-validator.sh"
# shellcheck source=lib/prerequisites.sh
source "${SCRIPT_DIR}/lib/prerequisites.sh"

# ─── Options ──────────────────────────────────────────────────────────────────

JSON_OUTPUT=false

usage() {
  cat <<'EOF'
Usage: verify-voice-input.sh [--json]

Health check to verify voice input system is properly configured.

Options:
  --json    Output results in JSON format
  --help    Show this help message

Exit Codes:
  0  All checks pass
  1  One or more checks failed

Checks Performed:
  1. Settings file exists and is valid YAML
  2. Selected voice tool is installed
  3. Voice tool is running (process check)
  4. Microphone permissions granted
  5. Vocabulary file is valid (if configured)
  6. (If cleanup_tier=local_llm) Ollama is accessible and model available
  7. (If cleanup_tier=cloud) API key env var is set
EOF
}

# ─── Check Runner ─────────────────────────────────────────────────────────────

CHECKS_PASSED=0
CHECKS_TOTAL=0
TOOL_NAME=""
RESULTS=()

run_check() {
  local name="$1"
  local result_var="$2"
  shift 2

  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))

  local stderr_file
  stderr_file="$(mktemp)"

  if "$@" 2>"${stderr_file}"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    RESULTS+=("${name}=true")
    eval "${result_var}=true"
    rm -f "${stderr_file}"
  else
    if [[ -s "${stderr_file}" ]]; then
      echo "Check '${name}' failed with error:" >&2
      cat "${stderr_file}" >&2
    fi
    rm -f "${stderr_file}"
    RESULTS+=("${name}=false")
    eval "${result_var}=false"
  fi
}

# ─── Main Checks ─────────────────────────────────────────────────────────────

run_all_checks() {
  local tool_installed_result=""
  local tool_running_result=""
  local mic_permission_result=""
  local settings_valid_result=""
  local vocabulary_valid_result=""
  local cleanup_available_result=""

  # Check 1: Settings file exists and is valid
  run_check "settings_valid" settings_valid_result validate_settings

  # Read tool from settings (default to superwhisper if settings invalid)
  if [[ -f "$VOICE_INPUT_SETTINGS" ]]; then
    TOOL_NAME=$(yaml_get "tool" "$VOICE_INPUT_SETTINGS")
  fi
  TOOL_NAME="${TOOL_NAME:-superwhisper}"

  # Check 2: Voice tool installed
  run_check "tool_installed" tool_installed_result check_tool_installed "$TOOL_NAME"

  # Check 3: Voice tool running
  run_check "tool_running" tool_running_result check_tool_running "$TOOL_NAME"

  # Check 4: Microphone permission
  run_check "mic_permission" mic_permission_result check_mic_permission "$TOOL_NAME"

  # Check 5: Vocabulary valid
  check_vocabulary_valid() {
    if [[ ! -f "$VOICE_INPUT_VOCABULARY" ]]; then
      log_warn "Vocabulary file not found: $VOICE_INPUT_VOCABULARY"
      return 1
    fi
    # Check it has version and terms fields
    if grep -q "^version:" "$VOICE_INPUT_VOCABULARY" && grep -q "^terms:" "$VOICE_INPUT_VOCABULARY"; then
      log_success "Vocabulary file is valid"
      return 0
    fi
    log_error "Vocabulary file missing required fields"
    return 1
  }
  run_check "vocabulary_valid" vocabulary_valid_result check_vocabulary_valid

  # Check 6/7: Cleanup availability (conditional)
  local cleanup_tier=""
  if [[ -f "$VOICE_INPUT_SETTINGS" ]]; then
    cleanup_tier=$(yaml_get "cleanup_tier" "$VOICE_INPUT_SETTINGS")
  fi

  check_cleanup_available() {
    case "${cleanup_tier}" in
      none | rules)
        log_success "Cleanup tier '$cleanup_tier' requires no external dependencies"
        return 0
        ;;
      local_llm)
        check_ollama_installed && check_ollama_running
        ;;
      cloud)
        local api_key_env
        api_key_env=$(yaml_get "cleanup_cloud_api_key_env" "$VOICE_INPUT_SETTINGS")
        check_cloud_api_key "$api_key_env"
        ;;
      *)
        log_success "No cleanup tier configured"
        return 0
        ;;
    esac
  }
  run_check "cleanup_available" cleanup_available_result check_cleanup_available

  # Output results
  if [[ "$JSON_OUTPUT" == true ]]; then
    print_json_output "$tool_installed_result" "$tool_running_result" \
      "$mic_permission_result" "$settings_valid_result" \
      "$vocabulary_valid_result" "$cleanup_available_result"
  else
    print_summary
  fi

  if ((CHECKS_PASSED == CHECKS_TOTAL)); then
    return 0
  fi
  return 1
}

# ─── Output ──────────────────────────────────────────────────────────────────

print_summary() {
  echo ""
  echo "=== Voice Input Health Check ==="
  echo ""
  echo "Tool: $TOOL_NAME"
  echo "Checks: $CHECKS_PASSED/$CHECKS_TOTAL passed"
  echo ""

  if ((CHECKS_PASSED == CHECKS_TOTAL)); then
    echo "Status: PASS"
  else
    echo "Status: FAIL"
    echo ""
    echo "Run the setup script to fix issues:"
    echo "  ${SCRIPT_DIR}/setup-voice-input.sh --tool $TOOL_NAME"
  fi
}

print_json_output() {
  local tool_installed="${1:-false}"
  local tool_running="${2:-false}"
  local mic_permission="${3:-false}"
  local settings_valid="${4:-false}"
  local vocabulary_valid="${5:-false}"
  local cleanup_available="${6:-false}"

  local status="fail"
  if ((CHECKS_PASSED == CHECKS_TOTAL)); then
    status="pass"
  fi

  cat <<EOF
{
  "status": "$status",
  "tool": "$TOOL_NAME",
  "tool_installed": $tool_installed,
  "tool_running": $tool_running,
  "mic_permission": $mic_permission,
  "settings_valid": $settings_valid,
  "vocabulary_valid": $vocabulary_valid,
  "cleanup_available": $cleanup_available,
  "checks_passed": $CHECKS_PASSED,
  "checks_total": $CHECKS_TOTAL
}
EOF
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        JSON_OUTPUT=true
        shift
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  run_all_checks
}

main "$@"
