#!/usr/bin/env bash
# test_config_parsing.sh — Unit tests for config validation
# Tests that settings.yaml and vocabulary.yaml are correctly validated.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared libraries
# shellcheck source=../../src/scripts/lib/common.sh
source "${PROJECT_ROOT}/src/scripts/lib/common.sh"
# shellcheck source=../../src/scripts/lib/config-validator.sh
source "${PROJECT_ROOT}/src/scripts/lib/config-validator.sh"

TEST_HOME=$(mktemp -d)
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ─── Test Helpers ─────────────────────────────────────────────────────────────

# Portable in-place sed replacement
# Usage: sed_inplace 's/pattern/replacement/' file
sed_inplace() {
  local expr="$1"
  local file="$2"
  local tmpfile
  tmpfile=$(mktemp)
  sed "$expr" "$file" > "$tmpfile" && mv "$tmpfile" "$file"
}

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

# Create a valid settings file for testing
create_valid_settings() {
  local file="${1:-${TEST_HOME}/settings.yaml}"
  cat > "$file" <<'EOF'
tool: superwhisper
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: true
cleanup_tier: rules
custom_vocab_paths:
  - ~/.config/voice-input/vocabulary.yaml
silence_timeout_ms: 1500
max_recording_duration_s: 300
language: en
output_method: clipboard
visual_feedback: true
EOF
}

# ─── Tests: Valid Settings ────────────────────────────────────────────────────

echo "=== Unit Tests: Config Parsing ==="
echo ""
echo "--- Valid Settings ---"

# Test: Valid settings file passes validation
run_test
create_valid_settings "${TEST_HOME}/valid.yaml"
if validate_settings "${TEST_HOME}/valid.yaml" 2>/dev/null; then
  pass "Valid settings file passes validation"
else
  fail "Valid settings file should pass validation"
fi

# Test: All required fields present
run_test
create_valid_settings "${TEST_HOME}/fields.yaml"
required_fields=("tool" "whisper_model" "activation_shortcut" "activation_mode"
  "cleanup_tier" "silence_timeout_ms" "language")
all_present=true
for field in "${required_fields[@]}"; do
  if ! grep -q "^${field}:" "${TEST_HOME}/fields.yaml"; then
    all_present=false
    break
  fi
done
if [[ "$all_present" == "true" ]]; then
  pass "All required fields are present in valid settings"
else
  fail "Missing required fields in valid settings"
fi

# ─── Tests: Invalid Settings ─────────────────────────────────────────────────

echo ""
echo "--- Invalid Settings ---"

# Test: Missing required field fails
run_test
cat > "${TEST_HOME}/missing.yaml" <<'EOF'
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: true
cleanup_tier: rules
silence_timeout_ms: 1500
language: en
EOF
if validate_settings "${TEST_HOME}/missing.yaml" 2>/dev/null; then
  fail "Missing 'tool' field should fail validation"
else
  pass "Missing required field correctly fails validation"
fi

# Test: Invalid tool enum fails
run_test
create_valid_settings "${TEST_HOME}/bad_tool.yaml"
sed_inplace 's/^tool: superwhisper/tool: invalid/' "${TEST_HOME}/bad_tool.yaml"
if validate_settings "${TEST_HOME}/bad_tool.yaml" 2>/dev/null; then
  fail "Invalid tool enum should fail validation"
else
  pass "Invalid tool enum correctly fails validation"
fi

# Test: Invalid model enum fails
run_test
create_valid_settings "${TEST_HOME}/bad_model.yaml"
sed_inplace 's/^whisper_model: large-v3/whisper_model: huge/' "${TEST_HOME}/bad_model.yaml"
if validate_settings "${TEST_HOME}/bad_model.yaml" 2>/dev/null; then
  fail "Invalid model enum should fail validation"
else
  pass "Invalid model enum correctly fails validation"
fi

# Test: Invalid activation_mode fails
run_test
create_valid_settings "${TEST_HOME}/bad_mode.yaml"
sed_inplace 's/^activation_mode: push_to_talk/activation_mode: voice_activated/' "${TEST_HOME}/bad_mode.yaml"
if validate_settings "${TEST_HOME}/bad_mode.yaml" 2>/dev/null; then
  fail "Invalid activation_mode should fail validation"
else
  pass "Invalid activation_mode correctly fails validation"
fi

# Test: Invalid cleanup_tier fails
run_test
create_valid_settings "${TEST_HOME}/bad_tier.yaml"
sed_inplace 's/^cleanup_tier: rules/cleanup_tier: premium/' "${TEST_HOME}/bad_tier.yaml"
if validate_settings "${TEST_HOME}/bad_tier.yaml" 2>/dev/null; then
  fail "Invalid cleanup_tier should fail validation"
else
  pass "Invalid cleanup_tier correctly fails validation"
fi

# Test: silence_timeout_ms below minimum fails
run_test
create_valid_settings "${TEST_HOME}/low_timeout.yaml"
sed_inplace 's/^silence_timeout_ms: 1500/silence_timeout_ms: 100/' "${TEST_HOME}/low_timeout.yaml"
if validate_settings "${TEST_HOME}/low_timeout.yaml" 2>/dev/null; then
  fail "silence_timeout_ms=100 should fail (min 500)"
else
  pass "silence_timeout_ms below minimum correctly fails"
fi

# Test: silence_timeout_ms above maximum fails
run_test
create_valid_settings "${TEST_HOME}/high_timeout.yaml"
sed_inplace 's/^silence_timeout_ms: 1500/silence_timeout_ms: 9000/' "${TEST_HOME}/high_timeout.yaml"
if validate_settings "${TEST_HOME}/high_timeout.yaml" 2>/dev/null; then
  fail "silence_timeout_ms=9000 should fail (max 5000)"
else
  pass "silence_timeout_ms above maximum correctly fails"
fi

# Test: Invalid language format fails
run_test
create_valid_settings "${TEST_HOME}/bad_lang.yaml"
sed_inplace 's/^language: en/language: english/' "${TEST_HOME}/bad_lang.yaml"
if validate_settings "${TEST_HOME}/bad_lang.yaml" 2>/dev/null; then
  fail "language='english' should fail (must be ISO 639-1)"
else
  pass "Invalid language format correctly fails"
fi

# ─── Tests: Cross-Field Validation ───────────────────────────────────────────

echo ""
echo "--- Cross-Field Validation ---"

# Test: offline_only=true + cleanup_tier=cloud fails
run_test
create_valid_settings "${TEST_HOME}/offline_cloud.yaml"
sed_inplace 's/^cleanup_tier: rules/cleanup_tier: cloud/' "${TEST_HOME}/offline_cloud.yaml"
if validate_settings "${TEST_HOME}/offline_cloud.yaml" 2>/dev/null; then
  fail "offline_only=true + cleanup_tier=cloud should fail"
else
  pass "offline_only + cloud cleanup correctly fails"
fi

# Test: cleanup_tier=cloud without provider fails
run_test
cat > "${TEST_HOME}/cloud_no_provider.yaml" <<'EOF'
tool: superwhisper
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: false
cleanup_tier: cloud
silence_timeout_ms: 1500
language: en
EOF
if validate_settings "${TEST_HOME}/cloud_no_provider.yaml" 2>/dev/null; then
  fail "cleanup_tier=cloud without provider should fail"
else
  pass "Cloud cleanup without provider correctly fails"
fi

# Test: cleanup_tier=cloud with provider and key passes
run_test
cat > "${TEST_HOME}/cloud_valid.yaml" <<'EOF'
tool: superwhisper
whisper_model: large-v3
activation_shortcut: RightCommand
activation_mode: push_to_talk
offline_only: false
cleanup_tier: cloud
cleanup_cloud_provider: claude
cleanup_cloud_api_key_env: ANTHROPIC_API_KEY
silence_timeout_ms: 1500
language: en
EOF
if validate_settings "${TEST_HOME}/cloud_valid.yaml" 2>/dev/null; then
  pass "Valid cloud cleanup config passes validation"
else
  fail "Valid cloud cleanup config should pass"
fi

# ─── Tests: Vocabulary File ──────────────────────────────────────────────────

echo ""
echo "--- Vocabulary Structure ---"

# Test: Seed vocabulary file is valid YAML
run_test
local_vocab="${PROJECT_ROOT}/src/config/vocabulary.yaml"
if [[ -f "$local_vocab" ]]; then
  if grep -q "^version:" "$local_vocab" && grep -q "^terms:" "$local_vocab"; then
    pass "Seed vocabulary has version and terms fields"
  else
    fail "Seed vocabulary missing version or terms field"
  fi
else
  fail "Seed vocabulary file not found at $local_vocab"
fi

# Test: Vocabulary entries have required fields
run_test
if [[ -f "$local_vocab" ]]; then
  # Check that at least one term has all required fields
  has_term=$(grep -c "^  - term:" "$local_vocab" || true)
  has_spoken=$(grep -c "spoken_forms:" "$local_vocab" || true)
  has_display=$(grep -c "display_form:" "$local_vocab" || true)
  has_category=$(grep -c "category:" "$local_vocab" || true)

  if ((has_term > 0 && has_spoken > 0 && has_display > 0 && has_category > 0)); then
    pass "Vocabulary entries contain required fields (term, spoken_forms, display_form, category)"
  else
    fail "Vocabulary entries missing required fields"
  fi
else
  fail "Vocabulary file not found"
fi

# Test: Vocabulary has 50+ entries
run_test
if [[ -f "$local_vocab" ]]; then
  term_count=$(grep -c "^  - term:" "$local_vocab" || true)
  if ((term_count >= 50)); then
    pass "Vocabulary has $term_count entries (≥50 required)"
  else
    fail "Vocabulary has only $term_count entries (50+ required)"
  fi
else
  fail "Vocabulary file not found"
fi

# Test: Vocabulary categories are valid enum values
run_test
if [[ -f "$local_vocab" ]]; then
  valid_categories="function_name|variable_name|technology|project_name|domain_term|custom"
  invalid_cats=$(grep "category:" "$local_vocab" | sed 's/.*category:[[:space:]]*//' | grep -vE "^(${valid_categories})$" | head -5 || true)
  if [[ -z "$invalid_cats" ]]; then
    pass "All vocabulary categories are valid enum values"
  else
    fail "Invalid vocabulary categories found" "$invalid_cats"
  fi
else
  fail "Vocabulary file not found"
fi

# ─── Tests: Shortcut Validation ──────────────────────────────────────────────

echo ""
echo "--- Shortcut Validation ---"

# Test: Valid single key shortcuts
run_test
valid_shortcuts=("RightCommand" "LeftCommand" "RightOption" "Fn" "CapsLock")
all_valid=true
for shortcut in "${valid_shortcuts[@]}"; do
  if ! validate_shortcut "$shortcut" 2>/dev/null; then
    all_valid=false
    break
  fi
done
if [[ "$all_valid" == "true" ]]; then
  pass "Valid single-key shortcuts pass validation"
else
  fail "Some valid shortcuts failed validation"
fi

# Test: Valid combo shortcuts
run_test
if validate_shortcut "Ctrl+Shift+Space" 2>/dev/null; then
  pass "Combo shortcut Ctrl+Shift+Space passes validation"
else
  fail "Combo shortcut should pass validation"
fi

# Test: Invalid shortcut fails
run_test
if validate_shortcut "invalid key name" 2>/dev/null; then
  fail "Invalid shortcut should fail validation"
else
  pass "Invalid shortcut correctly fails validation"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="

if ((TESTS_FAILED > 0)); then
  exit 1
fi
exit 0
