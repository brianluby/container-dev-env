#!/bin/bash
# secrets-common.sh - Shared utilities for secret injection scripts
#
# This file should be sourced by other scripts, not executed directly.
# Usage: source "$(dirname "$0")/secrets-common.sh"
#
# Provides:
#   - Logging functions (info, warn, error)
#   - Dependency check functions
#   - .env file validation

set -euo pipefail

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script should be sourced, not executed directly." >&2
    echo "Usage: source \"$(dirname \"\$0\")/secrets-common.sh\"" >&2
    exit 1
fi

# =============================================================================
# Configuration
# =============================================================================

# Default paths
SECRETS_DEFAULT_KEY_PATH="${HOME}/.config/chezmoi/key.txt"
SECRETS_DEFAULT_FILE="${HOME}/.secrets.env"
SECRETS_CHEZMOI_SOURCE="${HOME}/.local/share/chezmoi"
SECRETS_ENCRYPTED_FILE="private_dot_secrets.env.age"

# Colors (if terminal supports them)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    YELLOW=''
    GREEN=''
    BLUE=''
    NC=''
fi

# =============================================================================
# Logging Functions (T005)
# =============================================================================

# Get the script name for log prefix
_get_log_prefix() {
    local script_name
    script_name=$(basename "${BASH_SOURCE[-1]}" .sh)
    echo "[${script_name}]"
}

# Log informational message to stdout
# Usage: log_info "message"
log_info() {
    local prefix
    prefix=$(_get_log_prefix)
    echo -e "${BLUE}${prefix}${NC} $*"
}

# Log warning message to stderr
# Usage: log_warn "message"
log_warn() {
    local prefix
    prefix=$(_get_log_prefix)
    echo -e "${YELLOW}${prefix} WARNING:${NC} $*" >&2
}

# Log error message to stderr
# Usage: log_error "message"
log_error() {
    local prefix
    prefix=$(_get_log_prefix)
    echo -e "${RED}${prefix} ERROR:${NC} $*" >&2
}

# Log success message to stdout
# Usage: log_success "message"
log_success() {
    local prefix
    prefix=$(_get_log_prefix)
    echo -e "${GREEN}${prefix}${NC} $*"
}

# =============================================================================
# Dependency Check Functions (T006)
# =============================================================================

# Check if a command exists
# Usage: command_exists "age"
# Returns: 0 if exists, 1 if not
command_exists() {
    command -v "$1" &>/dev/null
}

# Get version of a command (first line of --version output)
# Usage: get_version "age"
get_version() {
    local cmd="$1"
    if command_exists "$cmd"; then
        "$cmd" --version 2>/dev/null | head -n1
    else
        echo "not installed"
    fi
}

# Check if age is installed
# Usage: check_age
# Returns: 0 if installed, 2 if not (exit code per contract)
check_age() {
    if ! command_exists age; then
        log_error "age is required but not installed."
        log_error "Install with: brew install age (macOS) or apt install age (Debian/Ubuntu)"
        return 2
    fi
    return 0
}

# Check if chezmoi is installed
# Usage: check_chezmoi
# Returns: 0 if installed, 2 if not (exit code per contract)
check_chezmoi() {
    if ! command_exists chezmoi; then
        log_error "chezmoi is required but not installed."
        log_error "Install with: brew install chezmoi (macOS) or sh -c \"\$(curl -fsLS get.chezmoi.io)\""
        return 2
    fi
    return 0
}

# Check all required dependencies
# Usage: check_dependencies
# Returns: 0 if all installed, 2 if any missing
check_dependencies() {
    local missing=0

    if ! check_age; then
        missing=1
    fi

    if ! check_chezmoi; then
        missing=1
    fi

    if [[ $missing -eq 1 ]]; then
        return 2
    fi

    return 0
}

# Print dependency versions (for setup wizard)
# Usage: print_dependency_versions
print_dependency_versions() {
    local age_version chezmoi_version

    if command_exists age; then
        age_version=$(get_version age)
        log_success "age ${age_version} found"
    else
        log_error "age not found"
    fi

    if command_exists chezmoi; then
        chezmoi_version=$(get_version chezmoi)
        log_success "chezmoi ${chezmoi_version} found"
    else
        log_error "chezmoi not found"
    fi
}

# =============================================================================
# .env File Validation (T007)
# =============================================================================

# Regex pattern for valid secret names
# Must start with uppercase letter, followed by uppercase letters, digits, or underscores
SECRETS_NAME_PATTERN='^[A-Z][A-Z0-9_]*$'

# Validate a single line from an .env file
# Usage: validate_env_line "line" line_number
# Returns: 0 if valid, 1 if invalid (sets VALIDATE_ERROR message)
validate_env_line() {
    local line="$1"
    local line_num="${2:-0}"
    VALIDATE_ERROR=""

    # Empty lines are valid
    if [[ -z "$line" ]]; then
        return 0
    fi

    # Comments are valid (lines starting with #)
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
        return 0
    fi

    # Lines with only whitespace are valid
    if [[ "$line" =~ ^[[:space:]]*$ ]]; then
        return 0
    fi

    # Must contain an equals sign
    if [[ ! "$line" =~ = ]]; then
        VALIDATE_ERROR="Line ${line_num}: Missing '=' - not a valid KEY=value format"
        return 1
    fi

    # Extract the key (everything before the first =)
    local key="${line%%=*}"

    # Remove leading/trailing whitespace from key
    key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Key cannot be empty
    if [[ -z "$key" ]]; then
        VALIDATE_ERROR="Line ${line_num}: Empty key name"
        return 1
    fi

    # Key must match the pattern
    if [[ ! "$key" =~ $SECRETS_NAME_PATTERN ]]; then
        VALIDATE_ERROR="Line ${line_num}: Invalid key '${key}' - must match ${SECRETS_NAME_PATTERN}"
        return 1
    fi

    return 0
}

# Validate an entire .env file
# Usage: validate_env_file "/path/to/file"
# Returns: 0 if valid, 1 if invalid
# Outputs: Error messages to stderr, count of variables to stdout
validate_env_file() {
    local file="$1"
    local line_num=0
    local var_count=0
    local errors=0

    # Check file exists
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    # Check file is readable
    if [[ ! -r "$file" ]]; then
        log_error "File not readable: $file"
        return 2
    fi

    # Validate each line
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))

        if ! validate_env_line "$line" "$line_num"; then
            log_error "$VALIDATE_ERROR"

            # Avoid logging secrets: do not print the full line, only metadata and (optionally) the key name.
            local invalid_key=""
            if [[ "$line" =~ = ]]; then
                # Extract the part before the first '=' as the candidate key, trimming leading/trailing whitespace.
                invalid_key="${line%%=*}"
                # Trim leading whitespace
                invalid_key="${invalid_key#"${invalid_key%%[![:space:]]*}"}"
                # Trim trailing whitespace
                invalid_key="${invalid_key%"${invalid_key##*[![:space:]]}"}"
            fi

            if [[ -n "$invalid_key" ]]; then
                log_error "Invalid line in $file at line $line_num (key: \"$invalid_key\")"
            else
                log_error "Invalid line in $file at line $line_num"
            fi
            ((errors++))
        elif [[ "$line" =~ = ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            # Count non-comment lines with = as variables
            ((var_count++))
        fi
    done < "$file"

    if [[ $errors -gt 0 ]]; then
        log_error "Found $errors validation error(s) in $file"
        log_error "Fix the file and try again"
        return 1
    fi

    echo "$var_count"
    return 0
}

# Extract just the key names from an .env file (for list command)
# Usage: get_env_keys "/path/to/file"
# Outputs: One key per line
get_env_keys() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines, comments, whitespace-only
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]] || [[ "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        fi

        # Extract and print the key
        if [[ "$line" =~ = ]]; then
            local key="${line%%=*}"
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            echo "$key"
        fi
    done < "$file"
}

# =============================================================================
# Utility Functions
# =============================================================================

# Check if secrets have been configured (key exists)
# Usage: secrets_configured
# Returns: 0 if configured, 1 if not
secrets_configured() {
    local key_path="${1:-$SECRETS_DEFAULT_KEY_PATH}"
    [[ -f "$key_path" ]]
}

# Check if encrypted secrets file exists in chezmoi source
# Usage: encrypted_secrets_exist
# Returns: 0 if exists, 1 if not
encrypted_secrets_exist() {
    [[ -f "${SECRETS_CHEZMOI_SOURCE}/${SECRETS_ENCRYPTED_FILE}" ]]
}

# Get the public key from an age identity file
# Usage: get_age_recipient "/path/to/key.txt"
# Outputs: The public key (age1...)
get_age_recipient() {
    local key_file="$1"

    if [[ ! -f "$key_file" ]]; then
        return 1
    fi

    # Extract the public key from the comment line
    grep "^# public key:" "$key_file" | sed 's/^# public key: //'
}
