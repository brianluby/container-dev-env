#!/bin/bash
set -euo pipefail
# =============================================================================
# Volume Health Diagnostic Script (T058)
# Feature: 004-volume-architecture
# =============================================================================
# Provides diagnostic information about Docker volumes used by devenv
# Usage: ./scripts/volume-health.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Volume prefix
VOLUME_PREFIX="devenv-"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_section() {
    echo ""
    echo -e "${YELLOW}--- $* ---${NC}"
}

# =============================================================================
# VOLUME LISTING
# =============================================================================

list_volumes() {
    print_header "DevEnv Volumes"

    # List all devenv volumes
    local volumes
    volumes=$(docker volume ls --format '{{.Name}}' | grep "^${VOLUME_PREFIX}" || echo "")

    if [[ -z "$volumes" ]]; then
        echo -e "${YELLOW}No devenv volumes found.${NC}"
        echo "Run 'docker compose up' to create volumes."
        return
    fi

    echo ""
    printf "%-25s %-15s %-15s %-10s\n" "VOLUME NAME" "TYPE" "SAFE TO PRUNE" "SIZE"
    printf "%-25s %-15s %-15s %-10s\n" "-------------------------" "---------------" "---------------" "----------"

    for vol in $volumes; do
        local vol_type
        vol_type=$(docker volume inspect "$vol" --format '{{index .Labels "com.devenv.type"}}' 2>/dev/null || echo "unknown")

        local safe_prune
        safe_prune=$(docker volume inspect "$vol" --format '{{index .Labels "com.devenv.safe-to-prune"}}' 2>/dev/null || echo "unknown")

        # Get volume size (requires docker system df)
        local size
        size=$(docker system df -v 2>/dev/null | grep "$vol" | awk '{print $3}' || echo "N/A")

        # Color code based on safe-to-prune
        if [[ "$safe_prune" == "false" ]]; then
            printf "%-25s %-15s ${RED}%-15s${NC} %-10s\n" "$vol" "$vol_type" "$safe_prune" "$size"
        else
            printf "%-25s %-15s ${GREEN}%-15s${NC} %-10s\n" "$vol" "$vol_type" "$safe_prune" "$size"
        fi
    done
}

# =============================================================================
# VOLUME HEALTH CHECK
# =============================================================================

check_volume_health() {
    print_header "Volume Health Check"

    local issues=0

    # Check each expected volume
    local expected_volumes=(
        "devenv-home:home:false"
        "devenv-npm-cache:cache:true"
        "devenv-pip-cache:cache:true"
        "devenv-cargo-registry:cache:true"
        "devenv-node-modules:build:true"
        "devenv-cargo-target:build:true"
    )

    for entry in "${expected_volumes[@]}"; do
        local vol_name="${entry%%:*}"
        local remainder="${entry#*:}"
        local expected_type="${remainder%%:*}"
        local expected_prune="${remainder##*:}"

        if docker volume inspect "$vol_name" &>/dev/null; then
            local actual_type
            actual_type=$(docker volume inspect "$vol_name" --format '{{index .Labels "com.devenv.type"}}' 2>/dev/null || echo "")

            local actual_prune
            actual_prune=$(docker volume inspect "$vol_name" --format '{{index .Labels "com.devenv.safe-to-prune"}}' 2>/dev/null || echo "")

            if [[ "$actual_type" == "$expected_type" ]] && [[ "$actual_prune" == "$expected_prune" ]]; then
                echo -e "${GREEN}✓${NC} $vol_name: OK"
            else
                echo -e "${YELLOW}⚠${NC} $vol_name: Labels mismatch (type=$actual_type, prune=$actual_prune)"
                ((issues++))
            fi
        else
            echo -e "${YELLOW}○${NC} $vol_name: Not created yet"
        fi
    done

    echo ""
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}All volumes healthy.${NC}"
    else
        echo -e "${YELLOW}Found $issues issue(s).${NC}"
    fi
}

# =============================================================================
# SAFE CLEANUP SUGGESTIONS
# =============================================================================

show_cleanup_commands() {
    print_header "Safe Cleanup Commands"

    echo "Remove cache volumes only (safe, rebuilds automatically):"
    echo -e "${YELLOW}  docker volume rm devenv-npm-cache devenv-pip-cache devenv-cargo-registry${NC}"
    echo ""

    echo "Remove build volumes (project-specific, safe to rebuild):"
    echo -e "${YELLOW}  docker volume rm devenv-node-modules devenv-cargo-target${NC}"
    echo ""

    echo "Remove home volume (CAUTION: loses shell history and dotfiles):"
    echo -e "${RED}  docker volume rm devenv-home${NC}"
    echo ""

    echo "Remove ALL devenv volumes:"
    echo -e "${RED}  docker volume rm \$(docker volume ls -q | grep '^devenv-')${NC}"
    echo ""

    echo "Standard docker prune (SAFE - named volumes survive):"
    echo -e "${GREEN}  docker system prune${NC}"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    echo -e "${BLUE}DevEnv Volume Health Diagnostic${NC}"
    echo "================================"

    list_volumes
    check_volume_health
    show_cleanup_commands

    echo ""
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
