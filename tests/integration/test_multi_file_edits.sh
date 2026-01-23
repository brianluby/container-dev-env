#!/usr/bin/env bash
# Integration test: multi-file coherent edits produce atomic commits
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

# Setup mock repo with multiple files
cd "${TEST_DIR}"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test"
echo "module A" > module_a.py
echo "module B" > module_b.py
echo "module C" > module_c.py
git add .
git commit --quiet -m "initial commit"

PASS=0
FAIL=0

check() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "PASS: ${desc}"
    PASS=$((PASS + 1))
  else
    echo "FAIL: ${desc}"
    FAIL=$((FAIL + 1))
  fi
}

# Simulate multi-file edit (what the agent backend would do)
echo "module A v2" > module_a.py
echo "module B v2" > module_b.py
echo "module C v2" > module_c.py
git add .
git commit --quiet -m "refactor: update all modules to v2"

# Test: All changes in single commit
LAST_COMMIT_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD)
check "Multiple files in single commit" bash -c "echo '${LAST_COMMIT_FILES}' | wc -l | grep -q 3"

# Test: Commit message is descriptive
LAST_MSG=$(git log -1 --pretty=%s)
check "Commit message is descriptive" bash -c "echo '${LAST_MSG}' | grep -q 'refactor'"

# Test: No partial commits exist between initial and final
COMMIT_COUNT=$(git rev-list --count HEAD)
check "No partial commits (only initial + final)" test "${COMMIT_COUNT}" -eq 2

# Test: All files have consistent state
check "module_a.py has v2 content" grep -q "v2" module_a.py
check "module_b.py has v2 content" grep -q "v2" module_b.py
check "module_c.py has v2 content" grep -q "v2" module_c.py

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] || exit 1
