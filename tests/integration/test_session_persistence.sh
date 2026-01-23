#!/usr/bin/env bash
# Integration test: session create > terminate > resume > verify context
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${PROJECT_ROOT}/src/agent/lib/session.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

export AGENT_STATE_DIR="${TEST_DIR}/state"
mkdir -p "${AGENT_STATE_DIR}/sessions" "${AGENT_STATE_DIR}/logs"
cd "${TEST_DIR}"

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

# Test: Create session
SESSION_ID=$(create_session "opencode" "Refactor auth module" "hybrid")
check "Session created with ID" test -n "${SESSION_ID}"
check "Session file exists" test -f "${AGENT_STATE_DIR}/sessions/${SESSION_ID}.json"

# Test: Session has correct initial state
check "Session status is active" bash -c "jq -r '.status' '${AGENT_STATE_DIR}/sessions/${SESSION_ID}.json' | grep -q 'active'"
check "Session has task description" bash -c "jq -r '.task_description' '${AGENT_STATE_DIR}/sessions/${SESSION_ID}.json' | grep -q 'Refactor'"

# Test: Simulate interruption (pause)
update_session_status "${SESSION_ID}" "paused"
check "Session paused successfully" bash -c "jq -r '.status' '${AGENT_STATE_DIR}/sessions/${SESSION_ID}.json' | grep -q 'paused'"

# Test: Resume (find latest paused session)
FOUND_ID=$(find_latest_session "paused")
check "Found paused session for resume" test "${FOUND_ID}" = "${SESSION_ID}"

# Test: Resume sets status back to active
update_session_status "${SESSION_ID}" "active"
check "Session resumed to active" bash -c "jq -r '.status' '${AGENT_STATE_DIR}/sessions/${SESSION_ID}.json' | grep -q 'active'"

# Test: Context preserved after resume
TASK=$(jq -r '.task_description' "${AGENT_STATE_DIR}/sessions/${SESSION_ID}.json")
check "Task description preserved" test "${TASK}" = "Refactor auth module"

# Test: Complete session
update_session_status "${SESSION_ID}" "completed"
check "Session completed with ended_at" bash -c "jq -r '.ended_at' '${AGENT_STATE_DIR}/sessions/${SESSION_ID}.json' | grep -qv 'null'"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] || exit 1
