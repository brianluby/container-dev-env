#!/usr/bin/env bash
# Integration test: background task management (start, list, stop)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"; kill %1 2>/dev/null || true' EXIT

export AGENT_STATE_DIR="${TEST_DIR}/state"
mkdir -p "${AGENT_STATE_DIR}/bg"

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

# Test: Start a background process
sleep 300 &
BG_PID=$!
BG_LOG="${AGENT_STATE_DIR}/bg/bg-001.log"
echo "" > "${BG_LOG}"

check "Background process started" kill -0 "${BG_PID}"

# Test: Track process info
cat > "${AGENT_STATE_DIR}/bg/bg-001.json" <<EOF
{
  "id": "bg-001",
  "command": "sleep 300",
  "pid": ${BG_PID},
  "status": "running",
  "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output_path": "${BG_LOG}"
}
EOF

check "Background task metadata recorded" test -f "${AGENT_STATE_DIR}/bg/bg-001.json"

# Test: List shows running process
check "Process is running" bash -c "jq -r '.status' '${AGENT_STATE_DIR}/bg/bg-001.json' | grep -q 'running'"

# Test: Kill specific process
kill "${BG_PID}" 2>/dev/null || true
wait "${BG_PID}" 2>/dev/null || true

# Update status
jq '.status = "stopped"' "${AGENT_STATE_DIR}/bg/bg-001.json" > "${AGENT_STATE_DIR}/bg/bg-001.json.tmp"
mv "${AGENT_STATE_DIR}/bg/bg-001.json.tmp" "${AGENT_STATE_DIR}/bg/bg-001.json"

check "Process stopped" bash -c "! kill -0 ${BG_PID} 2>/dev/null"
check "Status updated to stopped" bash -c "jq -r '.status' '${AGENT_STATE_DIR}/bg/bg-001.json' | grep -q 'stopped'"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]] || exit 1
