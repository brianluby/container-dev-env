#!/usr/bin/env bats
# Unit tests for MCP config generation script (src/mcp/generate-configs.sh)
# Tests: T011 (enabled/disabled filtering), T014 (multi-format output), T015 (merge behavior)
# TDD: These tests are written BEFORE the implementation exists.

load '../test_helper'

GENERATE_SCRIPT="${PROJECT_ROOT}/src/mcp/generate-configs.sh"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export HOME="${TEST_TMPDIR}/home"

  # Create workspace with source config directory
  mkdir -p "${TEST_TMPDIR}/workspace/.mcp"

  # Create output directories matching each tool's expected config location
  mkdir -p "${HOME}/.claude"
  mkdir -p "${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
  mkdir -p "${HOME}/.continue"

  # Export paths for the generate script
  export MCP_SOURCE_DIR="${TEST_TMPDIR}/workspace/.mcp"
  export MCP_OUTPUT_CLAUDE="${HOME}/.claude/settings.local.json"
  export MCP_OUTPUT_CLINE="${HOME}/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
  export MCP_OUTPUT_CONTINUE="${HOME}/.continue/config.yaml"
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- Helper: Create a test MCP config ---

create_test_config() {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true,
      "description": "Secure file operations"
    },
    "memory": {
      "command": "mcp-server-memory",
      "env": {
        "MEMORY_FILE_PATH": "/home/dev/.local/share/mcp-memory/memory.json"
      },
      "enabled": true,
      "description": "Knowledge graph memory"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@2026.1.14"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      },
      "enabled": false,
      "description": "GitHub API integration"
    }
  }
}
EOF
  echo "${config_file}"
}

create_all_disabled_config() {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": false,
      "description": "Disabled filesystem"
    },
    "memory": {
      "command": "mcp-server-memory",
      "enabled": false,
      "description": "Disabled memory"
    }
  }
}
EOF
  echo "${config_file}"
}

# =============================================================================
# T011 - Config parsing and enabled/disabled filtering
# =============================================================================

@test "T011: generates config with only enabled servers" {
  local config_file
  config_file="$(create_test_config)"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  # Claude Code output should contain the two enabled servers
  assert_file_exists "${MCP_OUTPUT_CLAUDE}"
  assert_file_contains "${MCP_OUTPUT_CLAUDE}" "filesystem"
  assert_file_contains "${MCP_OUTPUT_CLAUDE}" "memory"
}

@test "T011: excludes disabled servers from output" {
  local config_file
  config_file="$(create_test_config)"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  # The disabled github server should not appear in any output
  assert_file_exists "${MCP_OUTPUT_CLAUDE}"
  local claude_content
  claude_content="$(cat "${MCP_OUTPUT_CLAUDE}")"
  [[ "${claude_content}" != *'"github"'* ]]
}

@test "T011: handles config with all servers disabled" {
  local config_file
  config_file="$(create_all_disabled_config)"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  # Output should have empty mcpServers object
  assert_file_exists "${MCP_OUTPUT_CLAUDE}"
  local servers
  servers="$(jq '.mcpServers | keys | length' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${servers}" -eq 0 ]]
}

# =============================================================================
# T014 - Multi-format output generation
# =============================================================================

@test "T014: generates valid Claude Code JSON format" {
  local config_file
  config_file="$(create_test_config)"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # Must be valid JSON
  jq empty "${MCP_OUTPUT_CLAUDE}"

  # Must have mcpServers top-level key
  local has_mcp_servers
  has_mcp_servers="$(jq 'has("mcpServers")' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_mcp_servers}" == "true" ]]

  # Must NOT have "enabled" or "description" fields (Claude Code doesn't use them)
  local has_enabled
  has_enabled="$(jq '[.mcpServers[] | has("enabled")] | any' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_enabled}" == "false" ]]

  local has_description
  has_description="$(jq '[.mcpServers[] | has("description")] | any' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_description}" == "false" ]]
}

@test "T014: generates Cline JSON with disabled and autoApprove fields" {
  local config_file
  config_file="$(create_test_config)"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLINE}"

  # Must be valid JSON
  jq empty "${MCP_OUTPUT_CLINE}"

  # Must have mcpServers top-level key
  local has_mcp_servers
  has_mcp_servers="$(jq 'has("mcpServers")' "${MCP_OUTPUT_CLINE}")"
  [[ "${has_mcp_servers}" == "true" ]]

  # Each enabled server must have "disabled": false and "autoApprove": []
  local all_have_disabled
  all_have_disabled="$(jq '[.mcpServers[] | .disabled == false] | all' "${MCP_OUTPUT_CLINE}")"
  [[ "${all_have_disabled}" == "true" ]]

  local all_have_autoapprove
  all_have_autoapprove="$(jq '[.mcpServers[] | .autoApprove == []] | all' "${MCP_OUTPUT_CLINE}")"
  [[ "${all_have_autoapprove}" == "true" ]]
}

@test "T014: generates Continue YAML array format" {
  # Skip if PyYAML not available on host (only affects host testing, works in container)
  python3 -c "import yaml" 2>/dev/null || skip "PyYAML not installed"

  local config_file
  config_file="$(create_test_config)"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools continue --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CONTINUE}"

  # Verify YAML has mcpServers section with array entries using "- name:" syntax
  assert_file_contains "${MCP_OUTPUT_CONTINUE}" "mcpServers:"
  assert_file_contains "${MCP_OUTPUT_CONTINUE}" "- name:"

  # Each enabled server should appear as a named entry
  assert_file_contains "${MCP_OUTPUT_CONTINUE}" "name: filesystem"
  assert_file_contains "${MCP_OUTPUT_CONTINUE}" "name: memory"
}

# =============================================================================
# T015 - Merge behavior with existing config files
# =============================================================================

@test "T015: preserves existing settings.local.json keys when merging" {
  local config_file
  config_file="$(create_test_config)"

  # Pre-populate settings.local.json with existing content
  cat > "${MCP_OUTPUT_CLAUDE}" <<'EOF'
{
  "permissions": {
    "allow": ["Read", "Write"]
  },
  "model": "claude-opus-4-5-20251101"
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  # Verify mcpServers was added
  local has_mcp_servers
  has_mcp_servers="$(jq 'has("mcpServers")' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_mcp_servers}" == "true" ]]

  # Verify existing keys are preserved
  local has_permissions
  has_permissions="$(jq 'has("permissions")' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_permissions}" == "true" ]]

  local has_model
  has_model="$(jq 'has("model")' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_model}" == "true" ]]

  # Verify permission values are intact
  local allow_count
  allow_count="$(jq '.permissions.allow | length' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${allow_count}" -eq 2 ]]
}

@test "T015: creates settings.local.json if not exists" {
  local config_file
  config_file="$(create_test_config)"

  # Ensure file does not exist
  rm -f "${MCP_OUTPUT_CLAUDE}"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code,cline --quiet
  [[ "${status}" -eq 0 ]]

  # File should be created from scratch
  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # Should contain mcpServers
  local has_mcp_servers
  has_mcp_servers="$(jq 'has("mcpServers")' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_mcp_servers}" == "true" ]]

  # Should have enabled servers
  local server_count
  server_count="$(jq '.mcpServers | keys | length' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${server_count}" -eq 2 ]]
}

# =============================================================================
# T036 - Memory server configuration
# =============================================================================

@test "T036: memory server env has correct MEMORY_FILE_PATH" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "mcp-server-memory",
      "env": {
        "MEMORY_FILE_PATH": "/home/dev/.local/share/mcp-memory/memory.json"
      },
      "enabled": true,
      "description": "Knowledge graph memory"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # MEMORY_FILE_PATH should be passed through as-is (literal value, not env ref)
  local memory_path
  memory_path="$(jq -r '.mcpServers.memory.env.MEMORY_FILE_PATH' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${memory_path}" == "/home/dev/.local/share/mcp-memory/memory.json" ]]
}

@test "T036: memory server command is correct in generated config" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "mcp-server-memory",
      "env": {
        "MEMORY_FILE_PATH": "/home/dev/.local/share/mcp-memory/memory.json"
      },
      "enabled": true,
      "description": "Knowledge graph memory"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  local cmd
  cmd="$(jq -r '.mcpServers.memory.command' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${cmd}" == "mcp-server-memory" ]]

  # description should be stripped
  local has_desc
  has_desc="$(jq '.mcpServers.memory | has("description")' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_desc}" == "false" ]]
}

# =============================================================================
# T043 - Custom server addition
# =============================================================================

@test "T043: custom server generates correctly in Claude Code format" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "my-custom-server": {
      "command": "/usr/local/bin/my-mcp-server",
      "args": ["--port", "3000", "--workspace", "/workspace"],
      "env": {
        "CUSTOM_AUTH": "static-value"
      },
      "enabled": true,
      "description": "My custom MCP server"
    }
  }
}
EOF

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # Custom server should appear with correct command and args
  local cmd
  cmd="$(jq -r '.mcpServers["my-custom-server"].command' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${cmd}" == "/usr/local/bin/my-mcp-server" ]]

  local args_count
  args_count="$(jq '.mcpServers["my-custom-server"].args | length' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${args_count}" -eq 4 ]]

  # description should be stripped
  local has_desc
  has_desc="$(jq '.mcpServers["my-custom-server"] | has("description")' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${has_desc}" == "false" ]]
}
