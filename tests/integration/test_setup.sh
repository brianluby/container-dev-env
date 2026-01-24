#!/usr/bin/env bash
# test_setup.sh — Integration tests for setup-voice-input.sh
# Verifies that the setup script creates expected configuration files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETUP_SCRIPT="${PROJECT_ROOT}/src/scripts/setup-voice-input.sh"

# Use a temporary directory to avoid modifying real config
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
# Skip prerequisite checks (tool installation, macOS checks) in tests
export VOICE_INPUT_SKIP_PREREQS=1

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ─── Test Helpers ─────────────────────────────────────────────────────────────

cleanup() {
  rm -rf "$TEST_HOME"
}
trap cleanup EXIT

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

echo "=== Integration Tests: setup-voice-input.sh ==="
echo ""

# Test: Setup script exists and is executable
run_test
if [[ -x "$SETUP_SCRIPT" ]]; then
  pass "Setup script is executable"
else
  fail "Setup script is not executable" "$SETUP_SCRIPT"
fi

# Test: --help flag exits 0 and shows usage
run_test
if help_output=$("$SETUP_SCRIPT" --help 2>&1); then
  if echo "$help_output" | grep -qi "usage"; then
    pass "--help shows usage information"
  else
    fail "--help output does not contain 'usage'" "$help_output"
  fi
else
  fail "--help exited with non-zero status"
fi

# Test: --dry-run creates no files
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
"$SETUP_SCRIPT" --dry-run 2>/dev/null || true
if [[ ! -d "${TEST_HOME}/.config/voice-input" ]]; then
  pass "--dry-run does not create config directory"
else
  fail "--dry-run created config directory"
fi

# Test: Setup creates settings.yaml
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
if "$SETUP_SCRIPT" --tool superwhisper 2>/dev/null; then
  if [[ -f "${TEST_HOME}/.config/voice-input/settings.yaml" ]]; then
    pass "Setup creates settings.yaml"
  else
    fail "Setup did not create settings.yaml"
  fi
else
  fail "Setup script exited with error"
fi

# Test: Setup creates vocabulary.yaml
run_test
if [[ -f "${TEST_HOME}/.config/voice-input/vocabulary.yaml" ]]; then
  pass "Setup creates vocabulary.yaml"
else
  fail "Setup did not create vocabulary.yaml"
fi

# Test: Setup creates ai-cleanup-prompt.txt
run_test
if [[ -f "${TEST_HOME}/.config/voice-input/ai-cleanup-prompt.txt" ]]; then
  pass "Setup creates ai-cleanup-prompt.txt"
else
  fail "Setup did not create ai-cleanup-prompt.txt"
fi

# Test: settings.yaml contains required fields
run_test
local_settings="${TEST_HOME}/.config/voice-input/settings.yaml"
if [[ -f "$local_settings" ]]; then
  missing_fields=""
  for field in tool whisper_model activation_shortcut activation_mode cleanup_tier silence_timeout_ms language; do
    if ! grep -q "^${field}:" "$local_settings"; then
      missing_fields="${missing_fields} ${field}"
    fi
  done
  if [[ -z "$missing_fields" ]]; then
    pass "settings.yaml contains all required fields"
  else
    fail "settings.yaml missing fields:$missing_fields"
  fi
else
  fail "settings.yaml not found for field check"
fi

# Test: settings.yaml has correct defaults
run_test
if [[ -f "$local_settings" ]]; then
  errors=""
  if ! grep -q "^tool: superwhisper" "$local_settings"; then
    errors="${errors} tool!=superwhisper"
  fi
  if ! grep -q "^whisper_model: large-v3" "$local_settings"; then
    errors="${errors} model!=large-v3"
  fi
  if ! grep -q "^activation_mode: push_to_talk" "$local_settings"; then
    errors="${errors} mode!=push_to_talk"
  fi
  if ! grep -q "^cleanup_tier: rules" "$local_settings"; then
    errors="${errors} tier!=rules"
  fi
  if [[ -z "$errors" ]]; then
    pass "settings.yaml has correct default values"
  else
    fail "settings.yaml wrong defaults:$errors"
  fi
else
  fail "settings.yaml not found for defaults check"
fi

# Test: Invalid tool flag exits with error
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
if "$SETUP_SCRIPT" --tool invalid_tool 2>/dev/null; then
  fail "Setup should fail with invalid tool"
else
  pass "Setup rejects invalid --tool value"
fi

# Test: Invalid model flag exits with error
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
if "$SETUP_SCRIPT" --model invalid_model 2>/dev/null; then
  fail "Setup should fail with invalid model"
else
  pass "Setup rejects invalid --model value"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="

if ((TESTS_FAILED > 0)); then
  exit 1
fi
exit 0
