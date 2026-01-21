#!/bin/bash
# secrets-load.sh - Runtime secret loader for container entrypoint
#
# Loads decrypted secrets from ~/.secrets.env as environment variables.
# Designed to be sourced by the container entrypoint before executing
# the main command.
#
# Usage (in entrypoint.sh):
#   source /usr/local/bin/secrets-load.sh
#   exec "$@"
#
# Usage (standalone):
#   ./scripts/secrets-load.sh [OPTIONS]
#
# Options:
#   --check          Validate secrets file without loading
#   --secrets-file   Custom secrets file location (default: ~/.secrets.env)
#   --quiet          Suppress informational output
#   --help           Show this help message
#
# Exit codes:
#   0 - Secrets loaded successfully (or file doesn't exist)
#   1 - Secrets file exists but is malformed
#   2 - Secrets file exists but is unreadable

# Determine if we're being sourced or executed
_SECRETS_LOAD_SOURCED=false
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    _SECRETS_LOAD_SOURCED=true
fi

# Only set strict mode if executed (not sourced)
if [[ "$_SECRETS_LOAD_SOURCED" == "false" ]]; then
    set -euo pipefail
fi

# Source shared utilities
_SECRETS_LOAD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_SECRETS_LOAD_SCRIPT_DIR}/secrets-common.sh" ]]; then
    source "${_SECRETS_LOAD_SCRIPT_DIR}/secrets-common.sh"
else
    # Minimal fallback if common.sh not available (e.g., in container without full scripts/)
    log_info() { echo "[secrets-load] $*"; }
    log_warn() { echo "[secrets-load] WARNING: $*" >&2; }
    log_error() { echo "[secrets-load] ERROR: $*" >&2; }
    SECRETS_DEFAULT_FILE="${HOME}/.secrets.env"
    SECRETS_NAME_PATTERN='^[A-Z][A-Z0-9_]*$'
fi

# =============================================================================
# Configuration
# =============================================================================

_SECRETS_FILE="${SECRETS_DEFAULT_FILE}"
_SECRETS_QUIET=false
_SECRETS_CHECK_ONLY=false

# =============================================================================
# Help and Usage
# =============================================================================

_secrets_load_show_help() {
    cat << 'EOF'
secrets-load.sh - Runtime secret loader for container entrypoint

USAGE:
    # Source in entrypoint (recommended)
    source /usr/local/bin/secrets-load.sh

    # Standalone execution
    ./scripts/secrets-load.sh [OPTIONS]

OPTIONS:
    --check              Validate secrets file without loading
    --secrets-file PATH  Custom secrets file location (default: ~/.secrets.env)
    --quiet              Suppress informational output
    --help               Show this help message

EXIT CODES:
    0 - Secrets loaded successfully (or file doesn't exist)
    1 - Secrets file exists but is malformed
    2 - Secrets file exists but is unreadable

EXAMPLES:
    # Load secrets in entrypoint
    source /usr/local/bin/secrets-load.sh

    # Validate secrets file
    ./scripts/secrets-load.sh --check

    # Load from custom location
    ./scripts/secrets-load.sh --secrets-file /etc/secrets/app.env
EOF
}

# =============================================================================
# Argument Parsing (T021, T022, T023)
# =============================================================================

_secrets_load_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                _secrets_load_show_help
                return 255  # Special code to indicate help was shown
                ;;
            --check)
                _SECRETS_CHECK_ONLY=true
                shift
                ;;
            --secrets-file)
                if [[ -z "${2:-}" ]]; then
                    log_error "--secrets-file requires a path argument"
                    return 1
                fi
                _SECRETS_FILE="$2"
                shift 2
                ;;
            --quiet|-q)
                _SECRETS_QUIET=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                log_error "Use --help for usage information"
                return 1
                ;;
        esac
    done
}

# =============================================================================
# Core Functions (T017-T024)
# =============================================================================

# Validate a single line and return error info
# Sets global _SECRETS_VALIDATE_ERROR on failure
_secrets_validate_line() {
    local line="$1"
    local line_num="$2"
    _SECRETS_VALIDATE_ERROR=""

    # Empty lines are valid
    [[ -z "$line" ]] && return 0

    # Comments are valid
    [[ "$line" =~ ^[[:space:]]*# ]] && return 0

    # Whitespace-only lines are valid
    [[ "$line" =~ ^[[:space:]]*$ ]] && return 0

    # Must contain equals sign
    if [[ ! "$line" =~ = ]]; then
        _SECRETS_VALIDATE_ERROR="Line ${line_num}: Missing '=' - not a valid KEY=value format"
        return 1
    fi

    # Extract and validate key
    local key="${line%%=*}"
    key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ -z "$key" ]]; then
        _SECRETS_VALIDATE_ERROR="Line ${line_num}: Empty key name"
        return 1
    fi

    if [[ ! "$key" =~ $SECRETS_NAME_PATTERN ]]; then
        _SECRETS_VALIDATE_ERROR="Line ${line_num}: Invalid key '${key}' - must match ${SECRETS_NAME_PATTERN}"
        return 1
    fi

    return 0
}

# Validate the secrets file (T018, T019, T024)
_secrets_validate_file() {
    local file="$1"
    local line_num=0
    local var_count=0
    local errors=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))

        if ! _secrets_validate_line "$line" "$line_num"; then
            log_error "$_SECRETS_VALIDATE_ERROR"
            log_error "Invalid line: \"$line\""
            ((errors++))
        elif [[ "$line" =~ = ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            ((var_count++))
        fi
    done < "$file"

    if [[ $errors -gt 0 ]]; then
        log_error "Found $errors validation error(s) in $file"
        log_error "Fix the file and restart the container"
        return 1
    fi

    echo "$var_count"
    return 0
}

# Load secrets as environment variables (T020)
_secrets_load() {
    local file="$1"
    local var_count

    # Validate first
    var_count=$(_secrets_validate_file "$file") || return 1

    # Load the variables using set -a (export all)
    set -a
    # shellcheck disable=SC1090
    source "$file"
    set +a

    if [[ "$_SECRETS_QUIET" == "false" ]]; then
        log_info "Loaded $var_count environment variable(s)"
    fi

    return 0
}

# Main logic
_secrets_load_main() {
    # Parse arguments if any
    if [[ $# -gt 0 ]]; then
        _secrets_load_parse_args "$@" || {
            local rc=$?
            [[ $rc -eq 255 ]] && return 0  # Help was shown
            return $rc
        }
    fi

    # Check if secrets file exists (T018)
    if [[ ! -f "$_SECRETS_FILE" ]]; then
        if [[ "$_SECRETS_QUIET" == "false" ]]; then
            log_info "No secrets file found at $_SECRETS_FILE (skipping)"
        fi
        return 0
    fi

    # Check if file is readable
    if [[ ! -r "$_SECRETS_FILE" ]]; then
        log_error "Secrets file not readable: $_SECRETS_FILE"
        return 2
    fi

    if [[ "$_SECRETS_QUIET" == "false" ]]; then
        log_info "Loading secrets from $_SECRETS_FILE"
    fi

    # Check-only mode (T021)
    if [[ "$_SECRETS_CHECK_ONLY" == "true" ]]; then
        local var_count
        var_count=$(_secrets_validate_file "$_SECRETS_FILE") || return 1
        log_info "Secrets file is valid ($var_count variable(s) defined)"
        return 0
    fi

    # Load the secrets
    _secrets_load "$_SECRETS_FILE" || return 1

    return 0
}

# =============================================================================
# Execution
# =============================================================================

# Always run main when sourced or executed
# This allows: source secrets-load.sh --quiet
_secrets_load_main "$@"
_SECRETS_LOAD_RC=$?

# If executed (not sourced), exit with the return code
if [[ "$_SECRETS_LOAD_SOURCED" == "false" ]]; then
    exit $_SECRETS_LOAD_RC
fi

# If sourced and there was an error, we can't exit (would exit the parent shell)
# Instead, the sourcing script should check the return value
# Return the code for the sourcing script to handle
return $_SECRETS_LOAD_RC 2>/dev/null || true
