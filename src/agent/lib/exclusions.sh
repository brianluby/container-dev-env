#!/usr/bin/env bash
# exclusions.sh — .agentignore parsing and tool-native translation
# Version: 1.0.0
# Dependencies: none

set -euo pipefail

# Default exclusion patterns (applied even without .agentignore file)
readonly DEFAULT_EXCLUSIONS=(
  ".env"
  ".env.*"
  "*.pem"
  "*.key"
  "*.p12"
  "*.pfx"
  "credentials/"
  "secrets/"
  ".secret*"
  ".npmrc"
  ".pypirc"
  ".docker/config.json"
  "*.sqlite"
  "*.db"
  ".ssh/"
  "id_rsa*"
  "id_ed25519*"
)

# Loaded exclusion patterns (populated by load_exclusions)
EXCLUSION_PATTERNS=()

# load_exclusions <workspace_path>
# Loads default patterns + project .agentignore patterns
load_exclusions() {
  local workspace="${1:-.}"
  local agentignore="${workspace}/.agentignore"

  # Start with defaults
  EXCLUSION_PATTERNS=("${DEFAULT_EXCLUSIONS[@]}")

  # Load project-specific patterns if file exists
  if [[ -f "${agentignore}" ]]; then
    while IFS= read -r line; do
      # Skip empty lines and comments
      [[ -z "${line}" ]] && continue
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue
      # Trim whitespace
      line=$(echo "${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [[ -n "${line}" ]] && EXCLUSION_PATTERNS+=("${line}")
    done < "${agentignore}"
  fi
}

# match_exclusion <filepath> <pattern>
# Returns 0 if the filepath matches the exclusion pattern
match_exclusion() {
  local filepath="$1"
  local pattern="$2"

  # Directory pattern (trailing /)
  if [[ "${pattern}" == */ ]]; then
    local dir_pattern="${pattern%/}"
    if [[ "${filepath}" == "${dir_pattern}/"* ]] || [[ "${filepath}" == "${dir_pattern}" ]]; then
      return 0
    fi
    return 1
  fi

  # Exact match
  if [[ "${filepath}" == "${pattern}" ]]; then
    return 0
  fi

  # Basename match for patterns without /
  if [[ "${pattern}" != */* ]]; then
    local basename="${filepath##*/}"
    # Use bash pattern matching
    # shellcheck disable=SC2254
    case "${basename}" in
      ${pattern}) return 0 ;;
    esac
    # Also check full path
    # shellcheck disable=SC2254
    case "${filepath}" in
      ${pattern}) return 0 ;;
    esac
  fi

  # Path-based glob match
  # shellcheck disable=SC2254
  case "${filepath}" in
    ${pattern}) return 0 ;;
  esac

  return 1
}

# is_excluded <filepath>
# Returns 0 if the filepath matches any loaded exclusion pattern
is_excluded() {
  local filepath="$1"
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    if match_exclusion "${filepath}" "${pattern}"; then
      return 0
    fi
  done
  return 1
}

# translate_to_opencode
# Outputs OpenCode-compatible watcher ignore config (JSON fragment)
translate_to_opencode() {
  echo "{"
  echo "  \"watcher\": {"
  echo "    \"ignore\": ["
  local first=true
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    if [[ "${first}" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    printf '      "%s"' "${pattern}"
  done
  echo ""
  echo "    ]"
  echo "  }"
  echo "}"
}

# translate_to_claude
# Outputs Claude Code-compatible settings ignore config (JSON fragment)
translate_to_claude() {
  echo "{"
  echo "  \"permissions\": {"
  echo "    \"deny\": ["
  local first=true
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    if [[ "${first}" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    printf '      "Read(%s)"' "${pattern}"
  done
  echo ""
  echo "    ]"
  echo "  }"
  echo "}"
}

# apply_exclusions <backend> <workspace>
# Applies exclusion patterns to the given backend's native config
apply_exclusions() {
  local backend="$1"
  local workspace="$2"

  load_exclusions "${workspace}"

  case "${backend}" in
    opencode)
      # Write patterns to OpenCode config
      local oc_config="${HOME}/.config/opencode/opencode.json"
      mkdir -p "$(dirname "${oc_config}")"
      translate_to_opencode > "${oc_config}.exclusions"
      ;;
    claude)
      # Write patterns to Claude Code settings
      local claude_settings="${HOME}/.claude/settings.json"
      mkdir -p "$(dirname "${claude_settings}")"
      translate_to_claude > "${claude_settings}.exclusions"
      ;;
  esac
}
