#!/bin/bash
# Entrypoint script for hybrid volume architecture
# Fixes ownership of named volume mount points on first run

set -e

# Directories that may be named volumes needing ownership fix
VOLUME_DIRS=(
    "/home/dev/.npm"
    "/home/dev/.cache"
    "/home/dev/.cache/pip"
    "/workspace/node_modules"
)

# Expected owner
EXPECTED_UID=${LOCAL_UID:-1000}
EXPECTED_GID=${LOCAL_GID:-1000}

fix_permissions() {
    local dir="$1"

    # Skip if directory doesn't exist
    [[ ! -d "$dir" ]] && return 0

    # Check current ownership
    local current_uid=$(stat -c '%u' "$dir" 2>/dev/null || stat -f '%u' "$dir" 2>/dev/null)

    # Fix if owned by root (UID 0) and we have sudo
    if [[ "$current_uid" == "0" ]] && command -v sudo &>/dev/null; then
        echo "[entrypoint] Fixing ownership of $dir"
        sudo chown -R "${EXPECTED_UID}:${EXPECTED_GID}" "$dir"
    fi
}

# Fix permissions on known volume mount points
for dir in "${VOLUME_DIRS[@]}"; do
    fix_permissions "$dir"
done

# Execute the main command
exec "$@"
