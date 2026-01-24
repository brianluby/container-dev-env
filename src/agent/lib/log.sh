#!/usr/bin/env bash
# log.sh — Action log writing, reading, and credential filtering
# Version: 1.0.0
# Dependencies: jq, date

set -euo pipefail

# Valid action types (from ActionLogEntry schema)
readonly VALID_ACTIONS=(
  "file_edit" "file_create" "file_delete"
  "command_exec" "checkpoint" "rollback"
  "decision" "error"
  "sub_agent_spawn" "sub_agent_complete"
  "provider_switch" "session_start" "session_complete"
  "session_pause" "session_resume"
)

# _get_log_path <session_id>
# Returns the log file path for a session
_get_log_path() {
  local session_id="$1"
  local state_dir="${AGENT_STATE_DIR:-${HOME}/.local/share/agent}"
  echo "${state_dir}/logs/${session_id}.jsonl"
}

# _redact_credentials <text>
# Redacts known API key patterns from text
_redact_credentials() {
  local text="$1"

  # Redact specific env var values if set
  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    text="${text//${ANTHROPIC_API_KEY}/[REDACTED]}"
  fi
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    text="${text//${OPENAI_API_KEY}/[REDACTED]}"
  fi
  if [[ -n "${GOOGLE_API_KEY:-}" ]]; then
    text="${text//${GOOGLE_API_KEY}/[REDACTED]}"
  fi
  if [[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
    text="${text//${AWS_SECRET_ACCESS_KEY}/[REDACTED]}"
  fi
  if [[ -n "${OPENCODE_SERVER_PASSWORD:-}" ]]; then
    text="${text//${OPENCODE_SERVER_PASSWORD}/[REDACTED]}"
  fi

  # Redact common API key patterns (sk-xxx, key-xxx)
  text=$(echo "${text}" | sed -E 's/sk-[a-zA-Z0-9_-]{10,}/[REDACTED]/g')

  echo "${text}"
}

# _get_timestamp
# Returns current UTC timestamp in ISO 8601 format
_get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# log_action <session_id> <action> <target> <details> [result] [checkpoint_id]
# Appends a JSONL entry to the session's action log
log_action() {
  local session_id="$1"
  local action="$2"
  local target="$3"
  local details="$4"
  local result="${5:-null}"
  local checkpoint_id="${6:-null}"

  local log_path
  log_path=$(_get_log_path "${session_id}")

  # Ensure log directory exists
  mkdir -p "$(dirname "${log_path}")"

  # Redact credentials from all fields
  target=$(_redact_credentials "${target}")
  details=$(_redact_credentials "${details}")

  # Build JSON entry using jq for safe escaping (FR-002)
  local timestamp
  timestamp=$(_get_timestamp)

  # Construct JSONL entry with jq — all user-controlled fields via --arg
  local jq_args=(
    -n -c
    --arg timestamp "${timestamp}"
    --arg action "${action}"
    --arg target "${target}"
    --arg details "${details}"
  )

  local jq_filter
  if [[ "${result}" == "null" ]]; then
    if [[ "${checkpoint_id}" == "null" ]]; then
      jq_filter='{timestamp: $timestamp, action: $action, target: $target, details: $details, result: null, checkpoint_id: null}'
    else
      jq_args+=(--arg checkpoint_id "${checkpoint_id}")
      jq_filter='{timestamp: $timestamp, action: $action, target: $target, details: $details, result: null, checkpoint_id: $checkpoint_id}'
    fi
  else
    jq_args+=(--arg result "${result}")
    if [[ "${checkpoint_id}" == "null" ]]; then
      jq_filter='{timestamp: $timestamp, action: $action, target: $target, details: $details, result: $result, checkpoint_id: null}'
    else
      jq_args+=(--arg checkpoint_id "${checkpoint_id}")
      jq_filter='{timestamp: $timestamp, action: $action, target: $target, details: $details, result: $result, checkpoint_id: $checkpoint_id}'
    fi
  fi

  jq "${jq_args[@]}" "${jq_filter}" >> "${log_path}"
}

# read_log <session_id>
# Outputs all entries from the session's action log
read_log() {
  local session_id="$1"
  local log_path
  log_path=$(_get_log_path "${session_id}")

  if [[ ! -f "${log_path}" ]]; then
    echo "Error: No log found for session ${session_id}" >&2
    return 1
  fi

  cat "${log_path}"
}

# tail_log <session_id> <n>
# Outputs the last N entries from the session's action log
tail_log() {
  local session_id="$1"
  local n="$2"
  local log_path
  log_path=$(_get_log_path "${session_id}")

  if [[ ! -f "${log_path}" ]]; then
    echo "Error: No log found for session ${session_id}" >&2
    return 1
  fi

  tail -n "${n}" "${log_path}"
}

# filter_log <session_id> <action_type>
# Outputs entries matching the specified action type
filter_log() {
  local session_id="$1"
  local action_type="$2"
  local log_path
  log_path=$(_get_log_path "${session_id}")

  if [[ ! -f "${log_path}" ]]; then
    echo "Error: No log found for session ${session_id}" >&2
    return 1
  fi

  jq -c "select(.action == \"${action_type}\")" "${log_path}"
}

# format_log_text <session_id>
# Outputs the action log in human-readable text format
format_log_text() {
  local session_id="$1"
  local log_path
  log_path=$(_get_log_path "${session_id}")

  if [[ ! -f "${log_path}" ]]; then
    echo "Error: No log found for session ${session_id}" >&2
    return 1
  fi

  while IFS= read -r line; do
    local ts action target details result
    ts=$(echo "${line}" | jq -r '.timestamp')
    action=$(echo "${line}" | jq -r '.action')
    target=$(echo "${line}" | jq -r '.target')
    details=$(echo "${line}" | jq -r '.details')
    result=$(echo "${line}" | jq -r '.result // "—"')
    printf "[%s] %-15s %s — %s (%s)\n" "${ts}" "${action}" "${target}" "${details}" "${result}"
  done < "${log_path}"
}

# format_log_json <session_id>
# Outputs the action log as a JSON array
format_log_json() {
  local session_id="$1"
  local log_path
  log_path=$(_get_log_path "${session_id}")

  if [[ ! -f "${log_path}" ]]; then
    echo "Error: No log found for session ${session_id}" >&2
    return 1
  fi

  jq -s '.' "${log_path}"
}
