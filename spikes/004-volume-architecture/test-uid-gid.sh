#!/bin/bash
# UID/GID Testing Script
# Verifies file ownership works correctly with different mount strategies

set -e

echo "=== UID/GID Mount Compatibility Test ==="
echo ""

# Container user info
echo "Container user:"
id
echo ""

# Test directory ownership
test_ownership() {
    local dir="$1"
    local label="$2"

    echo "--- $label ---"
    echo "Path: $dir"

    if [ ! -d "$dir" ]; then
        echo "  Status: SKIP (directory does not exist)"
        echo ""
        return
    fi

    # Check if writable
    if touch "$dir/.test-write" 2>/dev/null; then
        echo "  Writable: YES"
        rm -f "$dir/.test-write"
    else
        echo "  Writable: NO"
    fi

    # Create test file and check ownership
    if echo "test" > "$dir/uid-test-file" 2>/dev/null; then
        file_owner=$(stat -c '%u:%g' "$dir/uid-test-file" 2>/dev/null || stat -f '%u:%g' "$dir/uid-test-file")
        echo "  New file owner: $file_owner"

        # Check if matches current user
        current_uid=$(id -u)
        current_gid=$(id -g)
        if [ "$file_owner" = "$current_uid:$current_gid" ]; then
            echo "  Ownership: CORRECT (matches container user)"
        else
            echo "  Ownership: MISMATCH (expected $current_uid:$current_gid)"
        fi

        rm -f "$dir/uid-test-file"
    else
        echo "  Create file: FAILED"
    fi

    # List directory ownership
    echo "  Directory contents ownership:"
    ls -la "$dir" 2>/dev/null | head -5 || echo "    (cannot list)"

    echo ""
}

# Test various paths
test_ownership "/workspace" "Workspace (bind mount)"
test_ownership "/home/dev" "Home directory"
test_ownership "/home/dev/.cache" "User cache"
test_ownership "/named-vol" "Named volume"
test_ownership "/tmp" "Tmpfs"

# Test creating nested directories
echo "--- Nested Directory Test ---"
if mkdir -p /workspace/test-nested/deep/path 2>/dev/null; then
    echo "Create nested dirs in /workspace: SUCCESS"
    touch /workspace/test-nested/deep/path/file.txt
    ls -la /workspace/test-nested/deep/path/
    rm -rf /workspace/test-nested
else
    echo "Create nested dirs in /workspace: FAILED"
fi
echo ""

echo "=== UID/GID Test Complete ==="
