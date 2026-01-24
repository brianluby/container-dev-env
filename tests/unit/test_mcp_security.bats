#!/usr/bin/env bats
# Unit tests for MCP config security (credential redaction, file permissions)
# Tests: T013 (credential redaction in logs, secure file permissions)
# TDD: These tests are written BEFORE the implementation exists.

load '../test_helper'

GENERATE_SCRIPT="${PROJECT_ROOT}/src/mcp/generate-configs.sh"
VALIDATE_SCRIPT="${PROJECT_ROOT}/src/mcp/validate-mcp.sh"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}/home"

  # Create workspace and output directories
  mkdir -p "${TEST_TMPDIR}/workspace/.mcp"
  mkdir -p "${HOME}/.claude"
  mkdir -p "${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
  mkdir -p "${HOME}/.continue"

  export MCP_SOURCE_DIR="${TEST_TMPDIR}/workspace/.mcp"
  export MCP_OUTPUT_CLAUDE="${HOME}/.claude/settings.local.json"
  export MCP_OUTPUT_CLINE="${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"

  # Clear sensitive env vars
  unset CONTEXT7_API_KEY
  unset GITHUB_PERSONAL_ACCESS_TOKEN
  unset SECRET_KEY
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- Helper: Create config with credential env vars ---

create_config_with_secrets() {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@2.1.0"],
      "env": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      },
      "enabled": true,
      "description": "Context7 docs"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@2026.1.14"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      },
      "enabled": true,
      "description": "GitHub API"
    },
    "custom": {
      "command": "custom-server",
      "env": {
        "SECRET_KEY": "${SECRET_KEY}"
      },
      "enabled": true,
      "description": "Custom server with secret"
    }
  }
}
EOF
  echo "${config_file}"
}

# =============================================================================
# T013 - Credential redaction in logs
# =============================================================================

@test "T013: does not log credential values to stderr" {
  local config_file
  config_file="$(create_config_with_secrets)"

  export CONTEXT7_API_KEY="ctx7-super-secret-key-abc123"
  export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  export SECRET_KEY="sk-live-very-secret-value-99999"

  # Run with default (non-quiet) mode to capture log output
  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code
  [[ "${status}" -eq 0 ]]

  # Credential VALUES must never appear in output (BATS captures stdout+stderr)
  [[ "${output}" != *"ctx7-super-secret-key-abc123"* ]]
  [[ "${output}" != *"ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"* ]]
  [[ "${output}" != *"sk-live-very-secret-value-99999"* ]]
}

@test "T013: logs variable names but not values" {
  local config_file
  config_file="$(create_config_with_secrets)"

  export CONTEXT7_API_KEY="ctx7-should-not-be-logged"
  export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_should-not-be-logged"
  export SECRET_KEY="sk-should-not-be-logged"

  # Run in non-quiet mode so logging output is generated (stderr)
  local stderr_file="${TEST_TMPDIR}/stderr.log"
  bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code 2>"${stderr_file}" || true

  local stderr_content
  stderr_content="$(cat "${stderr_file}")"

  # Variable NAMES may appear in informational logs (e.g., "Enabled servers: context7, ...")
  # The script logs server names and env var warnings, which is acceptable
  [[ "${stderr_content}" == *"context7"* ]]

  # But the actual VALUES must not be logged
  [[ "${stderr_content}" != *"ctx7-should-not-be-logged"* ]]
  [[ "${stderr_content}" != *"ghp_should-not-be-logged"* ]]
  [[ "${stderr_content}" != *"sk-should-not-be-logged"* ]]
}

@test "T013: generated files have 0600 permissions" {
  local config_file
  config_file="$(create_config_with_secrets)"

  export CONTEXT7_API_KEY="test-key"
  export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_test"
  export SECRET_KEY="sk-test"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  # Claude Code config should have restrictive permissions (owner read/write only)
  assert_file_exists "${MCP_OUTPUT_CLAUDE}"
  local claude_perms
  claude_perms="$(stat -f '%Lp' "${MCP_OUTPUT_CLAUDE}" 2>/dev/null || stat -c '%a' "${MCP_OUTPUT_CLAUDE}" 2>/dev/null)"
  [[ "${claude_perms}" == "600" ]]

  # Cline config should also have restrictive permissions
  assert_file_exists "${MCP_OUTPUT_CLINE}"
  local cline_perms
  cline_perms="$(stat -f '%Lp' "${MCP_OUTPUT_CLINE}" 2>/dev/null || stat -c '%a' "${MCP_OUTPUT_CLINE}" 2>/dev/null)"
  [[ "${cline_perms}" == "600" ]]
}

# =============================================================================
# T013 - Validation script security checks
# =============================================================================

@test "T013: validate-mcp rejects config with inline credentials" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@2026.1.14"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_hardcoded_token_value_12345"
      },
      "enabled": true,
      "description": "GitHub with hardcoded token"
    }
  }
}
EOF

  run bash "${VALIDATE_SCRIPT}" --source "${config_file}"
  [[ "${status}" -ne 0 ]]
  assert_output_contains "hardcoded"
}

@test "T013: validate-mcp accepts config with env var references only" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@2026.1.14"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      },
      "enabled": true,
      "description": "GitHub with env var reference"
    }
  }
}
EOF

  # Set the env var so the validation passes fully (no missing-var warning)
  export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_test_value"

  run bash "${VALIDATE_SCRIPT}" --source "${config_file}"
  [[ "${status}" -eq 0 ]]
}
