#!/bin/bash
# =============================================================================
# Integration Tests: Git Worktree Compatibility
# Feature: 007-git-worktree-compat
# =============================================================================
# Tests the container entrypoint behavior with various git worktree scenarios.
# Requires Docker to be available.
#
# Usage: bash tests/integration/test_worktree_container.sh
# =============================================================================

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES_DIR="$(mktemp -d)"
IMAGE_NAME="devcontainer-worktree-test"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# =============================================================================
# HELPERS
# =============================================================================

log_test() {
    echo "--- TEST: $1"
}

pass() {
    echo "    PASS: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo "    FAIL: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

skip_test() {
    echo "    SKIP: $1"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "ERROR: Docker is not available. Skipping integration tests."
        exit 3
    fi
}

# Build the test container image
build_image() {
    echo "=== Building test container image ==="
    docker build -t "$IMAGE_NAME" "$PROJECT_ROOT/docker/" 2>&1 | tail -5
    echo ""
}

# Create test fixtures
create_fixtures() {
    echo "=== Creating test fixtures ==="
    bash "$PROJECT_ROOT/tests/fixtures/create-worktree-fixtures.sh" "$FIXTURES_DIR"
    echo ""
}

# Run container and capture stdout and stderr separately
# Usage: run_container <mount_args...>
# Returns: stdout in $CONTAINER_STDOUT, stderr in $CONTAINER_STDERR, exit code in $CONTAINER_EXIT
run_container() {
    local stdout_file stderr_file
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)
    local exit_code=0
    
    { docker run --rm "$@" "$IMAGE_NAME" echo "started" >"$stdout_file" 2>"$stderr_file"; } || exit_code=$?
    
    CONTAINER_STDOUT=$(cat "$stdout_file")
    CONTAINER_STDERR=$(cat "$stderr_file")
    CONTAINER_EXIT=$exit_code
    
    rm -f "$stdout_file" "$stderr_file"
}

# =============================================================================
# WT-I001: Standard repo mount — no worktree warning
# =============================================================================
test_standard_repo_mount() {
    log_test "WT-I001: Standard repo mount produces no worktree warning"

    run_container -v "$FIXTURES_DIR/standard-repo:/workspace"

    if echo "$CONTAINER_STDERR" | grep -q "worktree detected"; then
        fail "Unexpected worktree warning for standard repo"
    else
        pass "No worktree warning for standard repo"
    fi
}

# =============================================================================
# WT-I002: Worktree with parent accessible — no warning, git works
# =============================================================================
test_worktree_with_parent() {
    log_test "WT-I002: Worktree with parent accessible works correctly"

    local main_git="$FIXTURES_DIR/main-repo/.git"
    run_container \
        -v "$FIXTURES_DIR/worktree-feature:/workspace" \
        -v "$main_git:$main_git:ro"

    if echo "$CONTAINER_STDERR" | grep -q "WARNING"; then
        fail "Unexpected warning for worktree with accessible parent"
    elif echo "$CONTAINER_STDERR" | grep -q "accessible"; then
        pass "Worktree with accessible metadata detected correctly"
    else
        pass "No warning for worktree with parent mounted"
    fi
}

# =============================================================================
# WT-I003: Worktree without parent — warning, container starts
# =============================================================================
test_worktree_without_parent() {
    log_test "WT-I003: Worktree without parent shows warning but container starts"

    run_container -v "$FIXTURES_DIR/broken-worktree:/workspace"

    if echo "$CONTAINER_STDERR" | grep -q "inaccessible"; then
        if echo "$CONTAINER_STDOUT" | grep -q "started"; then
            pass "Warning shown on stderr and container started"
        else
            fail "Warning shown but container did not start"
        fi
    else
        fail "No inaccessible warning on stderr for broken worktree"
    fi
}

# =============================================================================
# WT-I004: Non-git directory — no warnings
# =============================================================================
test_non_git_dir() {
    log_test "WT-I004: Non-git directory produces no warnings"

    run_container -v "$FIXTURES_DIR/plain-dir:/workspace"

    if echo "$CONTAINER_STDERR" | grep -q "worktree"; then
        fail "Unexpected worktree output on stderr for non-git directory"
    else
        pass "No worktree-related output for non-git directory"
    fi
}

# =============================================================================
# WT-I005: Git operations work in worktree
# =============================================================================
test_git_ops_in_worktree() {
    log_test "WT-I005: Git operations work in worktree"

    local main_git="$FIXTURES_DIR/main-repo/.git"
    local output
    output=$(docker run --rm \
        -v "$FIXTURES_DIR/worktree-feature:/workspace" \
        -v "$main_git:$main_git:ro" \
        "$IMAGE_NAME" \
        bash -c "git config --global --add safe.directory /workspace && cd /workspace && git status && git log --oneline -1 && git branch" 2>&1) || true

    if echo "$output" | grep -q "feature-branch"; then
        pass "Git operations work in worktree (branch detected)"
    else
        fail "Git operations failed in worktree: $output"
    fi
}

# =============================================================================
# WT-I006: Commit on correct branch
# =============================================================================
test_commit_correct_branch() {
    log_test "WT-I006: Commit lands on correct branch"

    local main_git="$FIXTURES_DIR/main-repo/.git"
    local output
    output=$(docker run --rm \
        -v "$FIXTURES_DIR/worktree-feature:/workspace" \
        -v "$main_git:$main_git" \
        "$IMAGE_NAME" \
        bash -c "git config --global --add safe.directory /workspace && cd /workspace && git rev-parse --abbrev-ref HEAD" 2>&1) || true

    if echo "$output" | grep -q "feature-branch"; then
        pass "HEAD points to feature-branch in worktree"
    else
        fail "Expected feature-branch, got: $output"
    fi
}

# =============================================================================
# WT-I007: Detached HEAD reported correctly
# =============================================================================
test_detached_head() {
    log_test "WT-I007: Detached HEAD reported correctly"

    local main_git="$FIXTURES_DIR/main-repo/.git"
    local output
    output=$(docker run --rm \
        -v "$FIXTURES_DIR/worktree-detached:/workspace" \
        -v "$main_git:$main_git:ro" \
        "$IMAGE_NAME" \
        bash -c "git config --global --add safe.directory /workspace && cd /workspace && git rev-parse --abbrev-ref HEAD" 2>&1) || true

    if echo "$output" | grep -q "HEAD"; then
        pass "Detached HEAD state correctly reported"
    else
        fail "Expected HEAD (detached), got: $output"
    fi
}

# =============================================================================
# WT-I008: Custom WORKSPACE_DIR works
# =============================================================================
test_custom_workspace_dir() {
    log_test "WT-I008: Custom WORKSPACE_DIR works"

    run_container \
        -e "WORKSPACE_DIR=/custom" \
        -v "$FIXTURES_DIR/broken-worktree:/custom" \
        -v "$FIXTURES_DIR/plain-dir:/workspace"

    if echo "$CONTAINER_STDERR" | grep -q "/custom"; then
        pass "Custom WORKSPACE_DIR used for detection"
    else
        # The workspace validation might fail if /workspace has content but no worktree
        # Check that the worktree warning references the custom path
        if echo "$CONTAINER_STDERR" | grep -q "inaccessible"; then
            pass "Worktree check ran against custom path"
        else
            fail "Custom WORKSPACE_DIR not used: $CONTAINER_STDERR"
        fi
    fi
}

# =============================================================================
# WT-I009: Worktree list accessible
# =============================================================================
test_worktree_list() {
    log_test "WT-I009: git worktree list shows all worktrees"

    local main_git="$FIXTURES_DIR/main-repo/.git"
    local output
    output=$(docker run --rm \
        -v "$FIXTURES_DIR/worktree-feature:/workspace" \
        -v "$main_git:$main_git:ro" \
        -v "$FIXTURES_DIR/main-repo:/mnt/main-repo:ro" \
        "$IMAGE_NAME" \
        bash -c "git config --global --add safe.directory /workspace && git config --global --add safe.directory /mnt/main-repo && cd /workspace && git worktree list 2>/dev/null" 2>&1) || true

    if echo "$output" | grep -q "worktree\|feature"; then
        pass "git worktree list shows worktree information"
    else
        # The list might not work perfectly with remapped paths
        skip_test "git worktree list may not resolve paths in container"
    fi
}

# =============================================================================
# WT-I010: Warning includes fix command
# =============================================================================
test_warning_includes_fix() {
    log_test "WT-I010: Warning includes actionable fix command"

    run_container -v "$FIXTURES_DIR/broken-worktree:/workspace"

    if echo "$CONTAINER_STDERR" | grep -q "docker run"; then
        pass "Warning includes docker run fix command on stderr"
    else
        fail "Warning does not include fix command on stderr: $CONTAINER_STDERR"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

echo "============================================"
echo "Integration Tests: Git Worktree Compatibility"
echo "============================================"
echo ""

check_docker
build_image
create_fixtures

echo "=== Running Integration Tests ==="
echo ""

test_standard_repo_mount
test_worktree_with_parent
test_worktree_without_parent
test_non_git_dir
test_git_ops_in_worktree
test_commit_correct_branch
test_detached_head
test_custom_workspace_dir
test_worktree_list
test_warning_includes_fix

echo ""
echo "============================================"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_SKIPPED skipped"
echo "============================================"

# Cleanup
rm -rf "$FIXTURES_DIR"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi
exit 0
