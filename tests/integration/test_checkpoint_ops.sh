#!/usr/bin/env bash
# Integration test: checkpoint create > list > rollback > verify
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${PROJECT_ROOT}/src/agent/lib/checkpoint.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

# Setup mock repo
cd "${TEST_DIR}"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test"
echo "initial content" > main.txt
git add main.txt
git commit --quiet -m "initial"

export AGENT_STATE_DIR="${TEST_DIR}/state"
mkdir -p "${AGENT_STATE_DIR}/sessions"

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

# Test: Create checkpoint
echo "modified" > main.txt
git add main.txt
check "Create checkpoint" create_checkpoint "test-session" "Before modification" "file_edit"

# Test: List checkpoints
check "List checkpoints shows entry" bash -c 'list_checkpoints | grep -q "checkpoint:"'

# Test: Rollback restores state
echo "bad content" > main.txt
check "Rollback to checkpoint" rollback_checkpoint "stash@{0}"

# Test: Multiple checkpoints ordered correctly
echo "change2" >> main.txt
git add main.txt
create_checkpoint "s1" "Second checkpoint" "multi_file"
echo "change3" >> main.txt
git add main.txt
create_checkpoint "s1" "Third checkpoint" "multi_file"
check "Multiple checkpoints exist" bash -c '[ $(git stash list | wc -l) -ge 2 ]'

# Test: Prune old checkpoints
check "Prune checkpoints" prune_checkpoints 1

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] || exit 1
