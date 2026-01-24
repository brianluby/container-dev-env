#!/usr/bin/env bash
# common.sh — Shared shell library for voice-input scripts
# Source this file: source "$(dirname "$0")/lib/common.sh"

set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────────────

readonly VOICE_INPUT_CONFIG_DIR="${HOME}/.config/voice-input"
readonly VOICE_INPUT_SETTINGS="${VOICE_INPUT_CONFIG_DIR}/settings.yaml"
readonly VOICE_INPUT_VOCABULARY="${VOICE_INPUT_CONFIG_DIR}/vocabulary.yaml"
readonly VOICE_INPUT_CLEANUP_PROMPT="${VOICE_INPUT_CONFIG_DIR}/ai-cleanup-prompt.txt"

readonly VALID_TOOLS=("superwhisper" "voiceink")
readonly VALID_MODELS=("tiny" "base" "small" "medium" "large-v3" "turbo")
readonly VALID_CLEANUP_TIERS=("none" "rules" "local_llm" "cloud")
readonly VALID_ACTIVATION_MODES=("push_to_talk" "toggle")

# ─── Logging ──────────────────────────────────────────────────────────────────

_log() {
  local level="$1"
  shift
  printf "[%s] %s: %s\n" "$(date +%H:%M:%S)" "$level" "$*" >&2
}

log_info() {
  _log "INFO" "$@"
}

log_warn() {
  _log "WARN" "$@"
}

log_error() {
  _log "ERROR" "$@"
}

log_success() {
  _log " OK " "$@"
}

# ─── Validation Helpers ───────────────────────────────────────────────────────

# Check if a value is in an array
# Usage: is_valid_value "value" "${array[@]}"
is_valid_value() {
  local value="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$value" ]]; then
      return 0
    fi
  done
  return 1
}

# Validate a value against allowed options and print error if invalid
# Usage: validate_option "tool" "$tool" "${VALID_TOOLS[@]}"
validate_option() {
  local name="$1"
  local value="$2"
  shift 2
  if ! is_valid_value "$value" "$@"; then
    log_error "Invalid $name: '$value'. Must be one of: $*"
    return 1
  fi
}

# ─── Platform Detection ───────────────────────────────────────────────────────

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

is_apple_silicon() {
  is_macos && [[ "$(uname -m)" == "arm64" ]]
}

# ─── File Helpers ─────────────────────────────────────────────────────────────

# Ensure a directory exists, creating it if needed
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_info "Created directory: $dir"
  fi
}

# Check if a command is available
command_exists() {
  command -v "$1" &>/dev/null
}

# Read a YAML value (simple key: value extraction, no nested support)
# Usage: yaml_get "key" "file.yaml"
# Returns empty string with exit 0 if key not found, exit 1 if file doesn't exist
yaml_get() {
  local key="$1"
  local file="$2"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  awk -F':' -v k="$key" '
    $1 == k {
      # Remove "key:" and leading whitespace from the value portion
      val = $0
      sub("^[^:]*:[[:space:]]*", "", val)
      # Trim trailing whitespace
      sub("[[:space:]]*$", "", val)
      print val
    }
  ' "$file"
  return 0
}

# ─── Exit Code Constants ─────────────────────────────────────────────────────

readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_MISSING_PREREQUISITE=2
readonly EXIT_INVALID_CONFIG=3
readonly EXIT_PLATFORM_NOT_SUPPORTED=4
readonly EXIT_VOCAB_NOT_FOUND=5
