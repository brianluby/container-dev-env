#!/usr/bin/env bats
# Unit tests for src/agent/lib/exclusions.sh
# Tests .agentignore parsing, default patterns, and tool-native translation

load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}"
  export WORKSPACE="${TEST_TMPDIR}/workspace"
  mkdir -p "${WORKSPACE}"
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- Default Patterns ---

@test "exclusions: loads default patterns when no .agentignore exists" {
  source_lib exclusions
  load_exclusions "${WORKSPACE}"
  [[ "${#EXCLUSION_PATTERNS[@]}" -gt 0 ]]
}

@test "exclusions: default patterns include .env" {
  source_lib exclusions
  load_exclusions "${WORKSPACE}"
  local found=false
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    if [[ "${pattern}" == ".env" ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "true" ]]
}

@test "exclusions: default patterns include *.key" {
  source_lib exclusions
  load_exclusions "${WORKSPACE}"
  local found=false
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    if [[ "${pattern}" == "*.key" ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "true" ]]
}

# --- .agentignore Parsing ---

@test "exclusions: loads patterns from .agentignore file" {
  cat > "${WORKSPACE}/.agentignore" <<'EOF'
# Custom patterns
config/production.yml
internal/proprietary/
EOF
  source_lib exclusions
  load_exclusions "${WORKSPACE}"
  local found=false
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    if [[ "${pattern}" == "config/production.yml" ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "true" ]]
}

@test "exclusions: ignores comment lines in .agentignore" {
  cat > "${WORKSPACE}/.agentignore" <<'EOF'
# This is a comment
secret.txt
# Another comment
EOF
  source_lib exclusions
  load_exclusions "${WORKSPACE}"
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    [[ "${pattern}" != "# This is a comment" ]]
    [[ "${pattern}" != "# Another comment" ]]
  done
}

@test "exclusions: ignores blank lines in .agentignore" {
  cat > "${WORKSPACE}/.agentignore" <<'EOF'
secret.txt

another.key

EOF
  source_lib exclusions
  load_exclusions "${WORKSPACE}"
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    [[ -n "${pattern}" ]]
  done
}

@test "exclusions: merges defaults with project .agentignore" {
  cat > "${WORKSPACE}/.agentignore" <<'EOF'
custom_secret.dat
EOF
  source_lib exclusions
  load_exclusions "${WORKSPACE}"
  # Should have both defaults and custom
  local has_env=false has_custom=false
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    [[ "${pattern}" == ".env" ]] && has_env=true
    [[ "${pattern}" == "custom_secret.dat" ]] && has_custom=true
  done
  [[ "${has_env}" == "true" ]]
  [[ "${has_custom}" == "true" ]]
}

# --- Glob Matching ---

@test "exclusions: matches exact filename" {
  source_lib exclusions
  run match_exclusion ".env" ".env"
  [[ "${status}" -eq 0 ]]
}

@test "exclusions: matches wildcard pattern" {
  source_lib exclusions
  run match_exclusion "server.key" "*.key"
  [[ "${status}" -eq 0 ]]
}

@test "exclusions: matches directory pattern" {
  source_lib exclusions
  run match_exclusion "credentials/aws.json" "credentials/"
  [[ "${status}" -eq 0 ]]
}

@test "exclusions: does not match non-excluded file" {
  source_lib exclusions
  run match_exclusion "src/main.sh" ".env"
  [[ "${status}" -ne 0 ]]
}

@test "exclusions: matches .env.* pattern" {
  source_lib exclusions
  run match_exclusion ".env.production" ".env.*"
  [[ "${status}" -eq 0 ]]
}

# --- Tool-Native Translation ---

@test "exclusions: translates patterns to OpenCode watcher config" {
  source_lib exclusions
  EXCLUSION_PATTERNS=(".env" "*.key" "secrets/")
  run translate_to_opencode
  [[ "${status}" -eq 0 ]]
  assert_output_contains ".env"
}

@test "exclusions: translates patterns to Claude Code settings" {
  source_lib exclusions
  EXCLUSION_PATTERNS=(".env" "*.key" "secrets/")
  run translate_to_claude
  [[ "${status}" -eq 0 ]]
  assert_output_contains ".env"
}
