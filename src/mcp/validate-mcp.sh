#!/bin/bash
set -e
set -o pipefail

# validate-mcp.sh - Validate MCP server availability and configuration
# Exit codes:
#   0 - All enabled servers validated successfully
#   1 - Config file missing or unreadable
#   2 - Config file is not valid JSON
#   3 - One or more enabled servers have issues (warnings printed, non-fatal)

readonly LOG_PREFIX="[mcp-validate]"
readonly DEFAULT_SOURCE="/workspace/.mcp/config.json"
readonly FALLBACK_SOURCE="/home/dev/.mcp/defaults/mcp-config.json"

# Options
opt_source=""
opt_quiet=false
opt_json=false

# Counters
count_enabled=0
count_ok=0
count_warn=0
count_error=0
count_skip=0

# JSON accumulator for --json mode
json_servers=""

###############################################################################
# Helpers
###############################################################################

usage() {
    cat <<'EOF'
Usage: validate-mcp.sh [OPTIONS]

Validates MCP server availability and configuration at container startup.

Options:
  --source PATH     Path to source config (default: /workspace/.mcp/config.json)
  --quiet           Only output errors and warnings
  --json            Output validation results as JSON
  --help            Show usage information

Exit codes:
  0    All enabled servers validated successfully
  1    Config file missing or unreadable
  2    Config file is not valid JSON
  3    One or more enabled servers have issues (warnings printed, non-fatal)
EOF
}

log() {
    if [[ "${opt_quiet}" == true ]]; then
        return
    fi
    echo "${LOG_PREFIX} $*" >&2
}

log_always() {
    echo "${LOG_PREFIX} $*" >&2
}

###############################################################################
# Argument Parsing
###############################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source)
                if [[ -z "${2:-}" ]]; then
                    log_always "ERROR: --source requires a PATH argument"
                    exit 1
                fi
                opt_source="$2"
                shift 2
                ;;
            --quiet)
                opt_quiet=true
                shift
                ;;
            --json)
                opt_json=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log_always "ERROR: Unknown option: $1"
                usage >&2
                exit 1
                ;;
        esac
    done
}

###############################################################################
# Resolve config path (supports absolute and relative paths, with fallback)
###############################################################################

resolve_config_path() {
    local source_path="${opt_source:-${DEFAULT_SOURCE}}"

    # Convert relative path to absolute
    if [[ "${source_path}" != /* ]]; then
        source_path="$(pwd)/${source_path}"
    fi

    if [[ -r "${source_path}" ]]; then
        echo "${source_path}"
        return 0
    fi

    # Try fallback only if using default source (user didn't specify --source)
    if [[ -z "${opt_source}" && -r "${FALLBACK_SOURCE}" ]]; then
        echo "${FALLBACK_SOURCE}"
        return 0
    fi

    # If user specified a path that doesn't exist, report it
    log_always "ERROR: Config file not found or unreadable: ${source_path}"
    if [[ -z "${opt_source}" ]]; then
        log_always "  Also checked fallback: ${FALLBACK_SOURCE}"
    fi
    return 1
}

###############################################################################
# Check Node.js availability
###############################################################################

check_node() {
    local node_version

    if ! command -v node >/dev/null 2>&1; then
        log_always "  node: NOT FOUND (ERROR)"
        if [[ "${opt_json}" == true ]]; then
            echo "null"
        fi
        return 1
    fi

    node_version="$(node --version 2>/dev/null)"
    log "  node: ${node_version} (OK)"
    echo "${node_version}"
}

###############################################################################
# Extract env var names from ${VAR_NAME} patterns in env object values
###############################################################################

extract_env_var_names() {
    local env_json="$1"

    if [[ -z "${env_json}" || "${env_json}" == "null" ]]; then
        return
    fi

    # Extract values that match ${...} pattern and pull out the var name
    echo "${env_json}" | jq -r 'to_entries[] | .value | select(test("\\$\\{[^}]+\\}")) | capture("\\$\\{(?<name>[^}]+)\\}") | .name'
}

###############################################################################
# Check a single env var exists (by name only, never echo value)
###############################################################################

check_env_var_set() {
    local var_name="$1"
    # Use indirect expansion to check if the variable is set and non-empty
    [[ -n "${!var_name:-}" ]]
}

###############################################################################
# Check for hardcoded credentials in env values
# Returns 0 if all env values use ${VAR_NAME} pattern or are non-sensitive
# Returns 1 if hardcoded credential-like values are found
###############################################################################

check_hardcoded_credentials() {
    local server_name="$1"
    local env_json="$2"

    if [[ -z "${env_json}" || "${env_json}" == "null" ]]; then
        return 0
    fi

    # Check each env value: if the key name suggests a credential (TOKEN, KEY, SECRET, PASSWORD)
    # and the value is NOT a ${VAR_NAME} reference, flag it as hardcoded
    local hardcoded_keys
    hardcoded_keys="$(echo "${env_json}" | jq -r '
        to_entries[]
        | select(
            (.key | test("TOKEN|KEY|SECRET|PASSWORD|CREDENTIAL"; "i"))
            and (.value | test("^\\$\\{[^}]+\\}$") | not)
        )
        | .key
    ')"

    if [[ -n "${hardcoded_keys}" ]]; then
        local key_list
        key_list="$(echo "${hardcoded_keys}" | tr '\n' ', ' | sed 's/,$//')"
        log_always "  ${server_name}: ERROR - hardcoded credentials detected in: ${key_list}"
        log_always "    Use environment variable references (\${VAR_NAME}) instead of inline values"
        return 1
    fi

    return 0
}

###############################################################################
# Validate a single server entry
###############################################################################

validate_server() {
    local server_name="$1"
    local server_json="$2"

    local enabled
    local cmd
    local env_json
    local status
    local reason=""
    local binary_display

    # Check if server is disabled
    enabled="$(echo "${server_json}" | jq -r 'if has("enabled") then .enabled else true end')"
    if [[ "${enabled}" == "false" ]]; then
        count_skip=$((count_skip + 1))
        log "  ${server_name}: SKIP (disabled)"
        if [[ "${opt_json}" == true ]]; then
            json_servers="${json_servers}$(printf '"%s": {"status": "skip", "reason": "disabled"},' "${server_name}")"
        fi
        return 0
    fi

    count_enabled=$((count_enabled + 1))

    # Check for hardcoded credentials first (security check)
    env_json="$(echo "${server_json}" | jq -c '.env // empty')"
    if ! check_hardcoded_credentials "${server_name}" "${env_json}"; then
        count_error=$((count_error + 1))
        if [[ "${opt_json}" == true ]]; then
            json_servers="${json_servers}$(printf '"%s": {"status": "error", "reason": "hardcoded credentials"},' "${server_name}")"
        fi
        return 1
    fi

    # Get the command binary
    cmd="$(echo "${server_json}" | jq -r '.command // empty')"
    if [[ -z "${cmd}" ]]; then
        count_error=$((count_error + 1))
        log_always "  ${server_name}: ERROR (no command specified)"
        if [[ "${opt_json}" == true ]]; then
            json_servers="${json_servers}$(printf '"%s": {"status": "error", "reason": "no command specified"},' "${server_name}")"
        fi
        return 1
    fi

    # Check if command binary is on PATH
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        count_error=$((count_error + 1))
        log_always "  ${server_name}: ERROR (${cmd} not found)"
        if [[ "${opt_json}" == true ]]; then
            json_servers="${json_servers}$(printf '"%s": {"status": "error", "binary": "%s", "reason": "%s not found"},' "${server_name}" "${cmd}" "${cmd}")"
        fi
        return 1
    fi

    binary_display="${cmd}"

    # Check env vars with ${VAR_NAME} pattern
    env_json="$(echo "${server_json}" | jq -r '.env // empty')"
    local missing_vars=()

    if [[ -n "${env_json}" && "${env_json}" != "null" ]]; then
        local var_names
        var_names="$(extract_env_var_names "${env_json}")"

        while IFS= read -r var_name; do
            [[ -z "${var_name}" ]] && continue
            if ! check_env_var_set "${var_name}"; then
                missing_vars+=("${var_name}")
            fi
        done <<< "${var_names}"
    fi

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        count_warn=$((count_warn + 1))
        local missing_list
        missing_list="$(IFS=', '; echo "${missing_vars[*]}")"
        reason="${missing_list} not set"

        if [[ "${opt_quiet}" != true ]]; then
            log_always "  ${server_name}: WARN (${reason})"
        else
            log_always "  ${server_name}: WARN (${reason})"
        fi

        if [[ "${opt_json}" == true ]]; then
            json_servers="${json_servers}$(printf '"%s": {"status": "warn", "binary": "%s", "reason": "%s"},' "${server_name}" "${binary_display}" "${reason}")"
        fi
        return 0
    fi

    # Memory server: check volume directory writable (T040)
    if [[ "${server_name}" == "memory" && -n "${env_json}" && "${env_json}" != "null" ]]; then
        local memory_path
        memory_path="$(echo "${env_json}" | jq -r '.MEMORY_FILE_PATH // empty')"
        if [[ -n "${memory_path}" ]]; then
            local memory_dir
            memory_dir="$(dirname "${memory_path}")"
            if [[ -d "${memory_dir}" && ! -w "${memory_dir}" ]]; then
                count_warn=$((count_warn + 1))
                reason="volume directory not writable: ${memory_dir}"
                log_always "  ${server_name}: WARN (${reason})"
                if [[ "${opt_json}" == true ]]; then
                    json_servers="${json_servers}$(printf '"%s": {"status": "warn", "binary": "%s", "reason": "%s"},' "${server_name}" "${binary_display}" "${reason}")"
                fi
                return 0
            fi
        fi
    fi

    # All checks passed
    count_ok=$((count_ok + 1))
    log "  ${server_name}: OK (${binary_display} found)"
    if [[ "${opt_json}" == true ]]; then
        json_servers="${json_servers}$(printf '"%s": {"status": "ok", "binary": "%s"},' "${server_name}" "${binary_display}")"
    fi
    return 0
}

###############################################################################
# Main
###############################################################################

main() {
    parse_args "$@"

    log "=== MCP Server Validation ==="

    # Check Node.js
    local node_version
    node_version="$(check_node)" || true

    # Resolve config path
    local config_path
    if ! config_path="$(resolve_config_path)"; then
        if [[ "${opt_json}" == true ]]; then
            printf '{"error": "config file missing or unreadable", "config_path": "%s"}\n' "${opt_source:-${DEFAULT_SOURCE}}"
        fi
        exit 1
    fi

    # Validate JSON
    if ! jq empty "${config_path}" 2>/dev/null; then
        log_always "ERROR: Config file is not valid JSON: ${config_path}"
        if [[ "${opt_json}" == true ]]; then
            printf '{"error": "config file is not valid JSON", "config_path": "%s"}\n' "${config_path}"
        fi
        exit 2
    fi

    # Iterate over servers
    local server_names
    server_names="$(jq -r '.mcpServers | keys[]' "${config_path}")"

    local has_error=false

    while IFS= read -r server_name; do
        [[ -z "${server_name}" ]] && continue
        local server_json
        server_json="$(jq -c ".mcpServers[\"${server_name}\"]" "${config_path}")"
        validate_server "${server_name}" "${server_json}" || has_error=true
    done <<< "${server_names}"

    # Summary
    log "=== Validation Complete (${count_enabled} enabled, ${count_ok} OK, ${count_warn} WARN, ${count_error} ERROR, ${count_skip} SKIP) ==="

    # JSON output
    if [[ "${opt_json}" == true ]]; then
        # Remove trailing comma from json_servers
        json_servers="${json_servers%,}"

        local json_node_version
        if [[ -n "${node_version}" ]]; then
            json_node_version="\"${node_version}\""
        else
            json_node_version="null"
        fi

        printf '{
  "node_version": %s,
  "config_path": "%s",
  "servers": {%s},
  "summary": {"enabled": %d, "ok": %d, "warn": %d, "error": %d, "skip": %d}
}\n' "${json_node_version}" "${config_path}" "${json_servers}" \
     "${count_enabled}" "${count_ok}" "${count_warn}" "${count_error}" "${count_skip}"
    fi

    # Determine exit code
    if [[ "${count_error}" -gt 0 ]]; then
        exit 3
    fi

    if [[ "${count_warn}" -gt 0 ]]; then
        exit 3
    fi

    exit 0
}

main "$@"
