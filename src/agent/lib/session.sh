#!/usr/bin/env bash
# session.sh — Session metadata management
# Version: 1.0.0
# Dependencies: jq, uuidgen or /proc/sys/kernel/random/uuid

set -euo pipefail

# _generate_uuid
# Generates a UUID for session identification
_generate_uuid() {
  if command -v uuidgen &>/dev/null; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  elif [[ -f /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  else
    # Fallback: generate pseudo-UUID from date and random
    printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
      $RANDOM $RANDOM $RANDOM $((RANDOM & 0x0fff | 0x4000)) \
      $((RANDOM & 0x3fff | 0x8000)) $RANDOM $RANDOM $RANDOM
  fi
}

# _get_session_path <session_id>
_get_session_path() {
  local session_id="$1"
  local state_dir="${AGENT_STATE_DIR:-${HOME}/.local/share/agent}"
  echo "${state_dir}/sessions/${session_id}.json"
}

# create_session <backend> <task_description> <approval_mode>
# Creates a new session and returns the session ID
create_session() {
  local backend="$1"
  local task_description="$2"
  local approval_mode="${3:-manual}"
  local session_id
  session_id=$(_generate_uuid)
  local session_path
  session_path=$(_get_session_path "${session_id}")
  local started_at
  started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$(dirname "${session_path}")"

  cat > "${session_path}" <<EOF
{
  "id": "${session_id}",
  "backend": "${backend}",
  "started_at": "${started_at}",
  "ended_at": null,
  "status": "active",
  "task_description": "${task_description}",
  "approval_mode": "${approval_mode}",
  "workspace": "$(pwd)",
  "checkpoints": [],
  "token_usage": {
    "input_tokens": 0,
    "output_tokens": 0,
    "total_tokens": 0,
    "estimated_cost_usd": 0.0,
    "model": "",
    "provider": ""
  },
  "action_log_path": "${AGENT_STATE_DIR:-${HOME}/.local/share/agent}/logs/${session_id}.jsonl"
}
EOF

  echo "${session_id}"
}

# get_session <session_id>
# Outputs the session JSON
get_session() {
  local session_id="$1"
  local session_path
  session_path=$(_get_session_path "${session_id}")

  if [[ ! -f "${session_path}" ]]; then
    echo "Error: Session '${session_id}' not found" >&2
    return 1
  fi

  # Validate JSON
  if ! jq empty "${session_path}" 2>/dev/null; then
    echo "Error: Session file corrupted: ${session_path}" >&2
    return 1
  fi

  cat "${session_path}"
}

# update_session_status <session_id> <new_status>
# Updates the session status (active, paused, completed, failed)
update_session_status() {
  local session_id="$1"
  local new_status="$2"
  local session_path
  session_path=$(_get_session_path "${session_id}")

  if [[ ! -f "${session_path}" ]]; then
    echo "Error: Session '${session_id}' not found" >&2
    return 1
  fi

  local tmp="${session_path}.tmp"
  if [[ "${new_status}" == "completed" || "${new_status}" == "failed" ]]; then
    local ended_at
    ended_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg status "${new_status}" --arg ended "${ended_at}" \
      '.status = $status | .ended_at = $ended' "${session_path}" > "${tmp}"
  else
    jq --arg status "${new_status}" '.status = $status' "${session_path}" > "${tmp}"
  fi
  mv "${tmp}" "${session_path}"
}

# list_sessions [status_filter]
# Lists all sessions, optionally filtered by status
list_sessions() {
  local status_filter="${1:-all}"
  local state_dir="${AGENT_STATE_DIR:-${HOME}/.local/share/agent}"
  local sessions_dir="${state_dir}/sessions"

  if [[ ! -d "${sessions_dir}" ]]; then
    return 0
  fi

  for session_file in "${sessions_dir}"/*.json; do
    [[ -f "${session_file}" ]] || continue
    if ! jq empty "${session_file}" 2>/dev/null; then
      continue  # Skip corrupted files
    fi
    local status
    status=$(jq -r '.status' "${session_file}" 2>/dev/null)
    if [[ "${status_filter}" == "all" || "${status}" == "${status_filter}" ]]; then
      jq -c '{id: .id, backend: .backend, started_at: .started_at, status: .status, task: .task_description}' "${session_file}"
    fi
  done
}

# find_latest_session [status_filter]
# Returns the ID of the most recent session matching the filter
find_latest_session() {
  local status_filter="${1:-active}"
  local state_dir="${AGENT_STATE_DIR:-${HOME}/.local/share/agent}"
  local sessions_dir="${state_dir}/sessions"
  local latest_id="" latest_time="0"

  if [[ ! -d "${sessions_dir}" ]]; then
    return 1
  fi

  for session_file in "${sessions_dir}"/*.json; do
    [[ -f "${session_file}" ]] || continue
    if ! jq empty "${session_file}" 2>/dev/null; then
      continue
    fi
    local status started_at
    status=$(jq -r '.status' "${session_file}" 2>/dev/null)
    if [[ "${status}" == "${status_filter}" ]]; then
      started_at=$(jq -r '.started_at' "${session_file}" 2>/dev/null)
      # shellcheck disable=SC2071 # Intentional string comparison for ISO 8601 timestamps
      if [[ "${started_at}" > "${latest_time}" ]]; then
        latest_time="${started_at}"
        latest_id=$(jq -r '.id' "${session_file}" 2>/dev/null)
      fi
    fi
  done

  if [[ -z "${latest_id}" ]]; then
    return 1
  fi

  echo "${latest_id}"
}
