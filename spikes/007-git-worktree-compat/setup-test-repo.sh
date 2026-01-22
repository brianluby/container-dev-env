#!/bin/bash
# Setup script for Git Worktree Compatibility Testing
# Creates a test repository with multiple worktrees for spike testing

set -e

SPIKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE="$SPIKE_DIR/test-repos"

echo "=== Git Worktree Test Repository Setup ==="
echo "Base directory: $TEST_BASE"
echo ""

# Clean up any previous test repos
if [ -d "$TEST_BASE" ]; then
    echo "Cleaning up previous test repos..."
    rm -rf "$TEST_BASE"
fi

mkdir -p "$TEST_BASE"

# Create main repository
echo "--- Creating main repository ---"
MAIN_REPO="$TEST_BASE/main-repo"
mkdir -p "$MAIN_REPO"
cd "$MAIN_REPO"

git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create initial content
cat > README.md << 'EOF'
# Test Repository

This is a test repository for git worktree compatibility testing.

## Purpose

Test that AI coding agents work correctly in worktree-based workflows.
EOF

mkdir -p src

cat > src/main.py << 'PYEOF'
#!/usr/bin/env python3
"""Main module for test application."""


def greet(name: str) -> str:
    """Return a greeting message."""
    return f"Hello, {name}!"


def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b


if __name__ == "__main__":
    print(greet("World"))
PYEOF

cat > src/utils.py << 'PYEOF'
"""Utility functions."""


def format_number(n: int) -> str:
    """Format a number with commas."""
    return f"{n:,}"


def is_even(n: int) -> bool:
    """Check if a number is even."""
    return n % 2 == 0
PYEOF

cat > .gitignore << 'EOF'
__pycache__/
*.pyc
.env
.venv/
EOF

git add -A
git commit -m "Initial commit: project setup"

# Create feature branch with changes
git checkout -b feature/add-multiply
cat >> src/main.py << 'PYEOF'


def multiply(a: int, b: int) -> int:
    """Multiply two numbers."""
    return a * b
PYEOF
git add -A
git commit -m "feat: add multiply function"

# Create another feature branch
git checkout main
git checkout -b feature/add-divide
cat >> src/main.py << 'PYEOF'


def divide(a: int, b: int) -> float:
    """Divide two numbers."""
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
PYEOF
git add -A
git commit -m "feat: add divide function"

# Go back to main
git checkout main

echo ""
echo "--- Creating worktrees ---"

# Create worktree directory
WORKTREE_DIR="$TEST_BASE/worktrees"
mkdir -p "$WORKTREE_DIR"

# Create worktree for feature/add-multiply
echo "Creating worktree: feature-multiply"
git worktree add "$WORKTREE_DIR/feature-multiply" feature/add-multiply

# Create worktree for feature/add-divide
echo "Creating worktree: feature-divide"
git worktree add "$WORKTREE_DIR/feature-divide" feature/add-divide

# Create worktree with detached HEAD (edge case)
echo "Creating worktree: detached-head"
FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD)
git worktree add --detach "$WORKTREE_DIR/detached-head" "$FIRST_COMMIT"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Repository structure:"
echo "  Main repo:        $MAIN_REPO"
echo "  Worktrees:"
echo "    feature-multiply: $WORKTREE_DIR/feature-multiply (branch: feature/add-multiply)"
echo "    feature-divide:   $WORKTREE_DIR/feature-divide (branch: feature/add-divide)"
echo "    detached-head:    $WORKTREE_DIR/detached-head (detached HEAD)"
echo ""
echo "Verification:"
cd "$MAIN_REPO"
echo "Main repo worktree list:"
git worktree list
echo ""

# Verify .git structure
echo "Checking .git structure:"
echo "  Main repo .git: $(file "$MAIN_REPO/.git")"
echo "  Worktree .git:  $(file "$WORKTREE_DIR/feature-multiply/.git")"
echo ""

# Show content of worktree .git file
echo "Content of worktree .git file:"
cat "$WORKTREE_DIR/feature-multiply/.git"
echo ""
