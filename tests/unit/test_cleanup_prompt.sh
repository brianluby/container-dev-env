#!/usr/bin/env bash
# test_cleanup_prompt.sh — Unit tests for AI cleanup prompt (US4)
# Verifies the cleanup prompt template contains required content.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROMPT_FILE="${PROJECT_ROOT}/src/config/ai-cleanup-prompt.txt"

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

# ─── Tests ────────────────────────────────────────────────────────────────────

echo "=== Unit Tests: AI Cleanup Prompt ==="
echo ""

# Test: Prompt file exists
run_test
if [[ -f "$PROMPT_FILE" ]]; then
  pass "AI cleanup prompt file exists"
else
  fail "AI cleanup prompt file not found" "$PROMPT_FILE"
  echo ""
  echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="
  exit 1
fi

# Test: Contains role instruction
run_test
if grep -q "transcription cleanup" "$PROMPT_FILE"; then
  pass "Prompt contains role instruction (transcription cleanup)"
else
  fail "Prompt missing role instruction"
fi

# Test: Contains punctuation rule
run_test
if grep -qi "punctuation" "$PROMPT_FILE"; then
  pass "Prompt contains punctuation formatting rule"
else
  fail "Prompt missing punctuation rule"
fi

# Test: Contains camelCase formatting rule
run_test
if grep -q "camelCase" "$PROMPT_FILE"; then
  pass "Prompt contains camelCase formatting rule"
else
  fail "Prompt missing camelCase rule"
fi

# Test: Contains technical acronym rule
run_test
if grep -q "API" "$PROMPT_FILE" && grep -q "JSON" "$PROMPT_FILE"; then
  pass "Prompt contains technical acronym rules (API, JSON)"
else
  fail "Prompt missing technical acronym rules"
fi

# Test: Contains preserve intent instruction
run_test
if grep -qi "intent" "$PROMPT_FILE"; then
  pass "Prompt instructs to preserve developer intent"
else
  fail "Prompt missing intent preservation instruction"
fi

# Test: Contains output-only instruction (no explanations)
run_test
if grep -qi "no explanation" "$PROMPT_FILE" || grep -qi "only the cleaned text" "$PROMPT_FILE"; then
  pass "Prompt instructs to output only cleaned text"
else
  fail "Prompt missing output-only instruction"
fi

# Test: Contains at least 2 examples
run_test
example_count=$(grep -c "^- Input:" "$PROMPT_FILE" || true)
if ((example_count >= 2)); then
  pass "Prompt contains $example_count examples (≥2 required)"
else
  fail "Prompt has only $example_count examples (2+ required)"
fi

# Test: Examples show before/after pairs
run_test
input_count=$(grep -c "Input:" "$PROMPT_FILE" || true)
output_count=$(grep -c "Output:" "$PROMPT_FILE" || true)
if ((input_count == output_count && input_count >= 2)); then
  pass "Examples have matching Input/Output pairs"
else
  fail "Examples have mismatched Input/Output pairs ($input_count inputs, $output_count outputs)"
fi

# Test: Contains code-related formatting (PascalCase, snake_case)
run_test
if grep -q "PascalCase" "$PROMPT_FILE" || grep -q "snake_case" "$PROMPT_FILE"; then
  pass "Prompt contains code convention formatting rules"
else
  fail "Prompt missing code convention rules"
fi

# Test: Contains file path handling rule
run_test
if grep -qi "file path" "$PROMPT_FILE" || grep -qi "slashes" "$PROMPT_FILE"; then
  pass "Prompt contains file path handling rule"
else
  fail "Prompt missing file path rule"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="

if ((TESTS_FAILED > 0)); then
  exit 1
fi
exit 0
