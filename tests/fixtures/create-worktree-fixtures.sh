#!/bin/bash
# =============================================================================
# Test Fixture Script: Git Worktree Compatibility
# Feature: 007-git-worktree-compat
# =============================================================================
# Creates test repositories with various worktree configurations for testing
# the validate_worktree() entrypoint function.
#
# Usage: ./create-worktree-fixtures.sh <output-dir>
# =============================================================================

set -e
set -o pipefail

FIXTURES_DIR="${1:-$(mktemp -d)}"

echo "Creating worktree test fixtures in: $FIXTURES_DIR"

# =============================================================================
# Fixture 1: Standard repository (normal .git/ directory)
# =============================================================================
create_standard_repo() {
    local dir="$FIXTURES_DIR/standard-repo"
    mkdir -p "$dir"
    cd "$dir"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "hello" > file.txt
    git add file.txt
    git commit -m "Initial commit"
    echo "Created: standard-repo (normal .git/ directory)"
}

# =============================================================================
# Fixture 2: Main repository with worktrees
# =============================================================================
create_main_repo_with_worktrees() {
    local dir="$FIXTURES_DIR/main-repo"
    mkdir -p "$dir"
    cd "$dir"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "main content" > main.txt
    git add main.txt
    git commit -m "Initial commit on main"

    # Create branches for worktrees
    git branch feature-branch
    git branch detached-target

    # Create worktree: feature branch
    git worktree add "$FIXTURES_DIR/worktree-feature" feature-branch

    # Create worktree: detached HEAD
    local commit_hash
    commit_hash=$(git rev-parse HEAD)
    git worktree add --detach "$FIXTURES_DIR/worktree-detached" "$commit_hash"

    echo "Created: main-repo with worktrees"
}

# =============================================================================
# Fixture 3: Broken worktree (invalid gitdir pointer)
# =============================================================================
create_broken_worktree() {
    local dir="$FIXTURES_DIR/broken-worktree"
    mkdir -p "$dir"
    echo "gitdir: /nonexistent/path/.git/worktrees/broken" > "$dir/.git"
    echo "some content" > "$dir/file.txt"
    echo "Created: broken-worktree (invalid gitdir pointer)"
}

# =============================================================================
# Fixture 4: Corrupt .git file (no gitdir prefix)
# =============================================================================
create_corrupt_git_file() {
    local dir="$FIXTURES_DIR/corrupt-git-file"
    mkdir -p "$dir"
    echo "this is not a valid git file" > "$dir/.git"
    echo "Created: corrupt-git-file (no gitdir: prefix)"
}

# =============================================================================
# Fixture 5: Empty .git file
# =============================================================================
create_empty_git_file() {
    local dir="$FIXTURES_DIR/empty-git-file"
    mkdir -p "$dir"
    touch "$dir/.git"
    echo "Created: empty-git-file (empty .git file)"
}

# =============================================================================
# Fixture 6: Plain directory (no git at all)
# =============================================================================
create_plain_dir() {
    local dir="$FIXTURES_DIR/plain-dir"
    mkdir -p "$dir"
    echo "just a file" > "$dir/file.txt"
    echo "Created: plain-dir (no .git)"
}

# =============================================================================
# Fixture 7: Worktree with relative gitdir path
# =============================================================================
create_relative_worktree() {
    local dir="$FIXTURES_DIR/relative-worktree"
    mkdir -p "$dir"
    # Create a main repo that the relative path points to
    local main_dir="$FIXTURES_DIR/relative-main"
    mkdir -p "$main_dir/.git/worktrees/relative-wt"
    echo "ref: refs/heads/main" > "$main_dir/.git/worktrees/relative-wt/HEAD"
    # Use relative path in .git file
    echo "gitdir: ../relative-main/.git/worktrees/relative-wt" > "$dir/.git"
    echo "Created: relative-worktree (relative gitdir path)"
}

# =============================================================================
# Fixture 8: Locked worktree
# =============================================================================
create_locked_worktree() {
    local main_dir="$FIXTURES_DIR/main-repo"
    if [[ -d "$main_dir" ]] && [[ -d "$FIXTURES_DIR/worktree-feature" ]]; then
        cd "$main_dir"
        git worktree lock "$FIXTURES_DIR/worktree-feature" --reason "testing lock display" 2>/dev/null || true
        echo "Created: locked worktree-feature"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

mkdir -p "$FIXTURES_DIR"

create_standard_repo
create_main_repo_with_worktrees
create_broken_worktree
create_corrupt_git_file
create_empty_git_file
create_plain_dir
create_relative_worktree
create_locked_worktree

# =============================================================================
# VALIDATION
# =============================================================================

validate_fixtures() {
    local errors=0

    # Standard repo must have .git directory
    if [[ ! -d "$FIXTURES_DIR/standard-repo/.git" ]]; then
        echo "ERROR: standard-repo/.git directory missing"
        ((errors++))
    fi

    # Main repo must have .git directory with worktrees
    if [[ ! -d "$FIXTURES_DIR/main-repo/.git/worktrees" ]]; then
        echo "ERROR: main-repo/.git/worktrees directory missing"
        ((errors++))
    fi

    # Worktree fixtures must have .git files (not directories)
    for wt in worktree-feature worktree-detached broken-worktree; do
        if [[ ! -f "$FIXTURES_DIR/$wt/.git" ]]; then
            echo "ERROR: $wt/.git file missing"
            ((errors++))
        fi
    done

    # Corrupt fixture must have non-gitdir content
    if [[ ! -f "$FIXTURES_DIR/corrupt-git-file/.git" ]]; then
        echo "ERROR: corrupt-git-file/.git file missing"
        ((errors++))
    fi

    # Empty fixture must exist and be empty
    if [[ ! -f "$FIXTURES_DIR/empty-git-file/.git" ]]; then
        echo "ERROR: empty-git-file/.git file missing"
        ((errors++))
    elif [[ -s "$FIXTURES_DIR/empty-git-file/.git" ]]; then
        local size
        size=$(wc -c < "$FIXTURES_DIR/empty-git-file/.git")
        echo "ERROR: empty-git-file/.git should be empty but has content (size: $size bytes)"
        ((errors++))
    fi

    # Plain dir must NOT have .git
    if [[ -e "$FIXTURES_DIR/plain-dir/.git" ]]; then
        echo "ERROR: plain-dir should not have .git"
        ((errors++))
    fi

    # Locked worktree is optional (git worktree lock may not be available)
    # No validation needed

    if [[ $errors -gt 0 ]]; then
        echo "Validation failed with $errors error(s)"
        return 1
    fi

    echo "Fixture validation passed"
    return 0
}

validate_fixtures || {
    echo "ERROR: Fixture creation validation failed. Tests may produce false positives."
    exit 1
}

echo ""
echo "All fixtures created in: $FIXTURES_DIR"
echo "Fixtures:"
ls -1 "$FIXTURES_DIR"
