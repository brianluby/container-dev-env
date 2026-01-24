#!/usr/bin/env bats
# test_secrets_loader.bats — Safe secrets loading tests
# Verifies: FR-004 (safe parsing), FR-005 (key validation),
#           FR-006 (injection rejection), FR-014 (permissions)

load '../unit/.bats-battery/bats-support/load'
load '../unit/.bats-battery/bats-assert/load'

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

setup() {
  TEST_TEMP="$(mktemp -d)"
  export TEST_TEMP
  export _SECRETS_LOAD_SOURCED=true
  export _SECRETS_QUIET=true
  source "${REPO_ROOT}/scripts/secrets-load.sh"
}

teardown() {
  rm -rf "${TEST_TEMP}"
}

# --- Basic loading ---

@test "loads simple KEY=VALUE pairs" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'API_KEY=abc123\nDB_HOST=localhost\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"

  # Verify variables were exported
  assert_equal "${API_KEY}" "abc123"
  assert_equal "${DB_HOST}" "localhost"
}

@test "handles values with equals signs" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'CONNECTION_STRING=host=db;port=5432;user=admin\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"
  assert_equal "${CONNECTION_STRING}" "host=db;port=5432;user=admin"
}

@test "skips blank lines and comments" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf '# This is a comment\n\nVALID_KEY=value\n   \n# Another comment\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"
  assert_equal "${VALID_KEY}" "value"
}

@test "handles empty file gracefully" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  touch "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success
}

# --- Key validation (FR-005) ---

@test "rejects lowercase keys" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'lowercase_key=value\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success  # Skips invalid keys with warning, doesn't fail

  # Variable should NOT be set
  assert_equal "${lowercase_key:-unset}" "unset"
}

@test "rejects keys starting with digits" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf '1BAD_KEY=value\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success
}

@test "accepts keys starting with underscore" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf '_VALID_KEY=value\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"
  assert_equal "${_VALID_KEY}" "value"
}

@test "rejects line without equals sign" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'NO_EQUALS_HERE\nVALID=ok\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success  # Warns but continues
}

# --- Injection prevention (FR-006) ---

@test "rejects value with command substitution \$()" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  local canary="${TEST_TEMP}/canary"
  printf 'EVIL=$(touch %s)\n' "${canary}" > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success  # Skips with warning

  # Canary must NOT exist
  [ ! -f "${canary}" ]
  # Variable must NOT be set
  assert_equal "${EVIL:-unset}" "unset"
}

@test "rejects value with backtick substitution" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  local canary="${TEST_TEMP}/canary"
  printf 'EVIL=`touch %s`\n' "${canary}" > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success

  [ ! -f "${canary}" ]
  assert_equal "${EVIL:-unset}" "unset"
}

@test "rejects value with variable expansion \${}" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'EVIL=${HOME}/something\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success

  assert_equal "${EVIL:-unset}" "unset"
}

@test "allows bare dollar sign without braces/parens" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'PRICE=$100\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"
  assert_equal "${PRICE}" '$100'
}

@test "rejects nested command substitution" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'EVIL=prefix$(id)suffix\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success

  assert_equal "${EVIL:-unset}" "unset"
}

# --- Permissions check (FR-014) ---

@test "rejects world-readable secrets file" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'KEY=value\n' > "${secrets_file}"
  chmod 644 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_failure
}

@test "rejects group-writable secrets file" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'KEY=value\n' > "${secrets_file}"
  chmod 620 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_failure
}

@test "accepts owner-only permissions (600)" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'KEY=value\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success
}

@test "accepts owner-read-only permissions (400)" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'KEY=value\n' > "${secrets_file}"
  chmod 400 "${secrets_file}"

  run _secrets_load_safe "${secrets_file}"
  assert_success
}

# --- Special characters in values ---

@test "preserves spaces in values" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'MSG=hello world with spaces\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"
  assert_equal "${MSG}" "hello world with spaces"
}

@test "preserves special characters in values" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'TOKEN=sk-abc123!@#%%^&*()_+\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"
  assert_equal "${TOKEN}" 'sk-abc123!@#%^&*()_+'
}

@test "handles empty values" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'EMPTY_VAL=\n' > "${secrets_file}"
  chmod 600 "${secrets_file}"

  _secrets_load_safe "${secrets_file}"
  assert_equal "${EMPTY_VAL}" ""
}

# --- Integration: main function ---

@test "_secrets_load_main returns 0 when file does not exist" {
  _SECRETS_FILE="${TEST_TEMP}/nonexistent.env"
  run _secrets_load_main
  assert_success
}

@test "_secrets_load_main returns 2 when file is not readable" {
  local secrets_file="${TEST_TEMP}/secrets.env"
  printf 'KEY=value\n' > "${secrets_file}"
  chmod 000 "${secrets_file}"

  _SECRETS_FILE="${secrets_file}"
  run _secrets_load_main
  assert_failure
  # Restore permissions for teardown
  chmod 600 "${secrets_file}"
}
