#!/usr/bin/env bats
# test_security.bats — Security validation tests for context file templates
# Tests: T037, T038

TESTS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/../.." && pwd)"
TEMPLATES_DIR="${PROJECT_ROOT}/src/templates"

@test "T037: all templates contain security warning comments" {
  local has_security_section=false

  for template in "${TEMPLATES_DIR}"/AGENTS.md.full "${TEMPLATES_DIR}"/AGENTS.md.minimal "${TEMPLATES_DIR}"/nested-AGENTS.md; do
    [ -f "$template" ] || continue

    # Check if this template has a Security section
    if grep -q "^## Security" "$template"; then
      has_security_section=true
      # If it has a Security section, it must have the WARNING comment
      grep -q "WARNING.*Do NOT include.*secrets" "$template"
    fi
  done

  # The comprehensive template must have a security section with warning
  grep -q "WARNING.*Do NOT include.*secrets" "${TEMPLATES_DIR}/AGENTS.md.full"
}

@test "T038: no template placeholder text suggests including secrets/keys/passwords" {
  for template in "${TEMPLATES_DIR}"/*; do
    [ -f "$template" ] || continue

    # Check that placeholder text doesn't suggest putting in actual secrets
    # Placeholders are in [brackets] — verify none suggest secret inclusion
    ! grep -i '\[.*your.*api.*key\]' "$template"
    ! grep -i '\[.*your.*password\]' "$template"
    ! grep -i '\[.*your.*secret\]' "$template"
    ! grep -i '\[.*enter.*token\]' "$template"
    ! grep -i '\[.*paste.*credentials\]' "$template"
    ! grep -i '\[.*insert.*key.*here\]' "$template"
  done
}
