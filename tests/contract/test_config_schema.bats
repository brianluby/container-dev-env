#!/usr/bin/env bats
# Contract tests for MCP source config schema validation
# Tests: T044 (schema validation), T064 (multi-tool format validation)
# Validates that the generate script properly rejects invalid configs

load '../test_helper'

GENERATE_SCRIPT="${PROJECT_ROOT}/src/mcp/generate-configs.sh"
VALIDATE_SCRIPT="${PROJECT_ROOT}/src/mcp/validate-mcp.sh"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}/home"

  mkdir -p "${TEST_TMPDIR}/workspace/.mcp"
  mkdir -p "${HOME}/.claude"
  mkdir -p "${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings"

  export MCP_SOURCE_DIR="${TEST_TMPDIR}/workspace/.mcp"
  export MCP_OUTPUT_CLAUDE="${HOME}/.claude/settings.local.json"
  export MCP_OUTPUT_CLINE="${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# =============================================================================
# T044 - Source config schema validation
# =============================================================================

@test "T044: rejects invalid JSON with clear error and exit code 2" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{ "mcpServers": { broken json here
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 2 ]]
  assert_output_contains "not valid JSON"
}

@test "T044: rejects config missing mcpServers key with exit code 3" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "servers": {
    "filesystem": {
      "command": "mcp-server-filesystem"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 3 ]]
  assert_output_contains "mcpServers"
}

@test "T044: rejects nonexistent source file with exit code 1" {
  run bash "${GENERATE_SCRIPT}" --source "/nonexistent/config.json" --tools claude-code --quiet
  [[ "${status}" -eq 1 ]]
  assert_output_contains "not found"
}

@test "T044: accepts valid config with all required fields" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "test-server": {
      "command": "test-binary",
      "args": ["--flag"],
      "enabled": true,
      "description": "A test server"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]
}

@test "T044: accepts config with empty mcpServers object" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {}
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]
}

# =============================================================================
# T064 - Multi-tool format validation
# =============================================================================

@test "T064: Claude Code output is valid JSON with mcpServers object" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true,
      "description": "File operations"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  # Valid JSON
  jq empty "${MCP_OUTPUT_CLAUDE}"

  # Has mcpServers as object
  local mcp_type
  mcp_type="$(jq -r '.mcpServers | type' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${mcp_type}" == "object" ]]

  # Each server has command (string)
  local cmd_type
  cmd_type="$(jq -r '.mcpServers.filesystem.command | type' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${cmd_type}" == "string" ]]
}

@test "T064: Cline output has disabled and autoApprove fields" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true,
      "description": "File operations"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools cline --quiet
  [[ "${status}" -eq 0 ]]

  # Valid JSON
  jq empty "${MCP_OUTPUT_CLINE}"

  # Has required Cline fields
  local disabled
  disabled="$(jq '.mcpServers.filesystem.disabled' "${MCP_OUTPUT_CLINE}")"
  [[ "${disabled}" == "false" ]]

  local auto_approve_type
  auto_approve_type="$(jq -r '.mcpServers.filesystem.autoApprove | type' "${MCP_OUTPUT_CLINE}")"
  [[ "${auto_approve_type}" == "array" ]]
}

@test "T064: dry-run outputs config to stdout without writing files" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "test": {
      "command": "test-cmd",
      "enabled": true,
      "description": "Test"
    }
  }
}
EOF

  # Remove any existing output files
  rm -f "${MCP_OUTPUT_CLAUDE}" "${MCP_OUTPUT_CLINE}"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --dry-run --quiet
  [[ "${status}" -eq 0 ]]

  # Output should contain the config
  assert_output_contains "Claude Code"
  assert_output_contains "mcpServers"

  # No files should be created
  [[ ! -f "${MCP_OUTPUT_CLAUDE}" ]]
}
