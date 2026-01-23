#!/usr/bin/env bash
# config.sh — Configuration loading and validation for the agent wrapper
# Version: 1.0.0
# Dependencies: jq

set -euo pipefail

# Defaults
readonly DEFAULT_BACKEND="opencode"
readonly DEFAULT_MODE="manual"
readonly DEFAULT_STATE_DIR="${HOME}/.local/share/agent"
readonly DEFAULT_CHECKPOINT_MAX_COUNT=50
readonly DEFAULT_CHECKPOINT_MAX_AGE_DAYS=30
readonly DEFAULT_SHELL_TIMEOUT=300

# Valid enum values
readonly VALID_BACKENDS=("opencode" "claude")
readonly VALID_MODES=("manual" "auto" "hybrid")

# Default dangerous patterns
readonly DEFAULT_DANGEROUS_PATTERNS=(
  "rm -rf"
  "git push --force"
  "git reset --hard"
  "chmod 777"
  "dd if="
  "> /dev/"
)

# Exported config variables (set by load_config)
AGENT_CFG_BACKEND=""
AGENT_CFG_MODE=""
AGENT_CFG_STATE_DIR=""
AGENT_CFG_CHECKPOINT_ENABLED="true"
AGENT_CFG_CHECKPOINT_MAX_COUNT=""
AGENT_CFG_CHECKPOINT_MAX_AGE_DAYS=""
AGENT_CFG_CHECKPOINT_AUTO_PRUNE="true"
AGENT_CFG_SHELL_TIMEOUT=""
AGENT_CFG_DANGEROUS_PATTERNS=()
AGENT_CFG_LOGGING_ENABLED="true"
AGENT_CFG_LOGGING_DIR=""
AGENT_CFG_MCP_CONFIG=""

# load_config <workspace_path>
# Loads configuration from global config, project config, and environment variables.
# Priority: env vars > project config > global config > defaults
load_config() {
  local workspace="${1:-.}"
  local global_config="${HOME}/.config/agent/config.json"
  local project_config="${workspace}/.agent.json"

  # Start with defaults
  AGENT_CFG_BACKEND="${DEFAULT_BACKEND}"
  AGENT_CFG_MODE="${DEFAULT_MODE}"
  AGENT_CFG_STATE_DIR="${DEFAULT_STATE_DIR}"
  AGENT_CFG_CHECKPOINT_MAX_COUNT="${DEFAULT_CHECKPOINT_MAX_COUNT}"
  AGENT_CFG_CHECKPOINT_MAX_AGE_DAYS="${DEFAULT_CHECKPOINT_MAX_AGE_DAYS}"
  AGENT_CFG_SHELL_TIMEOUT="${DEFAULT_SHELL_TIMEOUT}"
  AGENT_CFG_DANGEROUS_PATTERNS=("${DEFAULT_DANGEROUS_PATTERNS[@]}")
  AGENT_CFG_LOGGING_DIR="${AGENT_CFG_STATE_DIR}/logs"

  # Load global config if it exists
  if [[ -f "${global_config}" ]]; then
    _parse_config_file "${global_config}" || return 1
  fi

  # Load project config if it exists (overrides global)
  if [[ -f "${project_config}" ]]; then
    _parse_config_file "${project_config}" || return 1
  fi

  # Environment variables override everything
  if [[ -n "${AGENT_BACKEND:-}" ]]; then
    AGENT_CFG_BACKEND="${AGENT_BACKEND}"
  fi
  if [[ -n "${AGENT_MODE:-}" ]]; then
    AGENT_CFG_MODE="${AGENT_MODE}"
  fi
  if [[ -n "${AGENT_STATE_DIR:-}" ]]; then
    AGENT_CFG_STATE_DIR="${AGENT_STATE_DIR}"
    AGENT_CFG_LOGGING_DIR="${AGENT_CFG_STATE_DIR}/logs"
  fi

  # Validate final values
  _validate_config || return 1

  return 0
}

# _parse_config_file <filepath>
# Parses a JSON config file and sets config variables
_parse_config_file() {
  local filepath="$1"

  # Validate JSON
  if ! jq empty "${filepath}" 2>/dev/null; then
    echo "Error: Invalid JSON in ${filepath}" >&2
    return 1
  fi

  local val

  # Backend
  val=$(jq -r '.backend // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_BACKEND="${val}"
  fi

  # Mode
  val=$(jq -r '.mode // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_MODE="${val}"
  fi

  # Checkpoint config
  val=$(jq -r '.checkpoint.enabled // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_CHECKPOINT_ENABLED="${val}"
  fi

  val=$(jq -r '.checkpoint.retention.max_count // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_CHECKPOINT_MAX_COUNT="${val}"
  fi

  val=$(jq -r '.checkpoint.retention.max_age_days // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_CHECKPOINT_MAX_AGE_DAYS="${val}"
  fi

  val=$(jq -r '.checkpoint.auto_prune // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_CHECKPOINT_AUTO_PRUNE="${val}"
  fi

  # Shell config
  val=$(jq -r '.shell.timeout_seconds // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_SHELL_TIMEOUT="${val}"
  fi

  # Dangerous patterns (replace defaults if specified)
  local pattern_count
  pattern_count=$(jq -r '.shell.dangerous_patterns | length // 0' "${filepath}" 2>/dev/null)
  if [[ "${pattern_count}" -gt 0 ]]; then
    AGENT_CFG_DANGEROUS_PATTERNS=()
    while IFS= read -r pattern; do
      AGENT_CFG_DANGEROUS_PATTERNS+=("${pattern}")
    done < <(jq -r '.shell.dangerous_patterns[]' "${filepath}" 2>/dev/null)
  fi

  # Logging config
  val=$(jq -r '.logging.action_log // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_LOGGING_ENABLED="${val}"
  fi

  val=$(jq -r '.logging.directory // empty' "${filepath}" 2>/dev/null)
  if [[ -n "${val}" ]]; then
    AGENT_CFG_LOGGING_DIR="${val}"
  fi

  # MCP server config (pass-through to backends)
  local mcp_count
  mcp_count=$(jq -r '.mcp.servers | length // 0' "${filepath}" 2>/dev/null)
  if [[ "${mcp_count}" -gt 0 ]]; then
    AGENT_CFG_MCP_CONFIG=$(jq -c '.mcp' "${filepath}" 2>/dev/null)
  fi

  return 0
}

# _validate_config
# Validates all config values are within allowed ranges
_validate_config() {
  # Validate backend
  local valid=false
  for b in "${VALID_BACKENDS[@]}"; do
    if [[ "${AGENT_CFG_BACKEND}" == "${b}" ]]; then
      valid=true
      break
    fi
  done
  if [[ "${valid}" == "false" ]]; then
    echo "Error: invalid backend '${AGENT_CFG_BACKEND}'. Must be one of: ${VALID_BACKENDS[*]}" >&2
    return 1
  fi

  # Validate mode
  valid=false
  for m in "${VALID_MODES[@]}"; do
    if [[ "${AGENT_CFG_MODE}" == "${m}" ]]; then
      valid=true
      break
    fi
  done
  if [[ "${valid}" == "false" ]]; then
    echo "Error: invalid mode '${AGENT_CFG_MODE}'. Must be one of: ${VALID_MODES[*]}" >&2
    return 1
  fi

  return 0
}

# is_dangerous_command <command_string>
# Returns 0 if the command matches any configured dangerous pattern
is_dangerous_command() {
  local cmd="$1"
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "${cmd}" == *"${pattern}"* ]]; then
      return 0
    fi
  done
  return 1
}

# get_config_summary
# Outputs current configuration as JSON for --format json
get_config_summary() {
  local mcp_json="${AGENT_CFG_MCP_CONFIG:-null}"
  cat <<EOF
{
  "backend": "${AGENT_CFG_BACKEND}",
  "mode": "${AGENT_CFG_MODE}",
  "state_dir": "${AGENT_CFG_STATE_DIR}",
  "checkpoint": {
    "enabled": ${AGENT_CFG_CHECKPOINT_ENABLED},
    "max_count": ${AGENT_CFG_CHECKPOINT_MAX_COUNT},
    "max_age_days": ${AGENT_CFG_CHECKPOINT_MAX_AGE_DAYS},
    "auto_prune": ${AGENT_CFG_CHECKPOINT_AUTO_PRUNE}
  },
  "shell": {
    "timeout_seconds": ${AGENT_CFG_SHELL_TIMEOUT}
  },
  "mcp": ${mcp_json}
}
EOF
}
