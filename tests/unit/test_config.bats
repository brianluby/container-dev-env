#!/usr/bin/env bats
# Unit tests for src/agent/lib/config.sh
# Tests configuration loading, merging, and validation

load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}"
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.config/agent"
  export WORKSPACE="${TEST_TMPDIR}/workspace"
  mkdir -p "${WORKSPACE}"

  # Clear env vars to prevent test contamination
  unset AGENT_BACKEND
  unset AGENT_MODE
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- Config Loading ---

@test "config: loads project config from .agent.json" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{
  "backend": "opencode",
  "mode": "auto",
  "checkpoint": { "enabled": true, "retention": { "max_count": 30 } }
}
EOF
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_BACKEND}" == "opencode" ]]
  [[ "${AGENT_CFG_MODE}" == "auto" ]]
}

@test "config: loads global config from ~/.config/agent/config.json" {
  cat > "${HOME}/.config/agent/config.json" <<'EOF'
{
  "backend": "claude",
  "mode": "manual"
}
EOF
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_BACKEND}" == "claude" ]]
}

@test "config: project config overrides global config" {
  cat > "${HOME}/.config/agent/config.json" <<'EOF'
{ "backend": "claude", "mode": "manual" }
EOF
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "backend": "opencode", "mode": "hybrid" }
EOF
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_BACKEND}" == "opencode" ]]
  [[ "${AGENT_CFG_MODE}" == "hybrid" ]]
}

# --- Env Var Defaults ---

@test "config: AGENT_BACKEND env var overrides config file" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "backend": "opencode" }
EOF
  export AGENT_BACKEND="claude"
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_BACKEND}" == "claude" ]]
}

@test "config: AGENT_MODE env var overrides config file" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "mode": "manual" }
EOF
  export AGENT_MODE="auto"
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_MODE}" == "auto" ]]
}

@test "config: AGENT_STATE_DIR env var sets state directory" {
  export AGENT_STATE_DIR="/custom/state"
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_STATE_DIR}" == "/custom/state" ]]
}

@test "config: defaults to opencode backend when nothing configured" {
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_BACKEND}" == "opencode" ]]
}

@test "config: defaults to manual mode when nothing configured" {
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_MODE}" == "manual" ]]
}

# --- Validation ---

@test "config: rejects invalid mode value" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "mode": "invalid_mode" }
EOF
  source_lib config
  run load_config "${WORKSPACE}"
  [[ "${status}" -ne 0 ]]
  assert_output_contains "invalid"
}

@test "config: rejects invalid backend value" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "backend": "not_a_real_backend" }
EOF
  source_lib config
  run load_config "${WORKSPACE}"
  [[ "${status}" -ne 0 ]]
  assert_output_contains "invalid"
}

@test "config: handles missing config file gracefully" {
  source_lib config
  run load_config "${WORKSPACE}"
  [[ "${status}" -eq 0 ]]
}

@test "config: handles malformed JSON gracefully" {
  echo "not json {{{" > "${WORKSPACE}/.agent.json"
  source_lib config
  run load_config "${WORKSPACE}"
  [[ "${status}" -ne 0 ]]
}

# --- Checkpoint Config ---

@test "config: loads checkpoint retention max_count" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "checkpoint": { "retention": { "max_count": 25, "max_age_days": 14 } } }
EOF
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_CHECKPOINT_MAX_COUNT}" == "25" ]]
  [[ "${AGENT_CFG_CHECKPOINT_MAX_AGE_DAYS}" == "14" ]]
}

@test "config: defaults checkpoint max_count to 50" {
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_CHECKPOINT_MAX_COUNT}" == "50" ]]
}

# --- Shell Config ---

@test "config: loads shell timeout_seconds" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "shell": { "timeout_seconds": 120 } }
EOF
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_SHELL_TIMEOUT}" == "120" ]]
}

@test "config: defaults shell timeout to 300 seconds" {
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${AGENT_CFG_SHELL_TIMEOUT}" == "300" ]]
}

@test "config: loads dangerous_patterns array" {
  cat > "${WORKSPACE}/.agent.json" <<'EOF'
{ "shell": { "dangerous_patterns": ["rm -rf", "git push --force"] } }
EOF
  source_lib config
  load_config "${WORKSPACE}"
  [[ "${#AGENT_CFG_DANGEROUS_PATTERNS[@]}" -eq 2 ]]
}
