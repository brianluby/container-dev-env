#!/bin/bash
# Test script for Git Worktree Compatibility
# Tests AI tools in worktree environments

set -e

SPIKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE="$SPIKE_DIR/test-repos"
RESULTS_DIR="$SPIKE_DIR/results"
WORKTREE_DIR="$TEST_BASE/worktrees"
MAIN_REPO="$TEST_BASE/main-repo"

mkdir -p "$RESULTS_DIR"

echo "=== Git Worktree Compatibility Tests ==="
echo "Results directory: $RESULTS_DIR"
echo ""

# Initialize results file
RESULTS_FILE="$RESULTS_DIR/compatibility-matrix.md"
cat > "$RESULTS_FILE" << 'EOF'
# Git Worktree Compatibility Test Results

Generated: $(date)

## Test Environment

| Component | Version |
|-----------|---------|
EOF

# Add version info
echo "| Git | $(git --version | cut -d' ' -f3) |" >> "$RESULTS_FILE"
if command -v claude &> /dev/null; then
    echo "| Claude Code | $(claude --version 2>&1 | head -1) |" >> "$RESULTS_FILE"
fi
if command -v aider &> /dev/null; then
    echo "| Aider | $(aider --version 2>&1 | head -1) |" >> "$RESULTS_FILE"
fi

cat >> "$RESULTS_FILE" << 'EOF'

## Test Scenarios

### Scenario 1: Repository Detection in Worktree

Tests whether the tool correctly identifies a worktree as a valid git repository.

EOF

# Function to test git detection
test_git_detection() {
    local tool_name="$1"
    local test_dir="$2"
    local label="$3"

    echo "Testing $tool_name in $label..."
    cd "$test_dir"

    local result_file="$RESULTS_DIR/${tool_name}-${label//\//-}.txt"

    echo "=== $tool_name in $label ===" > "$result_file"
    echo "Directory: $test_dir" >> "$result_file"
    echo "Date: $(date)" >> "$result_file"
    echo "" >> "$result_file"

    # Basic git commands that tools should handle
    echo "--- Git Detection Tests ---" >> "$result_file"
    echo "git rev-parse --git-dir: $(git rev-parse --git-dir 2>&1)" >> "$result_file"
    echo "git rev-parse --show-toplevel: $(git rev-parse --show-toplevel 2>&1)" >> "$result_file"
    echo "git rev-parse --is-inside-work-tree: $(git rev-parse --is-inside-work-tree 2>&1)" >> "$result_file"
    echo "git branch --show-current: $(git branch --show-current 2>&1)" >> "$result_file"
    echo "git status (short): $(git status -s 2>&1 | head -5)" >> "$result_file"
    echo "" >> "$result_file"

    # Check .git type
    if [ -f ".git" ]; then
        echo ".git is a FILE (worktree)" >> "$result_file"
        echo ".git contents: $(cat .git)" >> "$result_file"
    elif [ -d ".git" ]; then
        echo ".git is a DIRECTORY (main repo)" >> "$result_file"
    else
        echo ".git NOT FOUND" >> "$result_file"
    fi
    echo "" >> "$result_file"

    echo "  Saved to: $result_file"
}

# Run git detection tests
echo ""
echo "--- Running Git Detection Tests ---"

# Test main repo
test_git_detection "git" "$MAIN_REPO" "main-repo"

# Test worktrees
test_git_detection "git" "$WORKTREE_DIR/feature-multiply" "worktree-multiply"
test_git_detection "git" "$WORKTREE_DIR/feature-divide" "worktree-divide"
test_git_detection "git" "$WORKTREE_DIR/detached-head" "worktree-detached"

echo ""
echo "--- Tool-Specific Tests ---"

# Test Claude Code detection (non-interactive)
if command -v claude &> /dev/null; then
    echo ""
    echo "Testing Claude Code..."

    for location in "main-repo:$MAIN_REPO" "worktree:$WORKTREE_DIR/feature-multiply"; do
        label="${location%%:*}"
        dir="${location#*:}"

        echo "  Location: $label"
        cd "$dir"

        result_file="$RESULTS_DIR/claude-code-$label.txt"
        echo "=== Claude Code in $label ===" > "$result_file"
        echo "Directory: $dir" >> "$result_file"
        echo "" >> "$result_file"

        # Test claude's ability to detect git repo (using print mode)
        echo "Testing: claude -p 'What git branch am I on?'" >> "$result_file"
        timeout 30 claude -p "What git branch am I on? Just tell me the branch name, nothing else." >> "$result_file" 2>&1 || echo "TIMEOUT or ERROR" >> "$result_file"
        echo "" >> "$result_file"

        echo "  Saved to: $result_file"
    done
fi

# Test Aider detection (non-interactive)
if command -v aider &> /dev/null; then
    echo ""
    echo "Testing Aider..."

    for location in "main-repo:$MAIN_REPO" "worktree:$WORKTREE_DIR/feature-multiply"; do
        label="${location%%:*}"
        dir="${location#*:}"

        echo "  Location: $label"
        cd "$dir"

        result_file="$RESULTS_DIR/aider-$label.txt"
        echo "=== Aider in $label ===" > "$result_file"
        echo "Directory: $dir" >> "$result_file"
        echo "" >> "$result_file"

        # Test aider's git detection (--show-repo-map shows if it detects repo)
        echo "Testing: aider --just-check-update (validates environment)" >> "$result_file"
        timeout 10 aider --just-check-update >> "$result_file" 2>&1 || echo "TIMEOUT or ERROR" >> "$result_file"
        echo "" >> "$result_file"

        # Try to get repo map (shows file detection)
        echo "Testing: aider --show-repo-map" >> "$result_file"
        timeout 30 aider --show-repo-map >> "$result_file" 2>&1 || echo "TIMEOUT or ERROR" >> "$result_file"
        echo "" >> "$result_file"

        echo "  Saved to: $result_file"
    done
fi

echo ""
echo "=== Tests Complete ==="
echo ""
echo "Results saved to: $RESULTS_DIR/"
ls -la "$RESULTS_DIR/"
