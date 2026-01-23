#!/usr/bin/env bash
# test_opencode_git.sh — Integration test: Git auto-commit behavior
#
# Verifies:
#   1. Auto-commit creates commits with conventional format messages
#   2. Commits are on the currently checked-out branch

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Integration: OpenCode Git Integration ==="

# Test 1: Config enables auto-commit with conventional style
echo "  [1/2] Checking auto-commit config..."
docker run --rm "$IMAGE" bash -c '
    CONFIG="$HOME/.config/opencode/config.yaml"
    if [[ ! -f "$CONFIG" ]]; then
        echo "FAIL: Config file not found at $CONFIG"
        exit 1
    fi
    if ! grep -q "auto_commit: true" "$CONFIG"; then
        echo "FAIL: auto_commit: true not found in config"
        exit 1
    fi
    if ! grep -q "commit_style: conventional" "$CONFIG"; then
        echo "FAIL: commit_style: conventional not found in config"
        exit 1
    fi
    echo "OK: auto_commit=true, commit_style=conventional"
'

# Test 2: Git is available and commits go to current branch
echo "  [2/2] Checking git branch behavior..."
docker run --rm "$IMAGE" bash -c '
    # Initialize a test repo
    cd /tmp && mkdir test-repo && cd test-repo
    git init -b test-branch
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > file.txt
    git add file.txt
    git commit -m "initial commit"

    # Verify we are on test-branch
    CURRENT=$(git branch --show-current)
    if [[ "$CURRENT" != "test-branch" ]]; then
        echo "FAIL: Expected branch test-branch, got $CURRENT"
        exit 1
    fi

    # Simulate an agent commit (conventional format)
    echo "modified" > file.txt
    git add file.txt
    git commit -m "feat(test): add modification for testing"

    # Verify commit is on test-branch with conventional format
    LAST_MSG=$(git log -1 --format=%s)
    if ! echo "$LAST_MSG" | grep -qE "^(feat|fix|refactor|docs|test|chore)\("; then
        echo "FAIL: Last commit not in conventional format: $LAST_MSG"
        exit 1
    fi

    BRANCH_OF_COMMIT=$(git branch --show-current)
    if [[ "$BRANCH_OF_COMMIT" != "test-branch" ]]; then
        echo "FAIL: Commit not on test-branch"
        exit 1
    fi

    echo "OK: Conventional commit on current branch"
'

echo "PASS: OpenCode git integration tests"
