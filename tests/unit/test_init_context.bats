#!/usr/bin/env bats
# test_init_context.bats — BATS tests for the init-context.sh bootstrap script
# Tests: T023, T024, T025, T026, T027, T028, T029, T030

TESTS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/../.." && pwd)"
SCRIPT="${PROJECT_ROOT}/src/scripts/init-context.sh"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- T023: --minimal creates AGENTS.md with 4 sections ---

@test "T023: init-context.sh --minimal creates AGENTS.md with 4 sections" {
  run "$SCRIPT" --minimal --output "${TEST_TMPDIR}/AGENTS.md"
  [ "$status" -eq 0 ]
  [ -f "${TEST_TMPDIR}/AGENTS.md" ]

  # Minimal template has 4 sections
  local section_count
  section_count=$(grep -c "^## " "${TEST_TMPDIR}/AGENTS.md")
  [ "$section_count" -eq 4 ]
}

# --- T024: --full creates AGENTS.md with 9 sections ---

@test "T024: init-context.sh --full creates AGENTS.md with 9 sections" {
  run "$SCRIPT" --full --output "${TEST_TMPDIR}/AGENTS.md"
  [ "$status" -eq 0 ]
  [ -f "${TEST_TMPDIR}/AGENTS.md" ]

  # Full template has 9 sections
  local section_count
  section_count=$(grep -c "^## " "${TEST_TMPDIR}/AGENTS.md")
  [ "$section_count" -eq 9 ]
}

# --- T025: no flags shows interactive prompt ---

@test "T025: init-context.sh without flags shows interactive prompt" {
  # Provide empty stdin to simulate no interactive input (script should prompt)
  run bash -c "echo '' | $SCRIPT --output ${TEST_TMPDIR}/AGENTS.md 2>&1"
  # Should mention template choice in output
  [[ "$output" == *"full"* ]] || [[ "$output" == *"minimal"* ]] || [[ "$output" == *"template"* ]]
}

# --- T026: exits 1 if AGENTS.md already exists (no --force) ---

@test "T026: script exits 1 if AGENTS.md already exists without --force" {
  touch "${TEST_TMPDIR}/AGENTS.md"
  run "$SCRIPT" --minimal --output "${TEST_TMPDIR}/AGENTS.md"
  [ "$status" -eq 1 ]
}

# --- T027: --force overwrites existing file ---

@test "T027: --force overwrites existing AGENTS.md" {
  echo "old content" > "${TEST_TMPDIR}/AGENTS.md"
  run "$SCRIPT" --minimal --force --output "${TEST_TMPDIR}/AGENTS.md"
  [ "$status" -eq 0 ]

  # Content should be from template, not "old content"
  ! grep -q "old content" "${TEST_TMPDIR}/AGENTS.md"
  grep -q "^## Overview" "${TEST_TMPDIR}/AGENTS.md"
}

# --- T028: --output writes to specified path ---

@test "T028: --output writes to specified path" {
  local custom_path="${TEST_TMPDIR}/custom/path/CONTEXT.md"
  mkdir -p "$(dirname "$custom_path")"
  run "$SCRIPT" --minimal --output "$custom_path"
  [ "$status" -eq 0 ]
  [ -f "$custom_path" ]
  grep -q "^# Project Context" "$custom_path"
}

# --- T029: --help outputs usage information ---

@test "T029: --help outputs usage information" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage"* ]]
  [[ "$output" == *"--full"* ]]
  [[ "$output" == *"--minimal"* ]]
  [[ "$output" == *"--output"* ]]
  [[ "$output" == *"--force"* ]]
}

# --- T030: invalid arguments exit with code 2 ---

@test "T030: invalid arguments exit with code 2" {
  run "$SCRIPT" --nonexistent-flag
  [ "$status" -eq 2 ]
}
