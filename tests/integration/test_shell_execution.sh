#!/usr/bin/env bash
# Integration test: shell command execution with timeout and dangerous patterns
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${PROJECT_ROOT}/src/agent/lib/config.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

export HOME="${TEST_DIR}/home"
mkdir -p "${HOME}/.config/agent"
export WORKSPACE="${TEST_DIR}/workspace"
mkdir -p "${WORKSPACE}"
export AGENT_STATE_DIR="${TEST_DIR}/state"
mkdir -p "${AGENT_STATE_DIR}"

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

# Load config with default dangerous patterns
load_config "${WORKSPACE}"

# Helper: check if command matches any dangerous pattern
is_dangerous() {
  local cmd="$1"
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "${cmd}" == *"${pattern}"* ]]; then
      return 0
    fi
  done
  return 1
}

# Test: Safe command is not flagged
check "cargo test is safe" bash -c '! is_dangerous "cargo test"'
check "npm install is safe" bash -c '! is_dangerous "npm install"'
check "git status is safe" bash -c '! is_dangerous "git status"'

# Test: Dangerous patterns are detected
check "rm -rf is dangerous" is_dangerous "rm -rf /tmp/important"
check "git push --force is dangerous" is_dangerous "git push --force origin main"
check "git reset --hard is dangerous" is_dangerous "git reset --hard HEAD~5"
check "chmod 777 is dangerous" is_dangerous "chmod 777 /etc/shadow"

# Test: Command timeout works (using timeout utility)
check "Command with timeout completes normally" timeout 5 echo "quick command"

# Test: Command exceeding timeout is terminated
if timeout 1 sleep 10 2>/dev/null; then
  echo "FAIL: Timeout did not kill long-running command"
  FAIL=$((FAIL + 1))
else
  echo "PASS: Timeout terminates long-running command"
  PASS=$((PASS + 1))
fi

# Test: Dangerous pattern in auto mode still detectable
export AGENT_MODE="auto"
load_config "${WORKSPACE}"
check "Dangerous patterns still loaded in auto mode" is_dangerous "rm -rf /"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] || exit 1
