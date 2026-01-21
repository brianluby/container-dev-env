#!/bin/bash
# secrets-setup.sh - First-time setup wizard for secret injection
#
# Interactive setup wizard for configuring age-encrypted secrets
# with Chezmoi. Guides users through:
#   1. Dependency verification (age, chezmoi)
#   2. Age encryption key generation
#   3. Chezmoi configuration for age
#   4. Initial encrypted secrets template creation
#
# Usage: ./scripts/secrets-setup.sh [OPTIONS]
#
# Options:
#   --non-interactive  Skip prompts, use defaults
#   --key-path PATH    Custom age key location (default: ~/.config/chezmoi/key.txt)
#   --force            Regenerate key even if one exists
#   --help             Show this help message
#
# Exit codes:
#   0 - Setup completed successfully
#   1 - General error
#   2 - Missing dependencies (age, chezmoi)
#   3 - Key already exists (without --force)
#   4 - User cancelled setup

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/secrets-common.sh"

# =============================================================================
# Configuration
# =============================================================================

KEY_PATH="${SECRETS_DEFAULT_KEY_PATH}"
NON_INTERACTIVE=false
FORCE=false

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << 'EOF'
secrets-setup.sh - First-time setup wizard for secret injection

USAGE:
    ./scripts/secrets-setup.sh [OPTIONS]

OPTIONS:
    --non-interactive  Skip prompts, use defaults
    --key-path PATH    Custom age key location (default: ~/.config/chezmoi/key.txt)
    --force            Regenerate key even if one exists (WARNING: invalidates existing encrypted files)
    --help             Show this help message

EXIT CODES:
    0 - Setup completed successfully
    1 - General error
    2 - Missing dependencies (age, chezmoi)
    3 - Key already exists (without --force)
    4 - User cancelled setup

EXAMPLES:
    # Interactive setup
    ./scripts/secrets-setup.sh

    # Non-interactive setup with defaults
    ./scripts/secrets-setup.sh --non-interactive

    # Custom key location
    ./scripts/secrets-setup.sh --key-path ~/.age/mykey.txt
EOF
}

# =============================================================================
# Argument Parsing (T012, T013, T014)
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --key-path)
                if [[ -z "${2:-}" ]]; then
                    log_error "--key-path requires a path argument"
                    exit 1
                fi
                KEY_PATH="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                log_error "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Setup Steps
# =============================================================================

# Step 1: Check dependencies (T008, T009)
step_check_dependencies() {
    echo ""
    echo "Step 1/4: Checking dependencies..."
    echo ""

    if ! check_dependencies; then
        exit 2
    fi

    print_dependency_versions
    echo ""
}

# Step 2: Create age encryption key (T010)
step_create_key() {
    echo "Step 2/4: Creating encryption key..."
    echo ""

    local key_dir
    key_dir=$(dirname "$KEY_PATH")

    # Check if key already exists
    if [[ -f "$KEY_PATH" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_warn "Key exists at $KEY_PATH - regenerating due to --force"
            log_warn "WARNING: This will invalidate all existing encrypted files!"
            if [[ "$NON_INTERACTIVE" == "false" ]]; then
                read -r -p "Are you sure you want to continue? [y/N] " response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    log_info "Cancelled by user"
                    exit 4
                fi
            fi
            rm -f "$KEY_PATH"
        else
            log_error "Encryption key already exists at $KEY_PATH"
            log_error "Use --force to regenerate (this will invalidate existing encrypted files)"
            exit 3
        fi
    fi

    # Create key directory if needed
    if [[ ! -d "$key_dir" ]]; then
        log_info "Creating directory: $key_dir"
        mkdir -p "$key_dir"
    fi

    # Generate the age key
    log_info "Generating age encryption key..."
    age-keygen -o "$KEY_PATH" 2>/dev/null

    # Set secure permissions
    chmod 600 "$KEY_PATH"

    # Extract and display the public key
    local public_key
    public_key=$(get_age_recipient "$KEY_PATH")

    log_success "Key created at: $KEY_PATH"
    log_info "Your public key: $public_key"
    echo ""

    # Key backup reminder (T015)
    echo -e "${YELLOW}  !!!  IMPORTANT: Back up this key to a password manager!  !!!${NC}"
    echo -e "${YELLOW}       If lost, you will need to recreate all secrets.${NC}"
    echo ""
}

# Step 3: Configure chezmoi for age encryption (T011)
step_configure_chezmoi() {
    echo "Step 3/4: Configuring chezmoi..."
    echo ""

    local chezmoi_config="${HOME}/.config/chezmoi/chezmoi.toml"
    local chezmoi_config_dir
    chezmoi_config_dir=$(dirname "$chezmoi_config")

    # Create chezmoi config directory if needed
    if [[ ! -d "$chezmoi_config_dir" ]]; then
        mkdir -p "$chezmoi_config_dir"
    fi

    # Get the public key
    local public_key
    public_key=$(get_age_recipient "$KEY_PATH")

    if [[ -z "$public_key" ]]; then
        log_error "Could not extract public key from $KEY_PATH"
        exit 1
    fi

    # Check if config exists and has age section
    if [[ -f "$chezmoi_config" ]]; then
        if grep -q '^\[age\]' "$chezmoi_config"; then
            log_info "Chezmoi age configuration already exists"
            log_info "Verifying settings..."

            # Update the identity and recipient if needed
            if ! grep -q "identity = \"$KEY_PATH\"" "$chezmoi_config"; then
                log_warn "Updating age identity path in config"
                # Use sed to update the identity line under [age] section in a portable way
                tmp_chezmoi_config="$(mktemp "${chezmoi_config}.XXXXXX")"
                sed "/^\[age\]/,/^\[/ s|identity = .*|identity = \"$KEY_PATH\"|" "$chezmoi_config" > "$tmp_chezmoi_config"
                mv "$tmp_chezmoi_config" "$chezmoi_config"
            fi
        else
            # Append age configuration
            log_info "Adding age configuration to chezmoi.toml"
            cat >> "$chezmoi_config" << EOF

[age]
    identity = "$KEY_PATH"
    recipient = "$public_key"
EOF
        fi
    else
        # Create new config
        log_info "Creating chezmoi.toml with age configuration"
        cat > "$chezmoi_config" << EOF
# Chezmoi configuration
# See: https://www.chezmoi.io/reference/configuration-file/

[age]
    identity = "$KEY_PATH"
    recipient = "$public_key"
EOF
    fi

    log_success "Chezmoi configured: $chezmoi_config"
    echo ""
}

# Step 4: Create initial encrypted secrets template (T012)
step_create_template() {
    echo "Step 4/4: Creating secrets template..."
    echo ""

    local chezmoi_source="${SECRETS_CHEZMOI_SOURCE}"
    local encrypted_file="${chezmoi_source}/${SECRETS_ENCRYPTED_FILE}"

    # Initialize chezmoi if needed
    if [[ ! -d "$chezmoi_source" ]]; then
        log_info "Initializing chezmoi source directory"
        chezmoi init
    fi

    # Check if encrypted secrets already exist
    if [[ -f "$encrypted_file" ]]; then
        log_info "Encrypted secrets file already exists"
        log_info "Location: $encrypted_file"
    else
        # Create a template secrets file
        local temp_file
        temp_file=$(mktemp)

        cat > "$temp_file" << 'EOF'
# Secrets file for development container
# Format: KEY=value (one per line)
# Lines starting with # are comments
#
# Example secrets:
# GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
# AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# DATABASE_URL=postgres://user:password@localhost:5432/mydb
#
# Edit this file and add your secrets below:

EOF

        # Add the file to chezmoi with encryption
        log_info "Creating encrypted secrets template..."

        # First, put the template where chezmoi expects the target
        local target_file="${HOME}/.secrets.env"
        cp "$temp_file" "$target_file"

        # Add to chezmoi with encryption
        chezmoi add --encrypt "$target_file"

        # Clean up
        rm -f "$temp_file" "$target_file"

        log_success "Created: $encrypted_file"
    fi

    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"

    echo ""
    echo "=== Secret Injection Setup ==="
    echo ""

    step_check_dependencies
    step_create_key
    step_configure_chezmoi
    step_create_template

    echo "=== Setup Complete ==="
    echo ""
    echo "Next steps:"
    echo "  1. Edit your secrets: chezmoi edit ~/.secrets.env"
    echo "  2. Apply changes: chezmoi apply"
    echo "  3. Restart container to load secrets"
    echo ""
}

main "$@"
