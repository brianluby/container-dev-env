#!/usr/bin/env bats
# Unit tests for src/agent/lib/provider.sh
# Tests backend detection, API key validation, and selection logic

load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}"
  export PATH="${TEST_TMPDIR}/bin:${PATH}"
  mkdir -p "${TEST_TMPDIR}/bin"

  # Clear relevant env vars
  unset ANTHROPIC_API_KEY
  unset OPENAI_API_KEY
  unset GOOGLE_API_KEY
  unset AGENT_BACKEND
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- Backend Detection ---

@test "provider: detects opencode when binary exists on PATH" {
  echo '#!/bin/sh' > "${TEST_TMPDIR}/bin/opencode"
  echo 'echo "opencode v0.5.2"' >> "${TEST_TMPDIR}/bin/opencode"
  chmod +x "${TEST_TMPDIR}/bin/opencode"

  source_lib provider
  run detect_backend "opencode"
  [[ "${status}" -eq 0 ]]
}

@test "provider: detects claude when binary exists on PATH" {
  echo '#!/bin/sh' > "${TEST_TMPDIR}/bin/claude"
  echo 'echo "claude 1.0.23"' >> "${TEST_TMPDIR}/bin/claude"
  chmod +x "${TEST_TMPDIR}/bin/claude"

  source_lib provider
  run detect_backend "claude"
  [[ "${status}" -eq 0 ]]
}

@test "provider: fails detection when backend not installed" {
  source_lib provider
  run detect_backend "opencode"
  [[ "${status}" -ne 0 ]]
}

# --- API Key Validation ---

@test "provider: validates ANTHROPIC_API_KEY is set" {
  export ANTHROPIC_API_KEY="sk-ant-test123"
  source_lib provider
  run validate_api_key "anthropic"
  [[ "${status}" -eq 0 ]]
}

@test "provider: fails when ANTHROPIC_API_KEY missing for claude backend" {
  source_lib provider
  run validate_api_key "anthropic"
  [[ "${status}" -ne 0 ]]
  assert_output_contains "ANTHROPIC_API_KEY"
}

@test "provider: validates OPENAI_API_KEY is set" {
  export OPENAI_API_KEY="sk-test123"
  source_lib provider
  run validate_api_key "openai"
  [[ "${status}" -eq 0 ]]
}

@test "provider: fails when no API key configured for any provider" {
  source_lib provider
  run validate_any_api_key
  [[ "${status}" -ne 0 ]]
  assert_output_contains "API key"
}

@test "provider: succeeds when at least one API key is configured" {
  export OPENAI_API_KEY="sk-test123"
  source_lib provider
  run validate_any_api_key
  [[ "${status}" -eq 0 ]]
}

# --- Selection Priority ---

@test "provider: --claude flag takes highest priority" {
  echo '#!/bin/sh' > "${TEST_TMPDIR}/bin/claude"
  chmod +x "${TEST_TMPDIR}/bin/claude"
  echo '#!/bin/sh' > "${TEST_TMPDIR}/bin/opencode"
  chmod +x "${TEST_TMPDIR}/bin/opencode"
  export AGENT_BACKEND="opencode"

  source_lib provider
  run select_backend "--claude"
  [[ "${status}" -eq 0 ]]
  assert_output_contains "claude"
}

@test "provider: AGENT_BACKEND env var used when no flag" {
  echo '#!/bin/sh' > "${TEST_TMPDIR}/bin/claude"
  chmod +x "${TEST_TMPDIR}/bin/claude"
  export AGENT_BACKEND="claude"

  source_lib provider
  run select_backend ""
  [[ "${status}" -eq 0 ]]
  assert_output_contains "claude"
}

@test "provider: defaults to opencode when no flag or env var" {
  echo '#!/bin/sh' > "${TEST_TMPDIR}/bin/opencode"
  chmod +x "${TEST_TMPDIR}/bin/opencode"

  source_lib provider
  run select_backend ""
  [[ "${status}" -eq 0 ]]
  assert_output_contains "opencode"
}

@test "provider: exits 4 when selected backend not installed" {
  source_lib provider
  run select_backend "--claude"
  [[ "${status}" -eq 4 ]]
}
