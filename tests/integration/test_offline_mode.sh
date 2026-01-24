#!/usr/bin/env bash
# test_offline_mode.sh — Integration tests for offline mode enforcement (US2)
# Verifies that offline_only=true prevents cloud cleanup tier.

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

echo "=== Integration Tests: Offline Mode (US2) ==="
echo ""

# Test: offline_only + cloud cleanup tier is rejected by setup script
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
if "$SETUP_SCRIPT" --cleanup-tier cloud 2>/dev/null; then
  fail "Setup should reject --cleanup-tier=cloud with default --offline-only"
else
  pass "Setup rejects cloud cleanup when offline_only is default"
fi

# Test: offline_only + cloud cleanup tier is rejected by validator
run_test
cat > "${TEST_HOME}/offline_cloud.yaml" <<'EOF'
tool: superwhisper
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: true
cleanup_tier: cloud
silence_timeout_ms: 1500
language: en
EOF
if validate_settings "${TEST_HOME}/offline_cloud.yaml" 2>/dev/null; then
  fail "Validator should reject offline_only=true + cleanup_tier=cloud"
else
  pass "Validator rejects offline_only=true + cleanup_tier=cloud"
fi

# Test: offline_only + none tier is valid
run_test
cat > "${TEST_HOME}/offline_none.yaml" <<'EOF'
tool: superwhisper
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: true
cleanup_tier: none
silence_timeout_ms: 1500
language: en
EOF
if validate_settings "${TEST_HOME}/offline_none.yaml" 2>/dev/null; then
  pass "offline_only + cleanup_tier=none is valid"
else
  fail "offline_only + cleanup_tier=none should be valid"
fi

# Test: offline_only + rules tier is valid
run_test
cat > "${TEST_HOME}/offline_rules.yaml" <<'EOF'
tool: superwhisper
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: true
cleanup_tier: rules
silence_timeout_ms: 1500
language: en
EOF
if validate_settings "${TEST_HOME}/offline_rules.yaml" 2>/dev/null; then
  pass "offline_only + cleanup_tier=rules is valid"
else
  fail "offline_only + cleanup_tier=rules should be valid"
fi

# Test: offline_only + local_llm tier is valid
run_test
cat > "${TEST_HOME}/offline_llm.yaml" <<'EOF'
tool: superwhisper
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: true
cleanup_tier: local_llm
silence_timeout_ms: 1500
language: en
EOF
if validate_settings "${TEST_HOME}/offline_llm.yaml" 2>/dev/null; then
  pass "offline_only + cleanup_tier=local_llm is valid"
else
  fail "offline_only + cleanup_tier=local_llm should be valid"
fi

# Test: --no-offline allows cloud tier
run_test
rm -rf "${TEST_HOME}/.config/voice-input"
if "$SETUP_SCRIPT" --no-offline --cleanup-tier cloud 2>/dev/null; then
  pass "--no-offline allows cloud cleanup tier"
else
  fail "--no-offline should allow cloud cleanup tier"
fi

# Test: Generated settings with --no-offline + cloud has offline_only=false
run_test
local_settings="${TEST_HOME}/.config/voice-input/settings.yaml"
if [[ -f "$local_settings" ]]; then
  if grep -q "^offline_only: false" "$local_settings"; then
    pass "Generated settings has offline_only=false when --no-offline used"
  else
    fail "Generated settings should have offline_only=false"
  fi
else
  fail "Settings file not found"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="

if ((TESTS_FAILED > 0)); then
  exit 1
fi
exit 0
