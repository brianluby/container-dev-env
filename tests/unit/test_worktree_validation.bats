#!/usr/bin/env bats
# =============================================================================
# Unit Tests: validate_worktree() function
# Feature: 007-git-worktree-compat
# =============================================================================
# Tests the worktree detection and validation logic in isolation.
# Run with: bats tests/unit/test_worktree_validation.bats
# =============================================================================

# Load BATS helpers
load '.bats-battery/bats-support/load'
load '.bats-battery/bats-assert/load'

# Source the entrypoint to get access to functions
# We need to prevent main() from executing, so we source with a guard
setup() {
    # Create a temp directory for each test
    TEST_DIR="$(mktemp -d)"
    export WORKSPACE_DIR="$TEST_DIR"

    # Source only the functions from entrypoint (not main)
    ENTRYPOINT_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../docker" && pwd)/entrypoint.sh"

    # Create a sourceable version that doesn't execute main or set strict modes
    FUNC_FILE="$TEST_DIR/functions.sh"
    grep -v '^main "\$@"$' "$ENTRYPOINT_PATH" \
        | grep -v '^set -e$' \
        | grep -v '^set -o pipefail$' \
        | sed 's/^readonly WORKSPACE_DIR=.*/WORKSPACE_DIR="${WORKSPACE_DIR:-\/workspace}"/' \
        > "$FUNC_FILE"
    source "$FUNC_FILE"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# =============================================================================
# WT-U001: No .git in workspace → no output, exit 0
# =============================================================================
@test "T006: no .git in workspace produces no output" {
    # Arrange: plain directory with no .git
    echo "just a file" > "$TEST_DIR/file.txt"

    # Act
    run validate_worktree

    # Assert
    assert_success
    refute_output --partial "worktree"
    refute_output --partial "WARNING"
}

# =============================================================================
# WT-U002: Standard .git directory → no worktree warning, exit 0
# =============================================================================
@test "T007: standard .git directory produces no worktree warning" {
    # Arrange: create a .git directory (standard repo)
    mkdir -p "$TEST_DIR/.git"

    # Act
    run validate_worktree

    # Assert
    assert_success
    refute_output --partial "WARNING"
    refute_output --partial "worktree detected"
}

# =============================================================================
# WT-U003: Worktree with accessible metadata → informational log, exit 0
# =============================================================================
@test "T008: worktree with accessible metadata logs info and exits 0" {
    # Arrange: create a valid worktree structure
    local git_dir="$TEST_DIR/main-repo/.git/worktrees/my-feature"
    mkdir -p "$git_dir"
    echo "ref: refs/heads/my-feature" > "$git_dir/HEAD"
    echo "gitdir: $git_dir" > "$TEST_DIR/.git"

    # Act
    run validate_worktree

    # Assert
    assert_success
    refute_output --partial "WARNING"
    assert_output --partial "worktree"
    assert_output --partial "accessible"
}

# =============================================================================
# WT-U004: Worktree with inaccessible metadata → warning on stderr, exit 0
# =============================================================================
@test "T009: worktree with inaccessible metadata warns on stderr" {
    # Arrange: .git file pointing to non-existent path
    echo "gitdir: /nonexistent/path/.git/worktrees/broken" > "$TEST_DIR/.git"

    # Act
    run validate_worktree

    # Assert
    assert_success
    assert_output --partial "WARNING"
    assert_output --partial "inaccessible"
}

# =============================================================================
# WT-U005: Empty .git file → warning about corrupt file, exit 0
# =============================================================================
@test "T010: empty .git file warns about corrupt file" {
    # Arrange: empty .git file
    touch "$TEST_DIR/.git"

    # Act
    run validate_worktree

    # Assert
    assert_success
    assert_output --partial "WARNING"
    assert_output --partial "corrupt"
}

# =============================================================================
# WT-U006: .git file without gitdir prefix → warning, exit 0
# =============================================================================
@test "T011: .git file without gitdir prefix warns" {
    # Arrange: .git file with invalid content
    echo "this is not a valid git file" > "$TEST_DIR/.git"

    # Act
    run validate_worktree

    # Assert
    assert_success
    assert_output --partial "WARNING"
    assert_output --partial "corrupt"
}

# =============================================================================
# WT-U007: Relative gitdir path → resolves correctly
# =============================================================================
@test "T012: relative gitdir path is resolved correctly" {
    # Arrange: create structure with relative path
    local main_git_dir="$TEST_DIR/main-repo/.git/worktrees/rel-feature"
    mkdir -p "$main_git_dir"
    echo "ref: refs/heads/rel-feature" > "$main_git_dir/HEAD"

    # Create workspace as a subdirectory, use relative path
    local ws_dir="$TEST_DIR/workspaces/my-worktree"
    mkdir -p "$ws_dir"
    echo "gitdir: ../../main-repo/.git/worktrees/rel-feature" > "$ws_dir/.git"

    export WORKSPACE_DIR="$ws_dir"

    # Act
    run validate_worktree

    # Assert
    assert_success
    refute_output --partial "WARNING"
    assert_output --partial "accessible"
}

# =============================================================================
# WT-U008: WORKSPACE_DIR override → uses custom path
# =============================================================================
@test "T013: WORKSPACE_DIR override uses custom path" {
    # Arrange: create a custom workspace path
    local custom_dir="$TEST_DIR/custom-workspace"
    mkdir -p "$custom_dir"
    echo "just a file" > "$custom_dir/file.txt"
    export WORKSPACE_DIR="$custom_dir"

    # Act
    run validate_worktree

    # Assert: should check custom path (no .git = no output)
    assert_success
    refute_output --partial "WARNING"
    refute_output --partial "/workspace"
}

# =============================================================================
# WT-U009: Permission denied on .git file → warning, exit 0
# =============================================================================
@test "T014: permission denied on .git file warns and continues" {
    # Arrange: .git file with no read permission
    echo "gitdir: /some/path" > "$TEST_DIR/.git"
    chmod 000 "$TEST_DIR/.git"

    # Act
    run validate_worktree

    # Assert
    assert_success
    assert_output --partial "WARNING"

    # Cleanup: restore permissions for teardown
    chmod 644 "$TEST_DIR/.git"
}

# =============================================================================
# WT-U010: Detached HEAD in worktree → no warning (metadata accessible)
# =============================================================================
@test "T026: detached HEAD worktree with accessible metadata produces no warning" {
    # Arrange: create a valid worktree with detached HEAD
    local git_dir="$TEST_DIR/main-repo/.git/worktrees/detached-wt"
    mkdir -p "$git_dir"
    # Detached HEAD points to a commit hash, not a ref
    echo "abc123def456" > "$git_dir/HEAD"
    echo "gitdir: $git_dir" > "$TEST_DIR/.git"

    # Act
    run validate_worktree

    # Assert: metadata is accessible, so no warning
    assert_success
    refute_output --partial "WARNING"
    assert_output --partial "accessible"
}
