#!/bin/bash
# secrets-load.sh - Runtime secret loader for container entrypoint
#
# Loads decrypted secrets from ~/.secrets.env as environment variables
# using safe line-by-line parsing (no source/eval — FR-004/005/006).
#
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
#   1 - Secrets file exists but is malformed or has unsafe permissions
#   2 - Secrets file exists but is unreadable

# Determine if we're being sourced or executed
_SECRETS_LOAD_SOURCED="${_SECRETS_LOAD_SOURCED:-false}"
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
    # shellcheck source=scripts/secrets-common.sh
    source "${_SECRETS_LOAD_SCRIPT_DIR}/secrets-common.sh"
else
    # Minimal fallback if common.sh not available (e.g., in container without full scripts/)
    _log_msg() {
        local level="$1"
        local component="$2"
        shift 2
        printf '[%s] %s: %s\n' "${level}" "${component}" "$*" >&2
    }
    log_info() { echo "[secrets-load] $*"; }
    log_warn() { echo "[secrets-load] WARNING: $*" >&2; }
    log_error() { echo "[secrets-load] ERROR: $*" >&2; }
    SECRETS_DEFAULT_FILE="${HOME}/.secrets.env"
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
    1 - Secrets file exists but is malformed or has unsafe permissions
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
# Argument Parsing
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
                    _log_msg ERROR secrets "--secrets-file requires a path argument"
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
                _log_msg ERROR secrets "Unknown option: $1"
                _log_msg ERROR secrets "Use --help for usage information"
                return 1
                ;;
        esac
    done
}

# =============================================================================
# Core: Safe Secrets Loader (FR-004/005/006/014/017)
# =============================================================================

# Check file permissions are secure (not world-readable, not group-writable)
# Returns: 0 if permissions are acceptable, 1 if not
_secrets_check_permissions() {
    local file="$1"
    local perms

    # Get octal permissions (macOS vs Linux stat syntax)
    if stat -f '%Lp' "$file" &>/dev/null; then
        # macOS: stat -f '%Lp' gives octal like "600"
        perms="$(stat -f '%Lp' "$file")"
    else
        # Linux: stat -c '%a' gives octal like "600"
        perms="$(stat -c '%a' "$file")"
    fi

    # Check world-readable (other-read bit): last digit includes 4
    local other_bits="${perms: -1}"
    if (( other_bits & 4 )); then
        _log_msg ERROR secrets "File is world-readable (mode ${perms}): $file"
        return 1
    fi

    # Check group-writable (group-write bit): middle digit includes 2
    local group_bits
    if [[ "${#perms}" -eq 3 ]]; then
        group_bits="${perms:1:1}"
    elif [[ "${#perms}" -ge 4 ]]; then
        group_bits="${perms:2:1}"
    else
        group_bits="0"
    fi
    if (( group_bits & 2 )); then
        _log_msg ERROR secrets "File is group-writable (mode ${perms}): $file"
        return 1
    fi

    return 0
}

# Safe line-by-line secrets loader (FR-004/005/006)
# Parses KEY=VALUE pairs without using source/eval.
# Validates keys, rejects command substitution patterns, checks permissions.
#
# Usage: _secrets_load_safe "/path/to/secrets.env"
# Returns: 0 on success, 1 on permission/fatal error
_secrets_load_safe() {
    local file="$1"
    local loaded=0
    local warnings=0

    # Key validation regex: uppercase letters, digits, or underscores
    local key_pattern='^[A-Z_][A-Z0-9_]*$'

    # Step 1: Check file permissions (before any parsing)
    if ! _secrets_check_permissions "$file"; then
        return 1
    fi

    # Step 2: Parse line by line using safe read (no source/eval)
    while IFS= read -r line || [[ -n "$line" ]]; do

        # Skip blank lines
        [[ -z "$line" ]] && continue

        # Skip whitespace-only lines
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Skip comment lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Split on first = only using parameter expansion
        local key="${line%%=*}"
        local value="${line#*=}"

        # If there was no = in the line, key == line
        if [[ "$key" == "$line" ]]; then
            _log_msg WARN secrets "Line has no '=' delimiter, skipping"
            warnings=$((warnings + 1))
            continue
        fi

        # Handle empty key
        if [[ -z "$key" || "$key" =~ ^[[:space:]]*$ ]]; then
            _log_msg WARN secrets "Empty key name, skipping"
            warnings=$((warnings + 1))
            continue
        fi

        # Trim whitespace from key
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"

        # Validate key against pattern
        if [[ ! "$key" =~ $key_pattern ]]; then
            _log_msg WARN secrets "Invalid key '${key}' (must match ${key_pattern}), skipping"
            warnings=$((warnings + 1))
            continue
        fi

        # Step 3: Check value for dangerous patterns
        # Reject $( ... ) command substitution
        if [[ "$value" == *'$('* ]]; then
            _log_msg WARN secrets "Value for '${key}' contains command substitution \$(), skipping"
            warnings=$((warnings + 1))
            continue
        fi

        # Reject ${ ... } variable expansion
        if [[ "$value" == *'${'* ]]; then
            _log_msg WARN secrets "Value for '${key}' contains variable expansion \${}, skipping"
            warnings=$((warnings + 1))
            continue
        fi

        # Reject backtick command substitution
        if [[ "$value" == *'`'* ]]; then
            _log_msg WARN secrets "Value for '${key}' contains backtick substitution, skipping"
            warnings=$((warnings + 1))
            continue
        fi

        # Step 4: Export the validated key=value pair safely (no eval)
        export "${key}=${value}"
        loaded=$((loaded + 1))

    done < "$file"

    if [[ "$_SECRETS_QUIET" == "false" && "$loaded" -gt 0 ]]; then
        _log_msg INFO secrets "Loaded ${loaded} environment variable(s)"
    fi

    return 0
}

# =============================================================================
# Main Logic
# =============================================================================

_secrets_load_main() {
    # Parse arguments if any
    if [[ $# -gt 0 ]]; then
        _secrets_load_parse_args "$@" || {
            local rc=$?
            [[ $rc -eq 255 ]] && return 0  # Help was shown
            return $rc
        }
    fi

    # Check if secrets file exists
    if [[ ! -f "$_SECRETS_FILE" ]]; then
        if [[ "$_SECRETS_QUIET" == "false" ]]; then
            _log_msg INFO secrets "No secrets file found at $_SECRETS_FILE (skipping)"
        fi
        return 0
    fi

    # Check if file is readable
    if [[ ! -r "$_SECRETS_FILE" ]]; then
        _log_msg ERROR secrets "Secrets file not readable: $_SECRETS_FILE"
        return 2
    fi

    if [[ "$_SECRETS_QUIET" == "false" ]]; then
        _log_msg INFO secrets "Loading secrets from $_SECRETS_FILE"
    fi

    # Check-only mode
    if [[ "$_SECRETS_CHECK_ONLY" == "true" ]]; then
        if _secrets_load_safe "$_SECRETS_FILE"; then
            _log_msg INFO secrets "Secrets file is valid"
            return 0
        else
            return 1
        fi
    fi

    # Load the secrets using safe parser
    _secrets_load_safe "$_SECRETS_FILE" || return 1

    return 0
}

# =============================================================================
# Execution
# =============================================================================

# Only run main automatically if NOT being sourced for testing
# When _SECRETS_LOAD_SOURCED is set before sourcing (test mode), skip auto-exec
if [[ "$_SECRETS_LOAD_SOURCED" == "false" ]]; then
    _secrets_load_main "$@"
    exit $?
fi
