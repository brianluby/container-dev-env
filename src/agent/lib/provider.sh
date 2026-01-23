#!/usr/bin/env bash
# provider.sh — Provider availability checking and backend selection
# Version: 1.0.0
# Dependencies: none (uses command -v for detection)

set -euo pipefail

# Exit codes (from CLI contract)
readonly EXIT_MISSING_API_KEY=3
readonly EXIT_BACKEND_NOT_INSTALLED=4

# detect_backend <backend_name>
# Returns 0 if the backend binary is available on PATH
detect_backend() {
  local backend="$1"
  if command -v "${backend}" &>/dev/null; then
    return 0
  fi
  return 1
}

# validate_api_key <provider>
# Checks that the required API key environment variable is set for the given provider
validate_api_key() {
  local provider="$1"
  case "${provider}" in
    anthropic)
      if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        echo "Error: ANTHROPIC_API_KEY environment variable is not set" >&2
        echo "Set it with: export ANTHROPIC_API_KEY='your-key'" >&2
        return 1
      fi
      ;;
    openai)
      if [[ -z "${OPENAI_API_KEY:-}" ]]; then
        echo "Error: OPENAI_API_KEY environment variable is not set" >&2
        echo "Set it with: export OPENAI_API_KEY='your-key'" >&2
        return 1
      fi
      ;;
    google)
      if [[ -z "${GOOGLE_API_KEY:-}" ]]; then
        echo "Error: GOOGLE_API_KEY environment variable is not set" >&2
        echo "Set it with: export GOOGLE_API_KEY='your-key'" >&2
        return 1
      fi
      ;;
    *)
      echo "Error: Unknown provider '${provider}'" >&2
      return 1
      ;;
  esac
  return 0
}

# validate_any_api_key
# Returns 0 if at least one LLM provider API key is configured
validate_any_api_key() {
  if [[ -n "${ANTHROPIC_API_KEY:-}" ]] || \
     [[ -n "${OPENAI_API_KEY:-}" ]] || \
     [[ -n "${GOOGLE_API_KEY:-}" ]]; then
    return 0
  fi
  echo "Error: No API key configured. Set at least one of:" >&2
  echo "  ANTHROPIC_API_KEY, OPENAI_API_KEY, or GOOGLE_API_KEY" >&2
  return 1
}

# select_backend <claude_flag>
# Selects the backend based on priority: --claude flag > AGENT_BACKEND env > default (opencode)
# Outputs the selected backend name on stdout
# Returns EXIT_BACKEND_NOT_INSTALLED if the selected backend is not available
select_backend() {
  local claude_flag="${1:-}"
  local selected=""

  # Priority 1: --claude flag
  if [[ "${claude_flag}" == "--claude" ]]; then
    selected="claude"
  # Priority 2: AGENT_BACKEND env var
  elif [[ -n "${AGENT_BACKEND:-}" ]]; then
    selected="${AGENT_BACKEND}"
  # Priority 3: Default
  else
    selected="opencode"
  fi

  # Verify the selected backend is installed
  if ! detect_backend "${selected}"; then
    echo "Error: Backend '${selected}' is not installed" >&2
    echo "Rebuild the container or check your PATH" >&2
    return ${EXIT_BACKEND_NOT_INSTALLED}
  fi

  echo "${selected}"
  return 0
}

# get_required_api_key_for_backend <backend>
# Returns the provider name whose API key is required for the given backend
get_required_api_key_for_backend() {
  local backend="$1"
  case "${backend}" in
    claude)
      echo "anthropic"
      ;;
    opencode)
      # OpenCode supports multiple providers; check what's available
      if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        echo "anthropic"
      elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
        echo "openai"
      elif [[ -n "${GOOGLE_API_KEY:-}" ]]; then
        echo "google"
      else
        echo ""
      fi
      ;;
  esac
}

# build_backend_command <backend> <mode> <task_description>
# Constructs the command array for launching the selected backend
# Outputs the command string to stdout
build_backend_command() {
  local backend="$1"
  local mode="$2"
  local task="$3"

  case "${backend}" in
    opencode)
      local cmd="opencode run"
      # Mode is handled by config file, not CLI flags for opencode
      echo "${cmd} \"${task}\""
      ;;
    claude)
      local cmd="claude -p"
      if [[ "${mode}" == "auto" ]]; then
        cmd="claude --dangerously-skip-permissions -p"
      fi
      echo "${cmd} \"${task}\""
      ;;
  esac
}

# build_serve_command
# Constructs the command for headless server mode (OpenCode only)
build_serve_command() {
  echo "opencode serve"
}

# apply_approval_mode <backend> <mode> <workspace>
# Configures the backend's native permission system according to the approval mode
apply_approval_mode() {
  local backend="$1"
  local mode="$2"
  local workspace="${3:-.}"

  case "${backend}" in
    opencode)
      _apply_opencode_permissions "${mode}" "${workspace}"
      ;;
    claude)
      _apply_claude_permissions "${mode}" "${workspace}"
      ;;
  esac
}

# _apply_opencode_permissions <mode> <workspace>
# Maps approval modes to OpenCode tool permission config
_apply_opencode_permissions() {
  local mode="$1"
  local workspace="$2"
  local config_dir="${HOME}/.config/opencode"
  mkdir -p "${config_dir}"

  case "${mode}" in
    manual)
      # All tools require ask confirmation
      cat > "${config_dir}/permissions.json" <<'EOF'
{"tools": {"*": "ask"}}
EOF
      ;;
    auto)
      # All tools allowed without confirmation
      cat > "${config_dir}/permissions.json" <<'EOF'
{"tools": {"*": "allow"}}
EOF
      ;;
    hybrid)
      # Read-only tools allowed, write tools ask, dangerous always ask
      cat > "${config_dir}/permissions.json" <<'EOF'
{"tools": {"read": "allow", "write": "ask", "bash": "ask", "*": "ask"}}
EOF
      ;;
  esac
}

# _apply_claude_permissions <mode> <workspace>
# Maps approval modes to Claude Code settings
_apply_claude_permissions() {
  local mode="$1"
  local workspace="$2"
  local claude_dir="${workspace}/.claude"
  mkdir -p "${claude_dir}"

  case "${mode}" in
    manual)
      # Default Claude Code behavior — no settings override needed
      rm -f "${claude_dir}/settings.json"
      ;;
    auto)
      # --dangerously-skip-permissions flag is used at command level, not config
      rm -f "${claude_dir}/settings.json"
      ;;
    hybrid)
      # Per-tool policies via settings
      cat > "${claude_dir}/settings.json" <<'EOF'
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "WebSearch"],
    "deny": [],
    "ask": ["Write", "Edit", "Bash", "Task"]
  }
}
EOF
      ;;
  esac
}
