#!/bin/bash
# =============================================================================
# Container Entrypoint Script - Volume Architecture
# Feature: 004-volume-architecture
# =============================================================================
# This script runs at container startup to:
# 1. Validate volume mounts (fail-fast for bind mounts)
# 2. Fix permissions on named volumes (dynamic UID detection)
# 3. Log volume status for debugging
# 4. Handle signals for graceful shutdown
# =============================================================================

set -e
set -o pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly LOG_PREFIX="[entrypoint]"

# Environment variables for UID/GID mapping
# macOS default: 501, Linux default: 1000
readonly EXPECTED_UID="${LOCAL_UID:-1000}"
readonly EXPECTED_GID="${LOCAL_GID:-1000}"

# Volume directories requiring permission fixes (named volumes only)
# Bind mounts are handled automatically by VirtioFS on macOS
readonly VOLUME_DIRS=(
    "/home/dev"
    "/home/dev/.npm"
    "/home/dev/.cache/pip"
    "/home/dev/.cargo/registry"
    "/workspace/node_modules"
    "/workspace/target"
)

# =============================================================================
# LOGGING FUNCTIONS (T007)
# =============================================================================

log() {
    echo "$LOG_PREFIX $*" >&2
}

log_error() {
    echo "$LOG_PREFIX ERROR: $*" >&2
}

log_warning() {
    echo "$LOG_PREFIX WARNING: $*" >&2
}

log_section() {
    echo "$LOG_PREFIX" >&2
    echo "$LOG_PREFIX === $* ===" >&2
}

# =============================================================================
# CROSS-PLATFORM COMPATIBILITY (T009)
# =============================================================================

# Get file owner UID - works on both Linux and macOS
# Linux uses stat -c '%u', macOS uses stat -f '%u'
get_owner_uid() {
    local path="$1"

    if [ ! -e "$path" ]; then
        log_error "Path does not exist when checking owner UID: $path"
        return 1
    fi

    case "$(uname -s)" in
        Darwin)
            stat -f '%u' "$path"
            ;;
        *)
            stat -c '%u' "$path"
            ;;
    esac
}

# Get file owner GID - works on both Linux and macOS
get_owner_gid() {
    local path="$1"

    if [ ! -e "$path" ]; then
        log_error "Path does not exist when checking owner GID: $path"
        return 1
    fi

    case "$(uname -s)" in
        Darwin)
            stat -f '%g' "$path"
            ;;
        *)
            stat -c '%g' "$path"
            ;;
    esac
}

# Get human-readable owner - works on both Linux and macOS
get_owner_name() {
    local path="$1"

    if [ ! -e "$path" ]; then
        log_error "Path does not exist when checking owner name: $path"
        return 1
    fi

    case "$(uname -s)" in
        Darwin)
            stat -f '%Su:%Sg' "$path"
            ;;
        *)
            stat -c '%U:%G' "$path"
            ;;
    esac
}

# =============================================================================
# SIGNAL HANDLING (T010)
# =============================================================================

# Child process PID for signal forwarding
CHILD_PID=""

# Trap handler for graceful shutdown
trap_shutdown() {
    log "Received shutdown signal"
    if [[ -n "$CHILD_PID" ]]; then
        log "Forwarding signal to child process (PID: $CHILD_PID)"
        kill -TERM "$CHILD_PID" 2>/dev/null || true
        wait "$CHILD_PID" 2>/dev/null || true
    fi
    exit 0
}

# Register signal handlers
trap 'trap_shutdown' SIGTERM SIGINT SIGHUP

# =============================================================================
# WORKSPACE VALIDATION (T017, T018) - US1
# =============================================================================

# Validate workspace bind mount exists and is writable (FR-013)
validate_workspace() {
    log_section "Validating Bind Mounts"

    # T017: Check workspace exists (fail-fast if missing)
    if [[ ! -d "/workspace" ]]; then
        log_error "Workspace bind mount not found at /workspace"
        log_error "Please run with: docker run -v ./src:/workspace:cached ..."
        exit 1
    fi

    # T018: Check workspace is writable
    local test_file="/workspace/.entrypoint-write-test"
    if ! touch "$test_file" 2>/dev/null; then
        log_error "Workspace /workspace is not writable"
        log_error "Check host directory permissions"
        exit 1
    fi
    rm -f "$test_file"

    log "  /workspace: mounted and writable"
}

# =============================================================================
# HOME VOLUME PERMISSION FIX (T027, T028) - US2
# =============================================================================

# Fix permissions on home directory named volume (FR-005, FR-006)
fix_home_permissions() {
    log_section "Fixing Named Volume Permissions"

    local home_dir="/home/dev"

    # T028: Volume recovery - create if missing with warning (FR-012)
    if [[ ! -d "$home_dir" ]]; then
        log_warning "Home directory missing, creating: $home_dir"
        sudo mkdir -p "$home_dir"
    fi

    # T027: Check if owned by root (UID 0) and fix if needed
    local current_uid
    current_uid=$(get_owner_uid "$home_dir" 2>/dev/null || echo "0")

    if [[ "$current_uid" == "0" ]]; then
        log "  Fixing ownership: $home_dir (root -> $EXPECTED_UID:$EXPECTED_GID)"
        sudo chown -R "$EXPECTED_UID:$EXPECTED_GID" "$home_dir"
    else
        log "  $home_dir: already owned by UID $current_uid (no fix needed)"
    fi
}

# =============================================================================
# CACHE VOLUME PERMISSION FIX (T044) - US3
# =============================================================================

# Fix permissions on cache volume directories
fix_cache_permissions() {
    log_section "Fixing Cache Volume Permissions"

    # Cache directories that need permission fixes
    local cache_dirs=(
        "/home/dev/.npm"
        "/home/dev/.cache/pip"
        "/home/dev/.cargo/registry"
        "/workspace/node_modules"
        "/workspace/target"
    )

    for dir in "${cache_dirs[@]}"; do
        # Create directory if it doesn't exist
        if [[ ! -d "$dir" ]]; then
            log "  Creating: $dir"
            sudo mkdir -p "$dir"
        fi

        # Check ownership and fix if needed
        local current_uid
        current_uid=$(get_owner_uid "$dir" 2>/dev/null || echo "0")

        if [[ "$current_uid" == "0" ]]; then
            log "  Fixing ownership: $dir (root -> $EXPECTED_UID:$EXPECTED_GID)"
            sudo chown -R "$EXPECTED_UID:$EXPECTED_GID" "$dir"
        else
            log "  $dir: owner UID $current_uid (ok)"
        fi
    done
}

# =============================================================================
# VOLUME STATUS LOGGING (T019, T029) - US1, US2
# =============================================================================

# Log volume mount status for debugging (FR-014)
log_volume_status() {
    log_section "Volume Status"

    # Log workspace status (T019)
    if [[ -d "/workspace" ]]; then
        local ws_owner
        ws_owner=$(get_owner_name "/workspace" 2>/dev/null || echo "unknown")
        log "  /workspace: bind mount, owner=$ws_owner"
    fi

    # Log home volume status (T029)
    if [[ -d "/home/dev" ]]; then
        local home_owner
        home_owner=$(get_owner_name "/home/dev" 2>/dev/null || echo "unknown")
        log "  /home/dev: named volume, owner=$home_owner"
    fi

    # Log cache volume status (US3)
    local cache_volumes=(
        "/home/dev/.npm:npm-cache"
        "/home/dev/.cache/pip:pip-cache"
        "/home/dev/.cargo/registry:cargo-registry"
        "/workspace/node_modules:node-modules"
        "/workspace/target:cargo-target"
    )

    for entry in "${cache_volumes[@]}"; do
        local path="${entry%%:*}"
        local name="${entry##*:}"
        if [[ -d "$path" ]]; then
            local owner
            owner=$(get_owner_name "$path" 2>/dev/null || echo "unknown")
            log "  $path: $name volume, owner=$owner"
        fi
    done

    # Log tmpfs status (T051 - US4)
    if [[ -d "/tmp" ]]; then
        local tmp_type
        tmp_type=$(df -T /tmp 2>/dev/null | tail -1 | awk '{print $2}' || echo "unknown")
        local tmp_size
        tmp_size=$(df -h /tmp 2>/dev/null | tail -1 | awk '{print $2}' || echo "unknown")
        log "  /tmp: $tmp_type, size=$tmp_size (ephemeral)"
    fi
}

# =============================================================================
# MAIN ENTRYPOINT
# =============================================================================

main() {
    log_section "Container Entrypoint Starting"

    # Log environment information (T008)
    log "User: $(whoami) (UID: $(id -u), GID: $(id -g))"
    log "Expected UID: $EXPECTED_UID, Expected GID: $EXPECTED_GID"
    log "Working Directory: $(pwd)"

    # Validate workspace bind mount (T017, T018)
    validate_workspace

    # Fix home volume permissions (T027, T028)
    fix_home_permissions

    # Fix cache volume permissions (T044)
    fix_cache_permissions

    # Log volume status (T019, T029)
    log_volume_status

    log_section "Container Ready"

    # Execute command or default shell
    if [[ $# -eq 0 ]]; then
        log "Executing: /bin/bash -l (default shell)"
        exec /bin/bash -l
    else
        log "Executing: $*"
        exec "$@"
    fi
}

# Run main function with all arguments
main "$@"
