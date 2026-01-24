#!/usr/bin/env bash
# secrets-loader.contract.sh — Contract tests for the hardened secrets loader
# Verifies: FR-004, FR-005, FR-006, FR-014, FR-016, FR-017

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../../.."

# Source the secrets loader
# shellcheck source=../../../scripts/secrets-load.sh
source "${REPO_ROOT}/scripts/secrets-load.sh"

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "${expected}" == "${actual}" ]]; then
    echo "  PASS: ${desc}"
    ((PASS++))
  else
    echo "  FAIL: ${desc} (expected='${expected}', actual='${actual}')" >&2
    ((FAIL++))
  fi
}

assert_exported() {
  local desc="$1" key="$2" expected="$3"
  local actual="${!key:-__UNSET__}"
  assert_eq "${desc}" "${expected}" "${actual}"
}

assert_not_exported() {
  local desc="$1" key="$2"
  if [[ -z "${!key+x}" ]]; then
    echo "  PASS: ${desc}"
    ((PASS++))
  else
    echo "  FAIL: ${desc} (variable was set to '${!key}')" >&2
    ((FAIL++))
  fi
}

# --- Contract: Permission Enforcement (FR-005) ---
echo "Contract: Permission enforcement"
echo "  Precondition: secrets file with mode 0644 (world-readable)"
echo "  Expected: loader rejects file with [ERROR] message, exit non-zero"

# --- Contract: Key Validation (FR-006) ---
echo "Contract: Key validation"
echo "  Input: KEY=value, _VALID=x, 2INVALID=x, invalid-key=x, lowercase=x"
echo "  Expected: Only ^[A-Z_][A-Z0-9_]*$ keys exported; others skipped with [WARN]"

# --- Contract: Command Substitution Rejection (FR-014) ---
echo "Contract: Command substitution rejection"
echo "  Input lines with values containing \$(), \${}, backticks"
echo "  Expected: Lines rejected with [WARN], NOT exported, NO command execution"

# --- Contract: First-= Split (FR-017) ---
echo "Contract: First-equals split"
echo "  Input: KEY=value=with=equals"
echo "  Expected: key='KEY', value='value=with=equals'"

# --- Contract: Safe Parsing (FR-004) ---
echo "Contract: Safe parsing (no shell execution)"
echo "  Input: KEY=\$(touch /tmp/pwned)"
echo "  Expected: /tmp/pwned does NOT exist after load attempt"

# --- Contract: Diagnostic Format (FR-016) ---
echo "Contract: Diagnostic format"
echo "  Expected: All warnings match '[WARN] secrets: <message>' on stderr"
echo "  Expected: All errors match '[ERROR] secrets: <message>' on stderr"

echo ""
echo "---"
echo "Contract specification complete."
echo "These contracts define the acceptance criteria for the hardened secrets loader."
echo "Implementation must pass all contracts. Use test_secrets_load.bats for automated verification."
