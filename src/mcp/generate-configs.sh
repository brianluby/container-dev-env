#!/bin/bash
# generate-configs.sh — Generate tool-native MCP config files from source config
#
# Reads the unified MCP source configuration and generates config files
# for Claude Code, Cline, and Continue.
#
# Usage: generate-configs.sh [OPTIONS]
#
# Options:
#   --source PATH     Path to source config (default: /workspace/.mcp/config.json)
#   --tools TOOLS     Comma-separated tool list (default: claude-code,cline,continue)
#   --dry-run         Print generated configs to stdout without writing files
#   --quiet           Suppress informational output (errors still printed to stderr)
#   --help            Show usage information
#
# Exit codes:
#   0    Success
#   1    Source config not found or not readable
#   2    Source config is not valid JSON
#   3    Source config fails schema validation
#   4    Write error (cannot create output file/directory)

set -e
set -o pipefail

# --- Constants ---
LOG_PREFIX="[mcp-generate]"
DEFAULT_SOURCE="/workspace/.mcp/config.json"
FALLBACK_SOURCE="/home/dev/.mcp/defaults/mcp-config.json"

# Output paths (overridable via env vars for testing)
CLAUDE_CODE_OUTPUT="${MCP_OUTPUT_CLAUDE:-/workspace/.claude/settings.local.json}"
CLINE_OUTPUT="${MCP_OUTPUT_CLINE:-${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json}"
CONTINUE_OUTPUT="${MCP_OUTPUT_CONTINUE:-${HOME}/.continue/config.yaml}"

# --- State ---
SOURCE_PATH=""
TOOLS="claude-code,cline,continue"
DRY_RUN=false
QUIET=false

# --- Logging ---
log() {
  if [[ "$QUIET" != true ]]; then
    echo "${LOG_PREFIX} $*" >&2
  fi
}

log_error() {
  echo "${LOG_PREFIX} ERROR: $*" >&2
}

log_warn() {
  if [[ "$QUIET" != true ]]; then
    echo "${LOG_PREFIX}   WARN: $*" >&2
  fi
}

# --- Usage ---
usage() {
  cat <<'EOF'
Usage: generate-configs.sh [OPTIONS]

Generate tool-native MCP config files from a unified source configuration.

Options:
  --source PATH     Path to source config (default: /workspace/.mcp/config.json)
  --tools TOOLS     Comma-separated tool list (default: claude-code,cline,continue)
  --dry-run         Print generated configs to stdout without writing files
  --quiet           Suppress informational output (errors still printed to stderr)
  --help            Show usage information

Exit codes:
  0    Success
  1    Source config not found or not readable
  2    Source config is not valid JSON
  3    Source config fails schema validation
  4    Write error (cannot create output file/directory)

Examples:
  generate-configs.sh
  generate-configs.sh --source ./my-config.json --tools claude-code
  generate-configs.sh --dry-run --quiet
EOF
}

# --- Argument Parsing ---
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source)
        if [[ $# -lt 2 ]]; then
          log_error "--source requires a path argument"
          exit 1
        fi
        SOURCE_PATH="$2"
        shift 2
        ;;
      --tools)
        if [[ $# -lt 2 ]]; then
          log_error "--tools requires a comma-separated list"
          exit 1
        fi
        TOOLS="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --quiet)
        QUIET=true
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage >&2
        exit 1
        ;;
    esac
  done
}

# --- Security: Symlink Check ---
# Ensure --source path does not follow symlinks outside workspace
validate_source_path() {
  local path="$1"

  if [[ -L "$path" ]]; then
    local resolved
    resolved="$(readlink -f "$path" 2>/dev/null || true)"
    if [[ -z "$resolved" ]]; then
      log_error "Cannot resolve symlink: ${path}"
      exit 1
    fi
    # Allow symlinks within /workspace or /home/dev
    if [[ "$resolved" != /workspace/* && "$resolved" != /home/dev/* ]]; then
      log_error "Source path is a symlink outside workspace: ${path} -> ${resolved}"
      exit 1
    fi
  fi
}

# --- Resolve Source Config ---
resolve_source() {
  if [[ -n "$SOURCE_PATH" ]]; then
    validate_source_path "$SOURCE_PATH"
    if [[ ! -f "$SOURCE_PATH" || ! -r "$SOURCE_PATH" ]]; then
      log_error "Source config not found or not readable: ${SOURCE_PATH}"
      exit 1
    fi
    echo "$SOURCE_PATH"
    return
  fi

  # Try default, then fallback
  if [[ -f "$DEFAULT_SOURCE" && -r "$DEFAULT_SOURCE" ]]; then
    validate_source_path "$DEFAULT_SOURCE"
    echo "$DEFAULT_SOURCE"
    return
  fi

  if [[ -f "$FALLBACK_SOURCE" && -r "$FALLBACK_SOURCE" ]]; then
    validate_source_path "$FALLBACK_SOURCE"
    echo "$FALLBACK_SOURCE"
    return
  fi

  log_error "Source config not found at ${DEFAULT_SOURCE} or ${FALLBACK_SOURCE}"
  exit 1
}

# --- JSON Validation ---
validate_json() {
  local source="$1"

  # Check valid JSON
  if ! jq empty "$source" 2>/dev/null; then
    log_error "Source config is not valid JSON: ${source}"
    exit 2
  fi

  # Check mcpServers key exists
  if ! jq -e '.mcpServers' "$source" >/dev/null 2>&1; then
    log_error "Source config missing required 'mcpServers' key: ${source}"
    exit 3
  fi
}

# --- Environment Variable Substitution ---
# Substitutes ${VAR_NAME} patterns in env values with actual env var values.
# Returns the processed JSON with resolved env vars.
substitute_env_vars() {
  local servers_json="$1"

  # Process each server's env values
  echo "$servers_json" | jq -c 'to_entries[]' | while IFS= read -r entry; do
    local server_name
    server_name=$(echo "$entry" | jq -r '.key')
    local server_config
    server_config=$(echo "$entry" | jq -c '.value')

    # Check if server has env object
    local has_env
    has_env=$(echo "$server_config" | jq 'has("env")')

    if [[ "$has_env" == "true" ]]; then
      # Process each env var
      local env_obj
      env_obj=$(echo "$server_config" | jq -c '.env')

      local new_env
      new_env=$(echo "$env_obj" | jq -c 'to_entries[]' | while IFS= read -r env_entry; do
        local env_key env_value
        env_key=$(echo "$env_entry" | jq -r '.key')
        env_value=$(echo "$env_entry" | jq -r '.value')

        # Check for ${VAR_NAME} pattern
        if [[ "$env_value" =~ \$\{([^}]+)\} ]]; then
          local var_name="${BASH_REMATCH[1]}"
          local resolved_value=""

          # Check if the env var is set
          if [[ -n "${!var_name+x}" ]]; then
            resolved_value="${!var_name}"
          else
            log_warn "${var_name} not set (${server_name} server may fail)"
          fi

          # Output the entry with resolved value (jq handles JSON escaping)
          jq -n --arg key "$env_key" --arg val "$resolved_value" \
            '{($key): $val}'
        else
          # No substitution needed, pass through
          jq -n --arg key "$env_key" --arg val "$env_value" \
            '{($key): $val}'
        fi
      done | jq -s 'add // {}')

      # Update server config with resolved env
      server_config=$(echo "$server_config" | jq --argjson env "$new_env" '.env = $env')
    fi

    # Output as key-value pair
    jq -n --arg key "$server_name" --argjson val "$server_config" \
      '{($key): $val}'
  done | jq -s 'add // {}'
}

# --- Filter Enabled Servers ---
filter_enabled() {
  local source="$1"

  # enabled defaults to true if not specified
  jq '.mcpServers | to_entries | map(select(.value.enabled == true or .value.enabled == null)) | from_entries' "$source"
}

# --- Get Disabled Server Names ---
get_disabled_names() {
  local source="$1"
  jq -r '.mcpServers | to_entries[] | select(.value.enabled == false) | .key' "$source"
}

# --- Get Enabled Server Names ---
get_enabled_names() {
  local source="$1"
  jq -r '.mcpServers | to_entries[] | select(.value.enabled == true or .value.enabled == null) | .key' "$source"
}

# --- Write File with Permissions ---
write_output() {
  local path="$1"
  local content="$2"
  local label="$3"

  if [[ "$DRY_RUN" == true ]]; then
    echo "--- ${label} (${path}) ---"
    echo "$content"
    echo ""
    return
  fi

  # Create parent directory
  local dir
  dir="$(dirname "$path")"
  if ! mkdir -p "$dir" 2>/dev/null; then
    log_error "Cannot create directory: ${dir}"
    exit 4
  fi

  # Write file
  if ! echo "$content" > "$path" 2>/dev/null; then
    log_error "Cannot write file: ${path}"
    exit 4
  fi

  # Set permissions to 0600
  chmod 0600 "$path"

  log "  Generated: ${path}"
}

# --- Generate Claude Code Config ---
generate_claude_code() {
  local servers_json="$1"

  # Remove enabled, description fields; remove empty args arrays and empty env objects
  local cleaned
  cleaned=$(echo "$servers_json" | jq '
    to_entries | map(
      .value |= (
        del(.enabled, .description) |
        if .args == [] then del(.args) else . end |
        if .env == {} then del(.env) else . end
      )
    ) | from_entries
  ')

  local output
  if [[ -f "$CLAUDE_CODE_OUTPUT" && "$DRY_RUN" != true ]]; then
    # Merge mcpServers into existing file, preserving other keys
    local existing
    existing=$(jq '.' "$CLAUDE_CODE_OUTPUT" 2>/dev/null || echo '{}')
    output=$(echo "$existing" | jq --argjson servers "$cleaned" '.mcpServers = $servers')
  else
    # Create new file
    output=$(jq -n --argjson servers "$cleaned" '{"mcpServers": $servers}')
  fi

  write_output "$CLAUDE_CODE_OUTPUT" "$output" "Claude Code"
}

# --- Generate Cline Config ---
generate_cline() {
  local servers_json="$1"

  # Remove enabled, description; add disabled: false and autoApprove: []
  local cleaned
  cleaned=$(echo "$servers_json" | jq '
    to_entries | map(
      .value |= (
        del(.enabled, .description) |
        . + {"disabled": false, "autoApprove": []}
      )
    ) | from_entries
  ')

  local output
  output=$(jq -n --argjson servers "$cleaned" '{"mcpServers": $servers}')

  write_output "$CLINE_OUTPUT" "$output" "Cline"
}

# --- Generate Continue Config ---
generate_continue() {
  local servers_json="$1"

  # Convert from object format to array format with name field
  local servers_array
  servers_array=$(echo "$servers_json" | jq '
    to_entries | map(
      {name: .key} + (.value | del(.enabled, .description))
    )
  ')

  # Use python3 + yaml module to generate YAML
  local yaml_content
  yaml_content=$(echo "$servers_array" | python3 -c "
import yaml, json, sys

servers = json.loads(sys.stdin.read())
data = {'mcpServers': servers}
yaml.dump(data, sys.stdout, default_flow_style=False, sort_keys=False)
")

  if [[ -f "$CONTINUE_OUTPUT" && "$DRY_RUN" != true ]]; then
    # Replace only the mcpServers section, preserve other content
    local merged
    merged=$(echo "$servers_array" | CONTINUE_CONFIG_PATH="$CONTINUE_OUTPUT" python3 -c "
import yaml, json, sys, os

existing_file = os.environ.get('CONTINUE_CONFIG_PATH', '')
servers = json.loads(sys.stdin.read())

try:
    with open(existing_file, 'r') as f:
        existing = yaml.safe_load(f) or {}
except (FileNotFoundError, yaml.YAMLError):
    existing = {}

existing['mcpServers'] = servers
yaml.dump(existing, sys.stdout, default_flow_style=False, sort_keys=False)
") || {
      log_error "Failed to generate Continue YAML config"
      exit 4
    }
    write_output "$CONTINUE_OUTPUT" "$merged" "Continue"
  else
    write_output "$CONTINUE_OUTPUT" "$yaml_content" "Continue"
  fi
}

# --- Tool Selection Check ---
tool_enabled() {
  local tool="$1"
  echo "$TOOLS" | tr ',' '\n' | grep -qx "$tool"
}

# --- Main ---
main() {
  parse_args "$@"

  log "=== Generating MCP Configs ==="

  # Resolve and validate source
  local source
  source="$(resolve_source)"
  log "  Source: ${source}"

  validate_json "$source"

  # Get enabled/disabled server names for logging
  local enabled_names disabled_names
  enabled_names=$(get_enabled_names "$source" | tr '\n' ', ' | sed 's/,$//')
  disabled_names=$(get_disabled_names "$source" | tr '\n' ', ' | sed 's/,$//')

  log "  Enabled servers: ${enabled_names}"
  if [[ -n "$disabled_names" ]]; then
    log "  Skipped (disabled): ${disabled_names}"
  fi

  # Filter to enabled servers
  local enabled_json
  enabled_json=$(filter_enabled "$source")

  # Substitute environment variables
  local resolved_json
  resolved_json=$(substitute_env_vars "$enabled_json")

  # Generate configs for selected tools
  if tool_enabled "claude-code"; then
    generate_claude_code "$resolved_json"
  fi

  if tool_enabled "cline"; then
    generate_cline "$resolved_json"
  fi

  if tool_enabled "continue"; then
    generate_continue "$resolved_json"
  fi

  log "=== Generation Complete ==="
}

main "$@"
