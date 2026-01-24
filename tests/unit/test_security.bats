#!/usr/bin/env bats
# Unit tests for MCP security: directory allowlist, file permissions, credential safety
# Tests: T022 (directory allowlist enforcement), T032 (file permissions with credentials)
# TDD: These tests are written BEFORE the implementation exists.

load '../test_helper'

GENERATE_SCRIPT="${PROJECT_ROOT}/src/mcp/generate-configs.sh"
VALIDATE_SCRIPT="${PROJECT_ROOT}/src/mcp/validate-mcp.sh"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}/home"

  mkdir -p "${TEST_TMPDIR}/workspace/.mcp"
  mkdir -p "${HOME}/.claude"

  export MCP_SOURCE_DIR="${TEST_TMPDIR}/workspace/.mcp"
  export MCP_OUTPUT_CLAUDE="${HOME}/.claude/settings.local.json"
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# =============================================================================
# T022 - Directory allowlist enforcement in generated config
# =============================================================================

@test "T022: generated filesystem config only contains explicitly allowed directories" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true,
      "description": "Secure file operations"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # The args array should only contain /workspace
  local args_count
  args_count="$(jq '.mcpServers.filesystem.args | length' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${args_count}" -eq 1 ]]

  local first_arg
  first_arg="$(jq -r '.mcpServers.filesystem.args[0]' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${first_arg}" == "/workspace" ]]
}

@test "T022: generated config does not add extra directories to filesystem args" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace", "/home/dev/projects"],
      "enabled": true,
      "description": "Multi-dir filesystem"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # Only the two explicitly specified directories should appear
  local args_count
  args_count="$(jq '.mcpServers.filesystem.args | length' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${args_count}" -eq 2 ]]

  # No hidden extra paths injected
  local content
  content="$(cat "${MCP_OUTPUT_CLAUDE}")"
  [[ "${content}" != *"/etc"* ]]
  [[ "${content}" != *"/root"* ]]
  [[ "${content}" != *"/var"* ]]
}

@test "T022: config generation preserves exact directory paths without modification" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace/src", "/workspace/tests"],
      "enabled": true,
      "description": "Scoped filesystem"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # Paths should be preserved exactly as specified
  local arg0 arg1
  arg0="$(jq -r '.mcpServers.filesystem.args[0]' "${MCP_OUTPUT_CLAUDE}")"
  arg1="$(jq -r '.mcpServers.filesystem.args[1]' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${arg0}" == "/workspace/src" ]]
  [[ "${arg1}" == "/workspace/tests" ]]
}

# =============================================================================
# T032 - File permissions with resolved credentials
# =============================================================================

@test "T032: generated file has 0600 when containing resolved credential values" {
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
      "description": "GitHub with token"
    }
  }
}
EOF

  export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_real_token_123"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # File must have 0600 permissions
  local perms
  perms="$(stat -f '%Lp' "${MCP_OUTPUT_CLAUDE}" 2>/dev/null || stat -c '%a' "${MCP_OUTPUT_CLAUDE}" 2>/dev/null)"
  [[ "${perms}" == "600" ]]

  # Verify the resolved value IS in the file (proving credentials are present)
  local content
  content="$(cat "${MCP_OUTPUT_CLAUDE}")"
  [[ "${content}" == *"ghp_real_token_123"* ]]
}

@test "T032: generated file has 0600 even when no credentials present" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true,
      "description": "No credentials needed"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # File should still have 0600 (consistent security posture)
  local perms
  perms="$(stat -f '%Lp' "${MCP_OUTPUT_CLAUDE}" 2>/dev/null || stat -c '%a' "${MCP_OUTPUT_CLAUDE}" 2>/dev/null)"
  [[ "${perms}" == "600" ]]
}
