#!/usr/bin/env bash
# agent.sh — Unified wrapper for agentic coding assistants
# Version: 1.0.0
# Dependencies: src/agent/lib/*.sh, jq
#
# Usage: agent [OPTIONS] [TASK_DESCRIPTION]
#        agent <SUBCOMMAND>

set -euo pipefail

# Resolve script directory for library sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Version
readonly AGENT_VERSION="1.0.0"

# Exit codes (from CLI contract)
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_INVALID_ARGS=2
readonly EXIT_MISSING_API_KEY=3
readonly EXIT_BACKEND_NOT_INSTALLED=4
readonly EXIT_SESSION_NOT_FOUND=5
readonly EXIT_CHECKPOINT_NOT_FOUND=6
readonly EXIT_PROVIDER_UNAVAILABLE=10
readonly EXIT_RATE_LIMITED=11

# Source library modules
# shellcheck source=lib/config.sh
source "${LIB_DIR}/config.sh"
# shellcheck source=lib/provider.sh
source "${LIB_DIR}/provider.sh"
# shellcheck source=lib/exclusions.sh
source "${LIB_DIR}/exclusions.sh"
# shellcheck source=lib/log.sh
source "${LIB_DIR}/log.sh"
# shellcheck source=lib/checkpoint.sh
source "${LIB_DIR}/checkpoint.sh"
# shellcheck source=lib/session.sh
source "${LIB_DIR}/session.sh"
# shellcheck source=lib/usage.sh
source "${LIB_DIR}/usage.sh"

# --- Argument Parsing ---

# Parsed options
OPT_CLAUDE=""
OPT_MODE=""
OPT_RESUME=false
OPT_SERVE=false
OPT_FORMAT="text"
OPT_VERSION=false
OPT_HELP=false
SUBCOMMAND=""
TASK_DESCRIPTION=""
SUBCOMMAND_ARGS=()

# print_help
# Displays usage information
print_help() {
  cat <<'EOF'
Usage: agent [OPTIONS] [TASK_DESCRIPTION]
       agent <SUBCOMMAND>

Unified wrapper for agentic coding assistants (OpenCode / Claude Code)

Options:
  --claude          Force Claude Code backend
  --mode, -m MODE   Approval mode: manual (default), auto, hybrid
  --resume, -r      Resume previous session
  --serve           Start headless server (OpenCode only)
  --format, -f FMT  Output format: text (default), json
  --version, -V     Print version and exit
  --help, -h        Print help and exit

Subcommands:
  log               View action log [--session ID] [--tail N] [--format json|text]
  checkpoints       List checkpoints [--session ID]
  rollback ID       Rollback to checkpoint
  usage             Display token/cost metrics [--session ID] [--format json|text]
  sessions          List all sessions [--status active|completed|all]
  status            Show current session status
  bg                List background tasks [--kill ID]
  config            Show effective configuration [--validate]

Environment Variables:
  ANTHROPIC_API_KEY     Anthropic API key (for Claude Code)
  OPENAI_API_KEY        OpenAI API key (for OpenCode)
  GOOGLE_API_KEY        Google API key (for OpenCode)
  AGENT_BACKEND         Default backend: opencode (default) or claude
  AGENT_MODE            Default approval mode: manual (default), auto, hybrid
  AGENT_STATE_DIR       Override state directory (default: ~/.local/share/agent/)
  OPENCODE_SERVER_PASSWORD  Authentication for headless server mode

Exit Codes:
  0   Success
  1   General error
  2   Invalid arguments
  3   Missing API key
  4   Backend tool not installed
  5   Session not found (for --resume)
  6   Checkpoint not found (for rollback)
  10  Provider unavailable (after retries)
  11  Rate limited (after backoff exhausted)
EOF
}

# parse_args <args...>
# Parses command-line arguments into option variables
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --claude)
        OPT_CLAUDE="--claude"
        shift
        ;;
      --mode|-m)
        if [[ $# -lt 2 ]]; then
          echo "Error: --mode requires a value (manual, auto, hybrid)" >&2
          exit ${EXIT_INVALID_ARGS}
        fi
        OPT_MODE="$2"
        shift 2
        ;;
      --resume|-r)
        OPT_RESUME=true
        shift
        ;;
      --serve)
        OPT_SERVE=true
        shift
        ;;
      --format|-f)
        if [[ $# -lt 2 ]]; then
          echo "Error: --format requires a value (text, json)" >&2
          exit ${EXIT_INVALID_ARGS}
        fi
        OPT_FORMAT="$2"
        shift 2
        ;;
      --version|-V)
        OPT_VERSION=true
        shift
        ;;
      --help|-h)
        OPT_HELP=true
        shift
        ;;
      log|checkpoints|rollback|usage|sessions|status|bg|config)
        SUBCOMMAND="$1"
        shift
        SUBCOMMAND_ARGS=("$@")
        break
        ;;
      -*)
        echo "Error: Unknown option '$1'" >&2
        echo "Run 'agent --help' for usage" >&2
        exit ${EXIT_INVALID_ARGS}
        ;;
      *)
        TASK_DESCRIPTION="$1"
        shift
        ;;
    esac
  done

  # Read task from stdin if no positional argument and stdin is not a terminal
  if [[ -z "${TASK_DESCRIPTION}" && -z "${SUBCOMMAND}" && ! -t 0 ]]; then
    TASK_DESCRIPTION=$(cat)
  fi
}

# --- Subcommand Handlers ---

# cmd_config [--validate]
cmd_config() {
  local validate=false
  for arg in "${SUBCOMMAND_ARGS[@]:-}"; do
    if [[ "${arg}" == "--validate" ]]; then
      validate=true
    fi
  done

  load_config "$(pwd)"

  if [[ "${validate}" == "true" ]]; then
    echo "Configuration validation:"
    echo "  Backend: ${AGENT_CFG_BACKEND}"

    # Check backend availability
    if detect_backend "${AGENT_CFG_BACKEND}"; then
      echo "  Backend installed: yes"
    else
      echo "  Backend installed: NO — rebuild container" >&2
      exit ${EXIT_BACKEND_NOT_INSTALLED}
    fi

    # Check API keys
    if validate_any_api_key 2>/dev/null; then
      echo "  API key configured: yes"
    else
      echo "  API key configured: NO" >&2
      exit ${EXIT_MISSING_API_KEY}
    fi

    echo "  Mode: ${AGENT_CFG_MODE}"
    echo "  State dir: ${AGENT_CFG_STATE_DIR}"
    echo "  Status: OK"
  else
    if [[ "${OPT_FORMAT}" == "json" ]]; then
      get_config_summary
    else
      echo "Effective configuration:"
      echo "  backend: ${AGENT_CFG_BACKEND}"
      echo "  mode: ${AGENT_CFG_MODE}"
      echo "  state_dir: ${AGENT_CFG_STATE_DIR}"
      echo "  checkpoint.max_count: ${AGENT_CFG_CHECKPOINT_MAX_COUNT}"
      echo "  checkpoint.max_age_days: ${AGENT_CFG_CHECKPOINT_MAX_AGE_DAYS}"
      echo "  shell.timeout: ${AGENT_CFG_SHELL_TIMEOUT}s"
    fi
  fi
}

# cmd_log [--session ID] [--tail N] [--format json|text]
cmd_log() {
  local session_id="" tail_n="" fmt="${OPT_FORMAT}"
  local i=0
  while [[ ${i} -lt ${#SUBCOMMAND_ARGS[@]:-0} ]]; do
    case "${SUBCOMMAND_ARGS[${i}]:-}" in
      --session)
        i=$((i + 1))
        session_id="${SUBCOMMAND_ARGS[${i}]:-}"
        ;;
      --tail)
        i=$((i + 1))
        tail_n="${SUBCOMMAND_ARGS[${i}]:-}"
        ;;
      --format)
        i=$((i + 1))
        fmt="${SUBCOMMAND_ARGS[${i}]:-}"
        ;;
    esac
    i=$((i + 1))
  done

  if [[ -z "${session_id}" ]]; then
    echo "Error: --session ID required (or use 'agent status' to find current session)" >&2
    exit ${EXIT_INVALID_ARGS}
  fi

  if [[ -n "${tail_n}" ]]; then
    tail_log "${session_id}" "${tail_n}"
  elif [[ "${fmt}" == "json" ]]; then
    format_log_json "${session_id}"
  else
    format_log_text "${session_id}"
  fi
}

# cmd_checkpoints [--session ID]
cmd_checkpoints() {
  load_config "$(pwd)"

  local checkpoints
  checkpoints=$(list_checkpoints)

  if [[ -z "${checkpoints}" ]]; then
    echo "No checkpoints found."
  else
    if [[ "${OPT_FORMAT}" == "json" ]]; then
      local entries="[]"
      while IFS= read -r line; do
        local ref desc
        ref=$(echo "${line}" | cut -d: -f1)
        desc=$(echo "${line}" | cut -d: -f2- | sed 's/^ *//')
        entries=$(echo "${entries}" | jq --arg ref "${ref}" --arg desc "${desc}" '. + [{"ref": $ref, "description": $desc}]')
      done <<< "${checkpoints}"
      echo "${entries}" | jq .
    else
      echo "Checkpoints:"
      echo "${checkpoints}"
    fi
  fi
}

# cmd_rollback <CHECKPOINT_ID>
cmd_rollback() {
  local checkpoint_id="${SUBCOMMAND_ARGS[0]:-}"
  if [[ -z "${checkpoint_id}" ]]; then
    echo "Error: checkpoint ID required" >&2
    echo "Usage: agent rollback <CHECKPOINT_ID>" >&2
    exit ${EXIT_INVALID_ARGS}
  fi

  load_config "$(pwd)"

  if rollback_checkpoint "${checkpoint_id}"; then
    echo "Rolled back to checkpoint: ${checkpoint_id}"
    # Log the rollback action if a session is active
    local session_id
    session_id=$(find_latest_session "active" 2>/dev/null || true)
    if [[ -n "${session_id}" ]]; then
      log_action "${session_id}" "rollback" "${checkpoint_id}" "Rolled back to ${checkpoint_id}" "success"
    fi
  else
    exit ${EXIT_CHECKPOINT_NOT_FOUND}
  fi
}

# cmd_usage [--session ID] [--format json|text]
cmd_usage() {
  local session_id="" fmt="${OPT_FORMAT}"
  local i=0
  while [[ ${i} -lt ${#SUBCOMMAND_ARGS[@]:-0} ]]; do
    case "${SUBCOMMAND_ARGS[${i}]:-}" in
      --session)
        i=$((i + 1))
        session_id="${SUBCOMMAND_ARGS[${i}]:-}"
        ;;
      --format)
        i=$((i + 1))
        fmt="${SUBCOMMAND_ARGS[${i}]:-}"
        ;;
    esac
    i=$((i + 1))
  done

  load_config "$(pwd)"

  # Default to current/latest session if none specified
  if [[ -z "${session_id}" ]]; then
    session_id=$(find_latest_session "active" 2>/dev/null || find_latest_session "completed" 2>/dev/null || true)
    if [[ -z "${session_id}" ]]; then
      echo "Error: No session found. Specify --session ID" >&2
      exit ${EXIT_SESSION_NOT_FOUND}
    fi
  fi

  get_session_usage "${session_id}" "${fmt}"
}

# cmd_sessions [--status active|completed|all]
cmd_sessions() {
  local status_filter="all"
  local i=0
  while [[ ${i} -lt ${#SUBCOMMAND_ARGS[@]:-0} ]]; do
    case "${SUBCOMMAND_ARGS[${i}]:-}" in
      --status)
        i=$((i + 1))
        status_filter="${SUBCOMMAND_ARGS[${i}]:-all}"
        ;;
    esac
    i=$((i + 1))
  done

  load_config "$(pwd)"

  local sessions
  sessions=$(list_sessions "${status_filter}")

  if [[ -z "${sessions}" ]]; then
    echo "No sessions found."
  else
    if [[ "${OPT_FORMAT}" == "json" ]]; then
      echo "[${sessions//$'\n'/,}]" | jq .
    else
      echo "Sessions (filter: ${status_filter}):"
      echo "---"
      while IFS= read -r entry; do
        local id backend started status task
        id=$(echo "${entry}" | jq -r '.id')
        backend=$(echo "${entry}" | jq -r '.backend')
        started=$(echo "${entry}" | jq -r '.started_at')
        status=$(echo "${entry}" | jq -r '.status')
        task=$(echo "${entry}" | jq -r '.task // "—"')
        printf "  %-8s %-10s %-20s %-10s %s\n" "${id:0:8}…" "${backend}" "${started}" "${status}" "${task:0:40}"
      done <<< "${sessions}"
    fi
  fi
}

# cmd_status
cmd_status() {
  load_config "$(pwd)"

  local session_id
  session_id=$(find_latest_session "active" 2>/dev/null || true)

  if [[ -z "${session_id}" ]]; then
    echo "No active session."
    exit ${EXIT_SUCCESS}
  fi

  local session
  session=$(get_session "${session_id}")

  if [[ "${OPT_FORMAT}" == "json" ]]; then
    echo "${session}" | jq '{id, backend, status, started_at, task_description, approval_mode, token_usage}'
  else
    local backend status started task mode
    backend=$(echo "${session}" | jq -r '.backend')
    status=$(echo "${session}" | jq -r '.status')
    started=$(echo "${session}" | jq -r '.started_at')
    task=$(echo "${session}" | jq -r '.task_description')
    mode=$(echo "${session}" | jq -r '.approval_mode')
    local input_tokens output_tokens cost
    input_tokens=$(echo "${session}" | jq -r '.token_usage.input_tokens')
    output_tokens=$(echo "${session}" | jq -r '.token_usage.output_tokens')
    cost=$(echo "${session}" | jq -r '.token_usage.estimated_cost_usd')

    echo "Current Session: ${session_id:0:8}…"
    echo "  Status:    ${status}"
    echo "  Backend:   ${backend}"
    echo "  Mode:      ${mode}"
    echo "  Started:   ${started}"
    echo "  Task:      ${task}"
    echo "  Tokens:    ${input_tokens} in / ${output_tokens} out"
    echo "  Est. cost: \$${cost} USD"
  fi
}

# cmd_bg [--kill ID]
cmd_bg() {
  local kill_id=""
  local i=0
  while [[ ${i} -lt ${#SUBCOMMAND_ARGS[@]:-0} ]]; do
    case "${SUBCOMMAND_ARGS[${i}]:-}" in
      --kill)
        i=$((i + 1))
        kill_id="${SUBCOMMAND_ARGS[${i}]:-}"
        ;;
    esac
    i=$((i + 1))
  done

  load_config "$(pwd)"
  local bg_dir="${AGENT_CFG_STATE_DIR}/bg"

  if [[ -n "${kill_id}" ]]; then
    # Kill a specific background task
    local meta="${bg_dir}/${kill_id}.json"
    if [[ ! -f "${meta}" ]]; then
      echo "Error: Background task '${kill_id}' not found" >&2
      exit ${EXIT_ERROR}
    fi

    local pid
    pid=$(jq -r '.pid' "${meta}")
    if kill "${pid}" 2>/dev/null; then
      wait "${pid}" 2>/dev/null || true
      local tmp="${meta}.tmp"
      jq '.status = "stopped"' "${meta}" > "${tmp}"
      mv "${tmp}" "${meta}"
      echo "Stopped background task ${kill_id} (PID ${pid})"
    else
      echo "Task ${kill_id} already stopped"
      local tmp="${meta}.tmp"
      jq '.status = "stopped"' "${meta}" > "${tmp}"
      mv "${tmp}" "${meta}"
    fi
  else
    # List all background tasks
    if [[ ! -d "${bg_dir}" ]]; then
      echo "No background tasks."
      return 0
    fi

    local found=false
    if [[ "${OPT_FORMAT}" == "json" ]]; then
      local entries="[]"
      for meta_file in "${bg_dir}"/*.json; do
        [[ -f "${meta_file}" ]] || continue
        found=true
        entries=$(echo "${entries}" | jq --slurpfile entry "${meta_file}" '. + $entry')
      done
      echo "${entries}" | jq .
    else
      for meta_file in "${bg_dir}"/*.json; do
        [[ -f "${meta_file}" ]] || continue
        found=true
        local id cmd pid status started
        id=$(jq -r '.id' "${meta_file}")
        cmd=$(jq -r '.command' "${meta_file}")
        pid=$(jq -r '.pid' "${meta_file}")
        status=$(jq -r '.status' "${meta_file}")
        started=$(jq -r '.started_at' "${meta_file}")

        # Check if process is still running
        if [[ "${status}" == "running" ]] && ! kill -0 "${pid}" 2>/dev/null; then
          status="dead"
        fi

        printf "  %-10s PID=%-8s %-10s %-20s %s\n" "${id}" "${pid}" "${status}" "${started}" "${cmd}"
      done

      if [[ "${found}" == "false" ]]; then
        echo "No background tasks."
      fi
    fi
  fi
}

# --- Signal Handler ---

# _on_signal <session_id>
# Handles SIGTERM/SIGINT by pausing the session
_on_signal() {
  local session_id="$1"
  update_session_status "${session_id}" "paused"
  log_action "${session_id}" "session_pause" "${session_id}" "Session interrupted by signal" "success"
  exit ${EXIT_ERROR}
}

# _handle_provider_failure <session_id> <backend> <exit_code>
# Handles provider unavailability by pausing and notifying
_handle_provider_failure() {
  local session_id="$1"
  local backend="$2"
  local exit_code="$3"

  update_session_status "${session_id}" "paused"
  log_action "${session_id}" "error" "${backend}" "Provider unavailable (exit ${exit_code})" "failure"

  echo "" >&2
  echo "Error: Provider '${backend}' is unavailable (exit code: ${exit_code})" >&2
  echo "Session has been paused. To resume:" >&2
  echo "  agent --resume" >&2
  if [[ "${backend}" == "opencode" ]]; then
    echo "  Or switch to Claude Code: agent --claude --resume" >&2
  else
    echo "  Or switch to OpenCode: AGENT_BACKEND=opencode agent --resume" >&2
  fi

  exit ${EXIT_PROVIDER_UNAVAILABLE}
}

# --- Main Execution ---

main() {
  parse_args "$@"

  # Handle --version
  if [[ "${OPT_VERSION}" == "true" ]]; then
    echo "agent ${AGENT_VERSION}"
    exit ${EXIT_SUCCESS}
  fi

  # Handle --help
  if [[ "${OPT_HELP}" == "true" ]]; then
    print_help
    exit ${EXIT_SUCCESS}
  fi

  # Handle subcommands
  if [[ -n "${SUBCOMMAND}" ]]; then
    case "${SUBCOMMAND}" in
      config)       cmd_config ;;
      log)          cmd_log ;;
      checkpoints)  cmd_checkpoints ;;
      rollback)     cmd_rollback ;;
      usage)        cmd_usage ;;
      sessions)     cmd_sessions ;;
      status)       cmd_status ;;
      bg)           cmd_bg ;;
      *)
        echo "Error: Unknown subcommand '${SUBCOMMAND}'" >&2
        exit ${EXIT_INVALID_ARGS}
        ;;
    esac
    exit $?
  fi

  # Main task execution flow
  if [[ -z "${TASK_DESCRIPTION}" && "${OPT_RESUME}" == "false" && "${OPT_SERVE}" == "false" ]]; then
    echo "Error: No task description provided" >&2
    echo "Usage: agent [OPTIONS] \"task description\"" >&2
    echo "Run 'agent --help' for more information" >&2
    exit ${EXIT_INVALID_ARGS}
  fi

  # Load configuration
  load_config "$(pwd)"

  # Override mode from flag if provided
  if [[ -n "${OPT_MODE}" ]]; then
    AGENT_CFG_MODE="${OPT_MODE}"
  fi

  # Select backend
  local backend
  backend=$(select_backend "${OPT_CLAUDE}") || exit $?

  # Validate API key for selected backend
  local provider
  provider=$(get_required_api_key_for_backend "${backend}")
  if [[ -n "${provider}" ]]; then
    validate_api_key "${provider}" || exit ${EXIT_MISSING_API_KEY}
  else
    validate_any_api_key || exit ${EXIT_MISSING_API_KEY}
  fi

  # Handle --serve mode
  if [[ "${OPT_SERVE}" == "true" ]]; then
    if [[ "${backend}" != "opencode" ]]; then
      echo "Error: --serve is only supported with the OpenCode backend" >&2
      exit ${EXIT_INVALID_ARGS}
    fi
    echo "Starting headless server on port 4096..."
    exec opencode serve
  fi

  # Handle --resume mode
  if [[ "${OPT_RESUME}" == "true" ]]; then
    local resume_session
    resume_session=$(find_latest_session "active" 2>/dev/null || find_latest_session "paused" 2>/dev/null || true)
    if [[ -z "${resume_session}" ]]; then
      echo "Error: No active or paused session to resume" >&2
      exit ${EXIT_SESSION_NOT_FOUND}
    fi
    update_session_status "${resume_session}" "active"
    log_action "${resume_session}" "session_resume" "${resume_session}" "Resuming session" "success"
    if [[ "${backend}" == "claude" ]]; then
      exec claude --continue
    else
      exec opencode run --continue
    fi
  fi

  # Apply exclusion patterns
  apply_exclusions "${backend}" "$(pwd)"

  # Apply approval mode permissions
  apply_approval_mode "${backend}" "${AGENT_CFG_MODE}" "$(pwd)"

  # Create session
  local session_id
  session_id=$(create_session "${backend}" "${TASK_DESCRIPTION}" "${AGENT_CFG_MODE}")
  log_action "${session_id}" "session_start" "${session_id}" "Starting session: ${TASK_DESCRIPTION}" "success"

  # Create pre-task checkpoint
  if [[ "${AGENT_CFG_CHECKPOINT_ENABLED}" == "true" ]]; then
    create_checkpoint "${session_id}" "Pre-task: ${TASK_DESCRIPTION:0:60}" "pre_task"
    if [[ "${AGENT_CFG_CHECKPOINT_AUTO_PRUNE}" == "true" ]]; then
      prune_checkpoints "${AGENT_CFG_CHECKPOINT_MAX_COUNT}"
    fi
  fi

  # Set up signal handlers for session persistence
  trap '_on_signal "${session_id}"' SIGTERM SIGINT

  # Build and execute backend command
  local cmd exit_code=0
  cmd=$(build_backend_command "${backend}" "${AGENT_CFG_MODE}" "${TASK_DESCRIPTION}")
  echo "Launching ${backend} (mode: ${AGENT_CFG_MODE})..."
  eval "${cmd}" || exit_code=$?

  # Update session on completion
  if [[ ${exit_code} -eq 0 ]]; then
    update_session_status "${session_id}" "completed"
    log_action "${session_id}" "session_complete" "${session_id}" "Task completed" "success"
  elif [[ ${exit_code} -eq ${EXIT_PROVIDER_UNAVAILABLE} || ${exit_code} -eq ${EXIT_RATE_LIMITED} ]]; then
    _handle_provider_failure "${session_id}" "${backend}" "${exit_code}"
  else
    update_session_status "${session_id}" "failed"
    log_action "${session_id}" "session_complete" "${session_id}" "Task failed (exit ${exit_code})" "failure"
  fi

  exit ${exit_code}
}

# Run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
