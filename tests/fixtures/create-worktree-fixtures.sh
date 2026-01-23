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
        if git worktree lock "$FIXTURES_DIR/worktree-feature" --reason "testing lock display" 2>/dev/null; then
            echo "Created: locked worktree-feature"
        else
            echo "Warning: Failed to lock worktree-feature. Locked worktree tests will be skipped." >&2
        fi
    else
        echo "Warning: Cannot lock worktree-feature - main-repo or worktree-feature missing. Locked worktree tests will be skipped." >&2
    fi
}

# =============================================================================
# Validation: Verify all expected fixtures were created correctly
# =============================================================================
validate_fixtures() {
    local errors=0
    
    echo ""
    echo "Validating fixture structures..."
    
    # Fixture 1: standard-repo
    if [[ ! -d "$FIXTURES_DIR/standard-repo/.git" ]]; then
        echo "  ERROR: standard-repo/.git directory missing"
        errors=$((errors + 1))
    fi
    if [[ ! -f "$FIXTURES_DIR/standard-repo/file.txt" ]]; then
        echo "  ERROR: standard-repo/file.txt missing"
        errors=$((errors + 1))
    fi
    
    # Fixture 2: main-repo
    if [[ ! -d "$FIXTURES_DIR/main-repo/.git" ]]; then
        echo "  ERROR: main-repo/.git directory missing"
        errors=$((errors + 1))
    fi
    if [[ ! -f "$FIXTURES_DIR/main-repo/main.txt" ]]; then
        echo "  ERROR: main-repo/main.txt missing"
        errors=$((errors + 1))
    fi
    
    # Fixture 2a: worktree-feature (created by main-repo)
    if [[ ! -f "$FIXTURES_DIR/worktree-feature/.git" ]]; then
        echo "  ERROR: worktree-feature/.git file missing"
        errors=$((errors + 1))
    fi
    
    # Fixture 2b: worktree-detached (created by main-repo)
    if [[ ! -f "$FIXTURES_DIR/worktree-detached/.git" ]]; then
        echo "  ERROR: worktree-detached/.git file missing"
        errors=$((errors + 1))
    fi
    
    # Fixture 3: broken-worktree
    if [[ ! -f "$FIXTURES_DIR/broken-worktree/.git" ]]; then
        echo "  ERROR: broken-worktree/.git file missing"
        errors=$((errors + 1))
    fi
    if [[ ! -f "$FIXTURES_DIR/broken-worktree/file.txt" ]]; then
        echo "  ERROR: broken-worktree/file.txt missing"
        errors=$((errors + 1))
    fi
    
    # Fixture 4: corrupt-git-file
    if [[ ! -f "$FIXTURES_DIR/corrupt-git-file/.git" ]]; then
        echo "  ERROR: corrupt-git-file/.git file missing"
        errors=$((errors + 1))
    fi
    
    # Fixture 5: empty-git-file
    if [[ ! -f "$FIXTURES_DIR/empty-git-file/.git" ]]; then
        echo "  ERROR: empty-git-file/.git file missing"
        errors=$((errors + 1))
    elif [[ -s "$FIXTURES_DIR/empty-git-file/.git" ]]; then
        local size=$(stat -f%z "$FIXTURES_DIR/empty-git-file/.git" 2>/dev/null || stat -c%s "$FIXTURES_DIR/empty-git-file/.git" 2>/dev/null)
        echo "  ERROR: empty-git-file/.git should be empty but has content (size: ${size} bytes)"
        errors=$((errors + 1))
    fi
    
    # Fixture 6: plain-dir
    if [[ ! -d "$FIXTURES_DIR/plain-dir" ]]; then
        echo "  ERROR: plain-dir directory missing"
        errors=$((errors + 1))
    fi
    if [[ ! -f "$FIXTURES_DIR/plain-dir/file.txt" ]]; then
        echo "  ERROR: plain-dir/file.txt missing"
        errors=$((errors + 1))
    fi
    if [[ -e "$FIXTURES_DIR/plain-dir/.git" ]]; then
        echo "  ERROR: plain-dir should not have .git"
        errors=$((errors + 1))
    fi
    
    # Fixture 7: relative-worktree
    if [[ ! -f "$FIXTURES_DIR/relative-worktree/.git" ]]; then
        echo "  ERROR: relative-worktree/.git file missing"
        errors=$((errors + 1))
    fi
    if [[ ! -d "$FIXTURES_DIR/relative-main/.git/worktrees/relative-wt" ]]; then
        echo "  ERROR: relative-main worktree metadata missing"
        errors=$((errors + 1))
    fi
    
    # Report results
    if [[ $errors -eq 0 ]]; then
        echo "  ✓ All fixtures validated successfully"
        return 0
    else
        echo "  ✗ Validation failed with $errors error(s)"
        return 1
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

echo ""
echo "All fixtures created in: $FIXTURES_DIR"
echo "Fixtures:"
ls -1 "$FIXTURES_DIR"

# Validate all fixtures were created correctly
validate_fixtures || {
    echo ""
    echo "ERROR: Fixture creation validation failed. Tests may produce false positives."
    echo "       Review the error messages above and re-run this script to recreate fixtures."
    exit 1
}
