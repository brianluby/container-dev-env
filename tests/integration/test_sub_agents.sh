#!/usr/bin/env bash
# Integration test: sub-agent delegation with non-overlapping file scopes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${PROJECT_ROOT}/src/agent/lib/log.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

export AGENT_STATE_DIR="${TEST_DIR}/state"
mkdir -p "${AGENT_STATE_DIR}/logs"

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

SESSION_ID="sub-agent-test"

# Test: Log sub-agent spawn event
log_action "${SESSION_ID}" "sub_agent_spawn" "sub-001" "Backend work: src/api/" "success"
check "Sub-agent spawn logged" bash -c "grep -q 'sub_agent_spawn' '${AGENT_STATE_DIR}/logs/${SESSION_ID}.jsonl'"

# Test: Log sub-agent complete event
log_action "${SESSION_ID}" "sub_agent_complete" "sub-001" "Completed backend API" "success"
check "Sub-agent complete logged" bash -c "grep -q 'sub_agent_complete' '${AGENT_STATE_DIR}/logs/${SESSION_ID}.jsonl'"

# Test: Multiple sub-agents logged independently
log_action "${SESSION_ID}" "sub_agent_spawn" "sub-002" "Frontend work: src/ui/" "success"
log_action "${SESSION_ID}" "sub_agent_complete" "sub-002" "Completed frontend UI" "success"
check "Multiple sub-agents in log" bash -c "grep -c 'sub_agent' '${AGENT_STATE_DIR}/logs/${SESSION_ID}.jsonl' | grep -q 4"

# Test: Non-overlapping file scopes are distinct
SCOPE_1=$(grep "sub-001" "${AGENT_STATE_DIR}/logs/${SESSION_ID}.jsonl" | head -1 | jq -r '.details')
SCOPE_2=$(grep "sub-002" "${AGENT_STATE_DIR}/logs/${SESSION_ID}.jsonl" | head -1 | jq -r '.details')
check "Sub-agent scopes are distinct" test "${SCOPE_1}" != "${SCOPE_2}"

# Test: Action log entries have valid JSON format
check "All log entries are valid JSONL" bash -c "while IFS= read -r line; do echo \"\${line}\" | jq empty || exit 1; done < '${AGENT_STATE_DIR}/logs/${SESSION_ID}.jsonl'"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] || exit 1
