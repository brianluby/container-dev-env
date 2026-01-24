#!/usr/bin/env bash
# test_clipboard.sh — Integration tests for clipboard integration (US5)
# Verifies clipboard roundtrip with special characters.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  printf "  ✓ %s\n" "$1"
}

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf "  ✗ %s\n" "$1" >&2
  if [[ -n "${2:-}" ]]; then
    printf "    %s\n" "$2" >&2
  fi
}

run_test() {
  TESTS_RUN=$((TESTS_RUN + 1))
}

# Check if pbcopy/pbpaste are available (macOS only)
if ! command -v pbcopy &>/dev/null || ! command -v pbpaste &>/dev/null; then
  echo "=== Integration Tests: Clipboard (US5) ==="
  echo ""
  echo "SKIPPED: pbcopy/pbpaste not available (requires macOS)"
  exit 0
fi

# Save current clipboard content
ORIGINAL_CLIPBOARD=$(pbpaste 2>/dev/null || echo "")

cleanup() {
  # Restore original clipboard
  printf "%s" "$ORIGINAL_CLIPBOARD" | pbcopy 2>/dev/null || true
}
trap cleanup EXIT

# ─── Tests ────────────────────────────────────────────────────────────────────

echo "=== Integration Tests: Clipboard (US5) ==="
echo ""

# Test: Basic text roundtrip
run_test
test_text="Create a function called getUserById that takes a userId parameter"
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Basic text clipboard roundtrip"
else
  fail "Basic text roundtrip failed" "Expected: $test_text, Got: $result"
fi

# Test: Backticks roundtrip
run_test
test_text='Use `docker run` and `kubectl apply` commands'
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Backticks clipboard roundtrip"
else
  fail "Backticks roundtrip failed"
fi

# Test: Single quotes roundtrip
run_test
test_text="Set the value to 'hello world' in the config"
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Single quotes clipboard roundtrip"
else
  fail "Single quotes roundtrip failed"
fi

# Test: Double quotes roundtrip
run_test
test_text='Set the value to "hello world" in the config'
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Double quotes clipboard roundtrip"
else
  fail "Double quotes roundtrip failed"
fi

# Test: Brackets and braces roundtrip
run_test
test_text='Create an array [1, 2, 3] and object {key: "value"}'
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Brackets and braces clipboard roundtrip"
else
  fail "Brackets/braces roundtrip failed"
fi

# Test: File paths roundtrip
run_test
test_text='Edit the file at /src/components/Header.tsx and /api/routes/users.ts'
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "File paths clipboard roundtrip"
else
  fail "File paths roundtrip failed"
fi

# Test: Multi-line text roundtrip
run_test
test_text="Line 1: Create a new endpoint
Line 2: Add validation middleware
Line 3: Return JSON response"
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Multi-line text clipboard roundtrip"
else
  fail "Multi-line roundtrip failed"
fi

# Test: Special characters (dollar sign, ampersand, pipe)
run_test
test_text='Use $HOME variable and cmd1 && cmd2 | grep pattern'
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Special characters ($ && |) clipboard roundtrip"
else
  fail "Special characters roundtrip failed"
fi

# Test: Unicode characters
run_test
test_text='Add the arrow → function and check ✓ mark'
printf "%s" "$test_text" | pbcopy
result=$(pbpaste)
if [[ "$result" == "$test_text" ]]; then
  pass "Unicode characters clipboard roundtrip"
else
  fail "Unicode roundtrip failed"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="

if ((TESTS_FAILED > 0)); then
  exit 1
fi
exit 0
