#!/usr/bin/env bash
# test_cleanup_config.sh — Integration tests for AI cleanup configuration (US4)
# Verifies tiered cleanup configuration and validation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETUP_SCRIPT="${PROJECT_ROOT}/src/scripts/setup-voice-input.sh"

# shellcheck source=../../src/scripts/lib/common.sh
source "${PROJECT_ROOT}/src/scripts/lib/common.sh"
# shellcheck source=../../src/scripts/lib/config-validator.sh
source "${PROJECT_ROOT}/src/scripts/lib/config-validator.sh"

TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
export VOICE_INPUT_SKIP_PREREQS=1

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

echo "=== Integration Tests: AI Cleanup Config (US4) ==="
echo ""

# Test: Setup with --cleanup-tier=rules creates correct settings
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
"$SETUP_SCRIPT" --cleanup-tier rules 2>/dev/null
local_settings="${TEST_HOME}/.config/voice-input/settings.yaml"
if grep -q "^cleanup_tier: rules" "$local_settings" 2>/dev/null; then
  pass "cleanup_tier=rules is correctly set in settings"
else
  fail "cleanup_tier=rules not found in settings"
fi

# Test: Setup with --cleanup-tier=local_llm adds model config
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
"$SETUP_SCRIPT" --cleanup-tier local_llm 2>/dev/null
local_settings="${TEST_HOME}/.config/voice-input/settings.yaml"
if grep -q "^cleanup_tier: local_llm" "$local_settings" && grep -q "cleanup_local_llm_model:" "$local_settings"; then
  pass "local_llm tier includes model configuration"
else
  fail "local_llm tier missing model configuration"
fi

# Test: Setup with --cleanup-tier=cloud adds provider config
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
"$SETUP_SCRIPT" --no-offline --cleanup-tier cloud 2>/dev/null
local_settings="${TEST_HOME}/.config/voice-input/settings.yaml"
if grep -q "^cleanup_tier: cloud" "$local_settings" && grep -q "cleanup_cloud_provider:" "$local_settings"; then
  pass "cloud tier includes provider configuration"
else
  fail "cloud tier missing provider configuration"
fi

# Test: Cloud config includes api key env reference
run_test
if grep -q "cleanup_cloud_api_key_env:" "$local_settings" 2>/dev/null; then
  pass "cloud tier includes API key env var reference"
else
  fail "cloud tier missing API key env var reference"
fi

# Test: AI cleanup prompt file exists
run_test
local_prompt="${PROJECT_ROOT}/src/config/ai-cleanup-prompt.txt"
if [[ -f "$local_prompt" ]]; then
  pass "AI cleanup prompt template exists"
else
  fail "AI cleanup prompt template not found"
fi

# Test: AI cleanup prompt contains formatting instructions
run_test
if grep -q "punctuation" "$local_prompt" && grep -q "camelCase" "$local_prompt"; then
  pass "AI cleanup prompt contains formatting rules"
else
  fail "AI cleanup prompt missing formatting rules"
fi

# Test: AI cleanup prompt contains examples
run_test
if grep -q "Input:" "$local_prompt" && grep -q "Output:" "$local_prompt"; then
  pass "AI cleanup prompt contains examples"
else
  fail "AI cleanup prompt missing examples"
fi

# Test: Setup deploys cleanup prompt to config dir
run_test
deployed_prompt="${TEST_HOME}/.config/voice-input/ai-cleanup-prompt.txt"
if [[ -f "$deployed_prompt" ]]; then
  pass "Cleanup prompt deployed to config directory"
else
  fail "Cleanup prompt not deployed to config directory"
fi

# Test: Invalid cleanup tier is rejected
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
if "$SETUP_SCRIPT" --cleanup-tier premium 2>/dev/null; then
  fail "Invalid cleanup tier should be rejected"
else
  pass "Invalid cleanup tier is correctly rejected"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="

if ((TESTS_FAILED > 0)); then
  exit 1
fi
exit 0
