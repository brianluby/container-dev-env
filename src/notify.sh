#!/usr/bin/env bash
set -euo pipefail

# notify.sh — Mobile push notification wrapper for AI agent events
# Usage: notify.sh <message> [priority] [title]
# See: specs/016-mobile-access/contracts/cli-interface.md

# ─── Logging ─────────────────────────────────────────────────────────────────

log_info() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_warn() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2
}

# ─── Config Parsing ──────────────────────────────────────────────────────────

# Locate and parse notify.yaml config file
# Sets: NTFY_ENABLED, SLACK_ENABLED, PRIORITY_*, QUIET_*, RETRY_*
parse_config() {
  local config_file="${NOTIFY_CONFIG:-${HOME}/.config/notify/notify.yaml}"

  if [[ ! -f "${config_file}" ]]; then
    log_error "Configuration file not found: ${config_file}"
    return 1
  fi

  # Validate basic YAML structure (must have services section)
  if ! grep -q "^services:" "${config_file}" 2>/dev/null; then
    log_error "Malformed config: missing 'services' section in ${config_file}"
    return 1
  fi

  # Extract service enabled states
  NTFY_ENABLED="$(sed -n '/^  ntfy:/,/^  [a-z]/{ /enabled:/s/.*enabled: *//p; }' "${config_file}" | head -1)"
  NTFY_ENABLED="${NTFY_ENABLED:-false}"

  SLACK_ENABLED="$(sed -n '/^  slack:/,/^[a-z]/{ /enabled:/s/.*enabled: *//p; }' "${config_file}" | head -1)"
  SLACK_ENABLED="${SLACK_ENABLED:-false}"

  # Extract priority mappings
  PRIORITY_PROGRESS="$(sed -n '/^priorities:/,/^[a-z]/{ /progress:/s/.*progress: *//p; }' "${config_file}" | head -1)"
  PRIORITY_PROGRESS="${PRIORITY_PROGRESS:-2}"

  PRIORITY_COMPLETED="$(sed -n '/^priorities:/,/^[a-z]/{ /completed:/s/.*completed: *//p; }' "${config_file}" | head -1)"
  PRIORITY_COMPLETED="${PRIORITY_COMPLETED:-3}"

  PRIORITY_FAILED="$(sed -n '/^priorities:/,/^[a-z]/{ /failed:/s/.*failed: *//p; }' "${config_file}" | head -1)"
  PRIORITY_FAILED="${PRIORITY_FAILED:-4}"

  PRIORITY_APPROVAL_NEEDED="$(sed -n '/^priorities:/,/^[a-z]/{ /approval_needed:/s/.*approval_needed: *//p; }' "${config_file}" | head -1)"
  PRIORITY_APPROVAL_NEEDED="${PRIORITY_APPROVAL_NEEDED:-5}"

  # Extract quiet hours settings
  QUIET_ENABLED="$(sed -n '/^quiet_hours:/,/^[a-z]/{ /enabled:/s/.*enabled: *//p; }' "${config_file}" | head -1)"
  QUIET_ENABLED="${QUIET_ENABLED:-false}"

  local quiet_start_raw
  quiet_start_raw="$(sed -n '/^quiet_hours:/,/^[a-z]/{ /start:/s/.*start: *//p; }' "${config_file}" | head -1)"
  quiet_start_raw="${quiet_start_raw//\"/}"
  QUIET_START="${quiet_start_raw/:/}"
  QUIET_START="${QUIET_START:-2200}"

  local quiet_end_raw
  quiet_end_raw="$(sed -n '/^quiet_hours:/,/^[a-z]/{ /end:/s/.*end: *//p; }' "${config_file}" | head -1)"
  quiet_end_raw="${quiet_end_raw//\"/}"
  QUIET_END="${quiet_end_raw/:/}"
  QUIET_END="${QUIET_END:-0800}"

  QUIET_MIN_PRIORITY="$(sed -n '/^quiet_hours:/,/^[a-z]/{ /min_priority:/s/.*min_priority: *//p; }' "${config_file}" | head -1)"
  QUIET_MIN_PRIORITY="${QUIET_MIN_PRIORITY:-5}"

  # Extract retry settings
  RETRY_MAX_ATTEMPTS="$(sed -n '/^retry:/,/^[a-z]/{ /max_attempts:/s/.*max_attempts: *//p; }' "${config_file}" | head -1)"
  RETRY_MAX_ATTEMPTS="${RETRY_MAX_ATTEMPTS:-3}"

  RETRY_BASE_DELAY="$(sed -n '/^retry:/,/^[a-z]/{ /base_delay:/s/.*base_delay: *//p; }' "${config_file}" | head -1)"
  RETRY_BASE_DELAY="${RETRY_BASE_DELAY:-2}"

  export NTFY_ENABLED SLACK_ENABLED
  export PRIORITY_PROGRESS PRIORITY_COMPLETED PRIORITY_FAILED PRIORITY_APPROVAL_NEEDED
  export QUIET_ENABLED QUIET_START QUIET_END QUIET_MIN_PRIORITY
  export RETRY_MAX_ATTEMPTS RETRY_BASE_DELAY
}

# ─── CLI Argument Parsing ────────────────────────────────────────────────────

# Parse and validate command-line arguments
# Sets: NOTIFY_MESSAGE, NOTIFY_PRIORITY, NOTIFY_TITLE
parse_args() {
  local message="${1:-}"
  local priority="${2:-3}"
  local title="${3:-Agent Notification}"

  # Handle --help flag
  if [[ "${message}" == "--help" || "${message}" == "-h" ]]; then
    cat >&2 << 'USAGE'
Usage: notify.sh <message> [priority] [title]

Send push notifications for AI agent events.

Arguments:
  message     Notification body text (required)
  priority    Priority level 1-5 (default: 3)
              Or event type: completed, failed, approval_needed, progress
  title       Notification title (default: "Agent Notification")

Exit Codes:
  0  Success (or suppressed/discarded)
  1  Configuration error
  2  Invalid arguments

Environment Variables:
  NTFY_SERVER   ntfy.sh server URL (default: https://ntfy.sh)
  NTFY_TOPIC    Topic name for publishing
  NTFY_TOKEN    Bearer access token
  SLACK_WEBHOOK Slack incoming webhook URL
  NOTIFY_CONFIG Config file path (default: ~/.config/notify/notify.yaml)
USAGE
    return 0
  fi

  # Validate message is non-empty
  if [[ -z "${message}" ]]; then
    log_error "message is required. Use --help for usage."
    return 2
  fi

  # Validate priority: accepts numeric 1-5 or event type strings
  if [[ -n "${priority}" ]]; then
    if [[ "${priority}" =~ ^[0-9]+$ ]]; then
      # Numeric: validate range
      if [[ "${priority}" -lt 1 || "${priority}" -gt 5 ]]; then
        log_error "Invalid priority '${priority}': must be in range 1-5"
        return 2
      fi
    elif [[ "${priority}" =~ ^(completed|failed|approval_needed|progress)$ ]]; then
      # Event type: will be resolved after config is loaded
      :
    else
      log_error "Invalid priority '${priority}': must be 1-5 or event type (completed, failed, approval_needed, progress)"
      return 2
    fi
  fi

  NOTIFY_MESSAGE="${message}"
  NOTIFY_PRIORITY="${priority}"
  NOTIFY_TITLE="${title}"

  export NOTIFY_MESSAGE NOTIFY_PRIORITY NOTIFY_TITLE
}

# ─── Environment Variable Validation ────────────────────────────────────────

# Validate required environment variables based on enabled services
# Missing env vars disable the service with a warning (don't block agent)
validate_env() {
  if [[ "${NTFY_ENABLED}" == "true" ]]; then
    if [[ -z "${NTFY_TOPIC:-}" || -z "${NTFY_TOKEN:-}" ]]; then
      log_warn "ntfy service enabled but NTFY_TOPIC or NTFY_TOKEN not set; skipping ntfy"
      NTFY_ENABLED="false"
    fi
  fi

  if [[ "${SLACK_ENABLED}" == "true" ]]; then
    if [[ -z "${SLACK_WEBHOOK:-}" ]]; then
      log_warn "slack service enabled but SLACK_WEBHOOK not set; skipping slack"
      SLACK_ENABLED="false"
    fi
  fi

  # Default NTFY_SERVER if not set
  NTFY_SERVER="${NTFY_SERVER:-https://ntfy.sh}"

  # HTTPS enforcement for NTFY_SERVER
  if [[ "${NTFY_ENABLED}" == "true" && "${NTFY_SERVER}" != https://* ]]; then
    log_warn "NTFY_SERVER is not https://; disabling ntfy for security"
    NTFY_ENABLED="false"
  fi

  export NTFY_SERVER NTFY_ENABLED SLACK_ENABLED

  # If no services remain enabled, warn but don't error
  if [[ "${NTFY_ENABLED}" != "true" && "${SLACK_ENABLED}" != "true" ]]; then
    log_warn "No notification services available; notification will be discarded"
  fi
}

# ─── Priority Resolution ─────────────────────────────────────────────────────

# Resolve priority: numeric (1-5) passes through, event type name looks up config
resolve_priority() {
  local input="${1:-3}"

  # If numeric 1-5, use directly
  if [[ "${input}" =~ ^[1-5]$ ]]; then
    echo "${input}"
    return 0
  fi

  # If event type name, look up in config priority mappings
  case "${input}" in
    completed) echo "${PRIORITY_COMPLETED:-3}" ;;
    failed) echo "${PRIORITY_FAILED:-4}" ;;
    approval_needed) echo "${PRIORITY_APPROVAL_NEEDED:-5}" ;;
    progress) echo "${PRIORITY_PROGRESS:-2}" ;;
    *) echo "3" ;; # Default fallback
  esac
}

# ─── Source Sanitization ─────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=notify-sanitize.sh
source "${SCRIPT_DIR}/notify-sanitize.sh"

# ─── ntfy.sh Delivery ────────────────────────────────────────────────────────

# Send notification via ntfy.sh HTTP POST
# Requires: NOTIFY_MESSAGE, NOTIFY_PRIORITY, NOTIFY_TITLE, NTFY_SERVER, NTFY_TOPIC, NTFY_TOKEN
send_ntfy() {
  local url="${NTFY_SERVER}/${NTFY_TOPIC}"

  # Enforce HTTPS
  if [[ "${url}" != https://* ]]; then
    log_error "HTTPS required: ${NTFY_SERVER} is not an https:// URL"
    return 1
  fi

  local http_code
  http_code="$(curl -s -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer ${NTFY_TOKEN}" \
    -H "X-Priority: ${NOTIFY_PRIORITY}" \
    -H "X-Title: ${NOTIFY_TITLE}" \
    -d "${NOTIFY_MESSAGE}" \
    "${url}")"

  if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]; then
    log_info "ntfy: delivered (HTTP ${http_code})"
    return 0
  else
    log_error "ntfy: delivery failed (HTTP ${http_code})"
    return 1
  fi
}

# ─── Slack Delivery ──────────────────────────────────────────────────────────

# Get priority emoji for Slack messages
get_priority_emoji() {
  local priority="${1:-3}"
  case "${priority}" in
    5) echo "🔴" ;;
    4) echo "🟠" ;;
    3) echo "🟢" ;;
    *) echo "⬜" ;;
  esac
}

# Send notification via Slack webhook
# Requires: NOTIFY_MESSAGE, NOTIFY_PRIORITY, NOTIFY_TITLE, SLACK_WEBHOOK
send_slack() {
  local emoji
  emoji="$(get_priority_emoji "${NOTIFY_PRIORITY}")"

  local payload
  # Use printf for JSON construction (jq optional)
  payload="$(printf '{"text":"%s *%s*\\n%s"}' "${emoji}" "${NOTIFY_TITLE}" "${NOTIFY_MESSAGE}")"

  local http_code
  http_code="$(curl -s -o /dev/null -w '%{http_code}' \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${SLACK_WEBHOOK}")"

  if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]; then
    log_info "slack: delivered (HTTP ${http_code})"
    return 0
  else
    log_error "slack: delivery failed (HTTP ${http_code})"
    return 1
  fi
}

# ─── Retry Logic ─────────────────────────────────────────────────────────────

# Wrapper that retries a send function with exponential backoff
# Usage: send_with_retry <send_function_name>
# Retries on: 429, 5xx, connection timeout
# No retry on: 400, 401
send_with_retry() {
  local send_fn="${1}"
  local max_attempts="${RETRY_MAX_ATTEMPTS:-3}"
  local base_delay="${RETRY_BASE_DELAY:-2}"
  local attempt=0

  while [[ "${attempt}" -lt "${max_attempts}" ]]; do
    attempt=$((attempt + 1))

    # Try the send function — capture its output for HTTP code analysis
    local result
    if result="$("${send_fn}" 2>&1)"; then
      # Success
      return 0
    fi

    # Check if the error mentions non-retryable codes
    if [[ "${result}" =~ "400" || "${result}" =~ "401" ]]; then
      log_warn "${send_fn}: non-retryable error (attempt ${attempt}), giving up"
      return 0 # exit 0 per spec — don't block agent
    fi

    # Retryable error
    if [[ "${attempt}" -lt "${max_attempts}" ]]; then
      local delay=$((base_delay ** attempt))
      log_warn "${send_fn}: retry attempt ${attempt}/${max_attempts}, waiting ${delay}s"
      sleep "${delay}"
    fi
  done

  log_error "${send_fn}: exhausted ${max_attempts} retries, discarding notification"
  return 0 # exit 0 per spec — don't block agent
}

# ─── Multi-Service Dispatch ──────────────────────────────────────────────────

# Dispatch notification to all enabled services independently
dispatch_services() {
  if [[ "${NTFY_ENABLED}" == "true" ]]; then
    send_with_retry send_ntfy || log_warn "ntfy delivery failed, continuing"
  fi

  if [[ "${SLACK_ENABLED}" == "true" ]]; then
    send_with_retry send_slack || log_warn "slack delivery failed, continuing"
  fi
}

# ─── Quiet Hours ─────────────────────────────────────────────────────────────

# Check if current time is within quiet hours window
# Returns 0 if in quiet hours, 1 if not
# Note: 10# prefix forces base-10 to avoid octal interpretation of 08xx/09xx
is_quiet_hours() {
  local now start end
  now=$((10#${MOCK_DATE_HHMM:-$(date +%H%M)}))
  start=$((10#${QUIET_START}))
  end=$((10#${QUIET_END}))

  if (( start > end )); then
    # Overnight window (e.g., 22:00-08:00)
    if (( now >= start || now < end )); then
      return 0
    fi
  else
    # Same-day window (e.g., 09:00-17:00)
    if (( now >= start && now < end )); then
      return 0
    fi
  fi
  return 1
}

# Check if notification should be suppressed
# Returns 0 if should suppress, 1 if should deliver
should_suppress() {
  # If quiet hours disabled, don't suppress
  if [[ "${QUIET_ENABLED}" != "true" ]]; then
    return 1
  fi

  # If not in quiet window, don't suppress
  if ! is_quiet_hours; then
    return 1
  fi

  # If priority >= min_priority, bypass (don't suppress)
  if [[ "${NOTIFY_PRIORITY}" -ge "${QUIET_MIN_PRIORITY}" ]]; then
    return 1
  fi

  # Suppress
  return 0
}

# Check quiet hours and handle suppression
# Logs if suppressed, returns 0 if suppressed (caller should exit)
check_quiet_hours() {
  if should_suppress; then
    log_info "Notification suppressed (quiet hours, priority ${NOTIFY_PRIORITY} < ${QUIET_MIN_PRIORITY})"
    return 0
  fi
  return 1
}

# ─── Empty Message Handling ──────────────────────────────────────────────────

# Substitute default message if empty after sanitization
handle_empty_message() {
  if [[ -z "${NOTIFY_MESSAGE:-}" || "${NOTIFY_MESSAGE}" =~ ^[[:space:]]*$ ]]; then
    NOTIFY_MESSAGE="Agent event (no details)"
    export NOTIFY_MESSAGE
  fi
}

# ─── Main Execution ─────────────────────────────────────────────────────────

main() {
  parse_args "$@"
  parse_config
  validate_env

  # Resolve priority (event type strings → numeric)
  NOTIFY_PRIORITY="$(resolve_priority "${NOTIFY_PRIORITY}")"
  export NOTIFY_PRIORITY

  # Sanitize message content (strip paths, keys, code)
  NOTIFY_MESSAGE="$(sanitize_message "${NOTIFY_MESSAGE}")"
  export NOTIFY_MESSAGE

  # Handle empty message (substitute default after sanitization)
  handle_empty_message

  # Check quiet hours — suppress if applicable
  if check_quiet_hours; then
    exit 0
  fi

  # Dispatch to all enabled services
  dispatch_services

  # Always exit 0 to avoid blocking agent hooks
  exit 0
}

# Only run main if not being sourced for testing
if [[ -z "${NOTIFY_SOURCED:-}" ]]; then
  main "$@"
fi
