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

# Workspace directory for worktree detection (007-git-worktree-compat)
readonly WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"

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
# GIT WORKTREE VALIDATION (007-git-worktree-compat) - US1
# =============================================================================

# Validate git worktree metadata accessibility (FR-001, FR-002, FR-003, FR-010)
# Non-blocking: always returns 0, prints warnings to stderr if issues detected
validate_worktree() {
    local ws_dir="${WORKSPACE_DIR:-/workspace}"
    local git_path="$ws_dir/.git"

    # FR-001: Check if .git exists at all
    if [[ ! -e "$git_path" ]]; then
        # Not a git repository — nothing to validate
        return 0
    fi

    # FR-001: Check if .git is a directory (standard repo) or file (worktree)
    if [[ -d "$git_path" ]]; then
        # Standard repository — no worktree validation needed
        return 0
    fi

    # .git is a file — this is a worktree
    if [[ ! -r "$git_path" ]]; then
        # Permission denied reading .git file
        log_warning "Git worktree .git file is not readable at $git_path"
        return 0
    fi

    # Read and validate .git file content
    local git_content
    git_content=$(cat "$git_path" 2>/dev/null) || {
        log_warning "Failed to read .git file at $git_path"
        return 0
    }

    # Check for empty file
    if [[ -z "$git_content" ]]; then
        log_warning "Git .git file is empty or corrupt at $git_path"
        return 0
    fi

    # Parse gitdir: pointer (FR-002)
    if [[ ! "$git_content" =~ ^gitdir:[[:space:]]+(.+)$ ]]; then
        log_warning "Git .git file is corrupt (no 'gitdir:' prefix) at $git_path"
        return 0
    fi

    local gitdir_path="${BASH_REMATCH[1]}"

    # Handle relative paths — resolve relative to workspace directory
    if [[ "$gitdir_path" != /* ]]; then
        gitdir_path="$(cd "$ws_dir" && cd "$(dirname "$gitdir_path")" && pwd)/$(basename "$gitdir_path")"
    fi

    # FR-002: Validate metadata directory is accessible
    if [[ -d "$gitdir_path" ]]; then
        log "  Git worktree detected: metadata accessible at $gitdir_path"
        return 0
    fi

    # FR-003, FR-010: Metadata is inaccessible — warn with actionable fix
    log_warning "Git worktree detected but metadata is inaccessible"
    log "  Workspace: $ws_dir"
    log "  Expected git dir: $gitdir_path"
    log "  This path is not accessible inside the container."

    # Infer the main repository root from the gitdir path
    # Expected pattern: /path/to/main-repo/.git/worktrees/<name>
    if [[ "$gitdir_path" == *"/.git/worktrees/"* ]]; then
        local main_repo_git="${gitdir_path%/worktrees/*}"
        local main_repo_root="${main_repo_git%/.git}"

        # Ensure the inferred paths are sane before suggesting fixes
        if [[ -n "$main_repo_root" ]] && \
           [[ "$main_repo_git" != "$gitdir_path" ]] && \
           [[ "$main_repo_root" != "$main_repo_git" ]] && \
           [[ "$main_repo_git" == */.git ]]; then
            log "  Fix: Mount the main repository root instead:"
            log "    docker run -v $main_repo_root:/workspace ..."
            log "  Or mount both the worktree and the main .git directory:"
            log "    docker run -v $ws_dir:/workspace -v $main_repo_git:$main_repo_git:ro ..."
        else
            log "  Note: Git worktree path is non-standard; could not safely infer main repository root."
            log "        Please mount the appropriate repository paths manually based on:"
            log "          gitdir: $gitdir_path"
        fi
    else
        log "  Note: Gitdir path does not match expected worktree pattern (/path/to/main-repo/.git/worktrees/<name>)."
        log "        Please mount the appropriate repository paths manually based on:"
        log "          gitdir: $gitdir_path"
    fi

    return 0
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
    # Get owner UID; do not treat failures as UID 0, and avoid exiting due to set -e
    current_uid=$(get_owner_uid "$home_dir" 2>/dev/null || true)

    # Handle failure to determine UID explicitly
    if [[ -z "$current_uid" ]]; then
        log_warning "Could not determine owner UID for $home_dir; assuming root (0) for permission fix"
        current_uid=0
    fi

    if [[ "$current_uid" -eq 0 ]]; then
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

    # Log git worktree status (007-git-worktree-compat - US3, FR-008)
    local ws_dir="${WORKSPACE_DIR:-/workspace}"
    if [[ -f "$ws_dir/.git" ]] && command -v git &>/dev/null; then
        local wt_list
        wt_list=$(cd "$ws_dir" && git worktree list 2>/dev/null) || true
        if [[ -n "$wt_list" ]]; then
            log "  Git worktrees:"
            while IFS= read -r line; do
                log "    $line"
            done <<< "$wt_list"
        fi
    fi

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

    # Validate git worktree metadata accessibility (007-git-worktree-compat)
    validate_worktree

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
