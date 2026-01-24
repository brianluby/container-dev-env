#!/bin/bash
# secrets-edit.sh - Helper for editing encrypted secrets
#
# Provides a streamlined workflow for adding, updating, or removing
# secrets. Wraps chezmoi edit with validation.
#
# Usage: ./scripts/secrets-edit.sh [COMMAND] [OPTIONS]
#
# Commands:
#   edit              Open secrets in $EDITOR (default)
#   add KEY=VALUE     Add a single secret
#   remove KEY        Remove a secret by name
#   list              List secret names (not values)
#   validate          Check secrets file format
#
# Options:
#   --help            Show this help message
#
# Exit codes:
#   0 - Operation completed successfully
#   1 - General error
#   2 - Secrets not configured (run setup first)
#   3 - Validation failed
#   4 - Key not found (for remove)

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/secrets-common.sh"

# =============================================================================
# Configuration
# =============================================================================

SECRETS_FILE="${SECRETS_DEFAULT_FILE}"

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << 'EOF'
secrets-edit.sh - Helper for editing encrypted secrets

USAGE:
    ./scripts/secrets-edit.sh [COMMAND] [OPTIONS]

COMMANDS:
    edit              Open secrets in $EDITOR (default)
    add KEY=VALUE     Add a single secret
    remove KEY        Remove a secret by name
    list              List secret names (not values)
    validate          Check secrets file format

OPTIONS:
    --help            Show this help message

EXIT CODES:
    0 - Operation completed successfully
    1 - General error
    2 - Secrets not configured (run setup first)
    3 - Validation failed
    4 - Key not found (for remove)

EXAMPLES:
    # Open secrets in editor
    ./scripts/secrets-edit.sh
    ./scripts/secrets-edit.sh edit

    # Add a new secret
    ./scripts/secrets-edit.sh add GITHUB_TOKEN=ghp_xxxx

    # Remove a secret
    ./scripts/secrets-edit.sh remove OLD_API_KEY

    # List all secret names
    ./scripts/secrets-edit.sh list

    # Validate secrets file
    ./scripts/secrets-edit.sh validate

NOTES:
    - The 'add' command value is visible in shell history
      For sensitive values, use 'edit' instead
    - 'list' never shows values, only names
EOF
}

# =============================================================================
# Utility Functions
# =============================================================================

# Check if secrets are configured (T032)
ensure_configured() {
    if ! secrets_configured; then
        log_error "Secrets not configured. Run secrets-setup.sh first."
        exit 2
    fi

    if ! encrypted_secrets_exist; then
        log_error "No encrypted secrets file found."
        log_error "Run secrets-setup.sh to create one."
        exit 2
    fi
}

# Get the decrypted secrets content via chezmoi
get_decrypted_content() {
    # Use chezmoi cat to get decrypted content without writing to disk
    chezmoi cat "${SECRETS_FILE}" 2>/dev/null || echo ""
}

# Write content back through chezmoi (re-encrypts automatically)
write_encrypted_content() {
    local content="$1"
    local temp_file
    temp_file=$(mktemp)
    
    # Set up trap to ensure cleanup even on unexpected exit
    # This is critical because temp_file contains unencrypted secrets
    trap "rm -f '$temp_file'" EXIT INT TERM ERR

    # Use printf to avoid echo's interpretation of backslashes (FR-011)
    printf '%s\n' "$content" > "$temp_file"

    # Remove existing and re-add with encryption
    local source_file="${SECRETS_CHEZMOI_SOURCE}/${SECRETS_ENCRYPTED_FILE}"
    if [[ -f "$source_file" ]]; then
        rm -f "$source_file"
    fi

    # Create target temporarily
    cp "$temp_file" "${SECRETS_FILE}"
    chezmoi add --encrypt "${SECRETS_FILE}"
    rm -f "$temp_file" "${SECRETS_FILE}"
    
    # Clear the trap since we've cleaned up successfully
    trap - EXIT INT TERM ERR
}

# =============================================================================
# Commands
# =============================================================================

# Edit command (T027)
cmd_edit() {
    ensure_configured

    log_info "Opening secrets in editor..."

    # chezmoi edit decrypts, opens in $EDITOR, and re-encrypts on save
    if chezmoi edit "${SECRETS_FILE}"; then
        log_success "Secrets updated"
        log_info "Restart container to apply changes"
    else
        log_error "Edit failed or was cancelled"
        exit 1
    fi
}

# Add command (T028)
cmd_add() {
    local input="$1"
    ensure_configured

    # Validate input format
    if [[ ! "$input" =~ = ]]; then
        log_error "Invalid format. Use: add KEY=VALUE"
        exit 1
    fi

    local key="${input%%=*}"
    local value="${input#*=}"

    # Validate key format
    if [[ ! "$key" =~ $SECRETS_NAME_PATTERN ]]; then
        log_error "Invalid key '${key}'"
        log_error "Key names must match: ${SECRETS_NAME_PATTERN}"
        exit 3
    fi

    # Get current content
    local content
    content=$(get_decrypted_content)

    # Check if key already exists (use printf to avoid echo backslash issues — FR-011)
    if printf '%s\n' "$content" | grep -q "^${key}="; then
        # Update existing key — use awk to avoid sed delimiter conflicts (FR-011)
        log_info "Updating existing key: $key"
        content=$(printf '%s\n' "$content" | awk -v key="${key}" -v val="${value}" '
            BEGIN { FS=""; OFS="" }
            index($0, key "=") == 1 { print key "=" val; next }
            { print }
        ')
    else
        # Add new key
        log_info "Adding new key: $key"
        if [[ -n "$content" ]]; then
            content="${content}"$'\n'"${key}=${value}"
        else
            content="${key}=${value}"
        fi
    fi

    # Write back
    write_encrypted_content "$content"

    log_success "Added $key"
    log_info "Restart container to apply changes"
}

# Remove command (T029)
cmd_remove() {
    local key="$1"
    ensure_configured

    # Get current content
    local content
    content=$(get_decrypted_content)

    # Check if key exists (use printf to avoid echo backslash issues — FR-011)
    if ! printf '%s\n' "$content" | grep -q "^${key}="; then
        log_error "Key '$key' not found in secrets file"
        exit 4
    fi

    # Remove the key (use printf to avoid echo backslash issues — FR-011)
    content=$(printf '%s\n' "$content" | grep -v "^${key}=")

    # Write back
    write_encrypted_content "$content"

    log_success "Removed $key"
    log_info "Restart container to apply changes"
}

# List command (T030)
cmd_list() {
    ensure_configured

    local content
    content=$(get_decrypted_content)

    if [[ -z "$content" ]]; then
        log_info "No secrets defined"
        return 0
    fi

    # Extract and print key names only (never values)
    printf '%s\n' "$content" | while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Extract and print key
        if [[ "$line" =~ = ]]; then
            local key="${line%%=*}"
            key=$(printf '%s' "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            printf '%s\n' "$key"
        fi
    done
}

# Validate command (T031)
cmd_validate() {
    ensure_configured

    # Get decrypted content to a temp file for validation
    local temp_file
    temp_file=$(mktemp)
    
    # Set up trap to ensure cleanup even on unexpected exit
    # This is critical because temp_file contains unencrypted secrets
    trap "rm -f '$temp_file'" EXIT INT TERM ERR
    
    get_decrypted_content > "$temp_file"

    local var_count
    if var_count=$(validate_env_file "$temp_file"); then
        log_success "Secrets file is valid ($var_count variable(s) defined)"
        rm -f "$temp_file"
        trap - EXIT INT TERM ERR
        return 0
    else
        rm -f "$temp_file"
        trap - EXIT INT TERM ERR
        exit 3
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    # No arguments = edit command
    if [[ $# -eq 0 ]]; then
        cmd_edit
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        --help|-h)
            show_help
            exit 0
            ;;
        edit)
            cmd_edit
            ;;
        add)
            if [[ $# -eq 0 ]]; then
                log_error "add requires KEY=VALUE argument"
                exit 1
            fi
            cmd_add "$1"
            ;;
        remove)
            if [[ $# -eq 0 ]]; then
                log_error "remove requires KEY argument"
                exit 1
            fi
            cmd_remove "$1"
            ;;
        list)
            cmd_list
            ;;
        validate)
            cmd_validate
            ;;
        *)
            log_error "Unknown command: $command"
            log_error "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
