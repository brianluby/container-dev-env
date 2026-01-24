#!/usr/bin/env bash
# agent-execution.contract.sh — Contract tests for safe agent command execution
# Verifies: FR-001, FR-002, FR-007, FR-008

set -euo pipefail

echo "=== Agent Execution Contracts ==="
echo ""

# --- Contract: No eval (FR-001) ---
echo "Contract: Command execution without eval"
echo "  Precondition: build_backend_command() returns an array, not a string"
echo "  Input: task_description containing shell metacharacters (;, |, &&, \$(), backticks)"
echo "  Expected: metacharacters passed literally as a single argument to the backend binary"
echo "  Expected: no shell interpretation of user-provided text"
echo "  Verification: canary-based (injected touch command must NOT create file)"
echo ""

# --- Contract: JSON session creation (FR-002) ---
echo "Contract: Safe JSON session creation"
echo "  Precondition: create_session() uses jq --arg for all user-controlled fields"
echo "  Input: task_description = 'Task with \"quotes\" and \\backslashes\\n and newlines'"
echo "  Expected: resulting session.json is valid (jq empty passes)"
echo "  Expected: task_description field contains literal special chars properly escaped"
echo ""

# --- Contract: JSON log writing (FR-002) ---
echo "Contract: Safe JSON log entry"
echo "  Precondition: log_action() uses jq --arg for target and details fields"
echo "  Input: target = '/path/with \"special\" chars', details = 'line1\\nline2'"
echo "  Expected: JSONL entry is valid JSON (jq -e . passes)"
echo "  Expected: no raw newlines break JSONL format (one JSON object per line)"
echo ""

# --- Contract: Localhost binding (FR-007) ---
echo "Contract: Server mode binds to localhost only"
echo "  Precondition: agent --serve starts the server"
echo "  Expected: listening socket bound to 127.0.0.1:4096 (not 0.0.0.0:4096)"
echo "  Verification: ss -tlnp or netstat shows 127.0.0.1 only"
echo ""

# --- Contract: Authentication required (FR-008) ---
echo "Contract: Server mode requires authentication"
echo "  Precondition: OPENCODE_SERVER_PASSWORD is unset or empty"
echo "  Input: agent --serve"
echo "  Expected: exit non-zero with [ERROR] message about missing authentication"
echo "  Expected: server does NOT start"
echo ""

echo "---"
echo "Contract specification complete."
echo "Implementation must satisfy all contracts. Use test_agent_injection.bats for automated verification."
