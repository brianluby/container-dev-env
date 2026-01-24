#!/usr/bin/env bash
# test_vocabulary.sh — Integration tests for vocabulary management (US6)
# Verifies add-term, remove-term, list, and validate subcommands.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VOCAB_SCRIPT="${PROJECT_ROOT}/src/scripts/update-vocabulary.sh"

TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"

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

# Setup: Create config dir with a seed vocabulary
setup_vocab() {
  mkdir -p "${TEST_HOME}/.config/voice-input"
  cat > "${TEST_HOME}/.config/voice-input/vocabulary.yaml" <<'EOF'
version: "1"

terms:
  - term: PostgreSQL
    spoken_forms: ["postgres", "postgresql"]
    display_form: PostgreSQL
    category: technology
    project: global
    enabled: true
EOF
}

# ─── Tests ────────────────────────────────────────────────────────────────────

echo "=== Integration Tests: Vocabulary Management (US6) ==="
echo ""

# Test: Script exists and is executable
run_test
if [[ -x "$VOCAB_SCRIPT" ]]; then
  pass "Vocabulary script is executable"
else
  fail "Vocabulary script not found or not executable" "$VOCAB_SCRIPT"
fi

# Test: --help shows usage
run_test
if help_output=$("$VOCAB_SCRIPT" --help 2>&1); then
  if echo "$help_output" | grep -qi "usage"; then
    pass "--help shows usage information"
  else
    fail "--help does not contain 'usage'"
  fi
else
  # --help may exit 0 or 1 depending on impl
  if echo "$help_output" | grep -qi "usage"; then
    pass "--help shows usage information"
  else
    fail "--help failed"
  fi
fi

# Test: add-term creates a valid entry
run_test
setup_vocab
if "$VOCAB_SCRIPT" add-term "FastAPI" --spoken-forms "fast api,fastapi" --display-form "FastAPI" --category technology 2>/dev/null; then
  vocab_file="${TEST_HOME}/.config/voice-input/vocabulary.yaml"
  if grep -q "FastAPI" "$vocab_file"; then
    pass "add-term creates entry in vocabulary file"
  else
    fail "add-term did not write entry to file"
  fi
else
  fail "add-term command failed"
fi

# Test: add-term includes spoken_forms
run_test
vocab_file="${TEST_HOME}/.config/voice-input/vocabulary.yaml"
if grep -q "fast api" "$vocab_file" 2>/dev/null; then
  pass "add-term includes spoken_forms in entry"
else
  fail "add-term did not include spoken_forms"
fi

# Test: add-term includes display_form
run_test
if grep -q "display_form: FastAPI" "$vocab_file" 2>/dev/null; then
  pass "add-term includes display_form"
else
  fail "add-term did not include display_form"
fi

# Test: add-term includes category
run_test
# Count category entries to verify the new one was added
cat_count=$(grep -c "category: technology" "$vocab_file" || true)
if ((cat_count >= 2)); then
  pass "add-term includes category field"
else
  fail "add-term did not include category"
fi

# Test: add-term with --project flag
run_test
setup_vocab
"$VOCAB_SCRIPT" add-term "myHelper" --spoken-forms "my helper" --display-form "myHelper" --category function_name --project my-project 2>/dev/null || true
vocab_file="${TEST_HOME}/.config/voice-input/vocabulary.yaml"
if grep -q "project: my-project" "$vocab_file" 2>/dev/null; then
  pass "add-term with --project sets project field"
else
  fail "add-term with --project did not set project field"
fi

# Test: remove-term removes an entry
run_test
setup_vocab
"$VOCAB_SCRIPT" remove-term "PostgreSQL" 2>/dev/null || true
vocab_file="${TEST_HOME}/.config/voice-input/vocabulary.yaml"
if grep -q "term: PostgreSQL" "$vocab_file" 2>/dev/null; then
  fail "remove-term did not remove entry"
else
  pass "remove-term removes entry from vocabulary"
fi

# Test: list subcommand shows entries
run_test
setup_vocab
list_output=$("$VOCAB_SCRIPT" list 2>/dev/null || echo "")
if echo "$list_output" | grep -q "PostgreSQL"; then
  pass "list shows vocabulary entries"
else
  fail "list did not show entries" "$list_output"
fi

# Test: validate subcommand passes for valid file
run_test
setup_vocab
if "$VOCAB_SCRIPT" validate 2>/dev/null; then
  pass "validate passes for valid vocabulary"
else
  fail "validate should pass for valid vocabulary"
fi

# Test: validate catches missing version field
run_test
mkdir -p "${TEST_HOME}/.config/voice-input"
cat > "${TEST_HOME}/.config/voice-input/vocabulary.yaml" <<'EOF'
terms:
  - term: test
    spoken_forms: ["test"]
    display_form: test
    category: technology
EOF
if "$VOCAB_SCRIPT" validate 2>/dev/null; then
  fail "validate should fail for missing version"
else
  pass "validate catches missing version field"
fi

# Test: validate catches invalid category
run_test
mkdir -p "${TEST_HOME}/.config/voice-input"
cat > "${TEST_HOME}/.config/voice-input/vocabulary.yaml" <<'EOF'
version: "1"

terms:
  - term: test
    spoken_forms: ["test"]
    display_form: test
    category: invalid_category
EOF
if "$VOCAB_SCRIPT" validate 2>/dev/null; then
  fail "validate should fail for invalid category"
else
  pass "validate catches invalid category"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed ==="

if ((TESTS_FAILED > 0)); then
  exit 1
fi
exit 0
