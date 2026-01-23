#!/usr/bin/env bats
# Unit tests for shell safety checks (dangerous pattern detection)
load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}"
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.config/agent"
  export WORKSPACE="${TEST_TMPDIR}/workspace"
  mkdir -p "${WORKSPACE}"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# Source config module which contains dangerous pattern logic
_load_patterns() {
  source_lib config
  load_config "${WORKSPACE}"
}

@test "shell_safety: detects 'rm -rf' as dangerous" {
  _load_patterns
  local found=false
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "rm -rf /tmp/foo" == *"${pattern}"* ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "true" ]]
}

@test "shell_safety: detects 'git push --force' as dangerous" {
  _load_patterns
  local found=false
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "git push --force origin main" == *"${pattern}"* ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "true" ]]
}

@test "shell_safety: detects 'chmod 777' as dangerous" {
  _load_patterns
  local found=false
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "chmod 777 /etc/passwd" == *"${pattern}"* ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "true" ]]
}

@test "shell_safety: 'git push origin main' is safe (no --force)" {
  _load_patterns
  local found=false
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "git push origin main" == *"${pattern}"* ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "false" ]]
}

@test "shell_safety: 'cargo test' is safe" {
  _load_patterns
  local found=false
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "cargo test" == *"${pattern}"* ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "false" ]]
}

@test "shell_safety: 'npm install' is safe" {
  _load_patterns
  local found=false
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "npm install" == *"${pattern}"* ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "false" ]]
}

@test "shell_safety: custom patterns from config override defaults" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "shell": { "dangerous_patterns": ["custom_danger", "rm -rf"] } }
EOF
  _load_patterns
  [[ "${#AGENT_CFG_DANGEROUS_PATTERNS[@]}" -eq 2 ]]
  local found=false
  for pattern in "${AGENT_CFG_DANGEROUS_PATTERNS[@]}"; do
    if [[ "${pattern}" == "custom_danger" ]]; then
      found=true
      break
    fi
  done
  [[ "${found}" == "true" ]]
}

@test "shell_safety: default timeout is 300 seconds" {
  _load_patterns
  [[ "${AGENT_CFG_SHELL_TIMEOUT}" == "300" ]]
}

@test "shell_safety: custom timeout from config" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "shell": { "timeout_seconds": 60 } }
EOF
  _load_patterns
  [[ "${AGENT_CFG_SHELL_TIMEOUT}" == "60" ]]
}
