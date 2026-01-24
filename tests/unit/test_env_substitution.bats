#!/usr/bin/env bats
# Unit tests for MCP config environment variable substitution
# Tests: T012 (env var substitution in config values)
# TDD: These tests are written BEFORE the implementation exists.

load '../test_helper'

GENERATE_SCRIPT="${PROJECT_ROOT}/src/mcp/generate-configs.sh"

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

  # Clear test env vars to prevent contamination
  unset CONTEXT7_API_KEY
  unset GITHUB_PERSONAL_ACCESS_TOKEN
  unset CUSTOM_VAR
  unset ANOTHER_VAR
  unset MISSING_VAR
}

teardown() {
  if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
    rm -rf "${TEST_TMPDIR}"
  fi
}

# --- Helper: Create config with env var references ---

create_config_with_env_refs() {
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
    }
  }
}
EOF
  echo "${config_file}"
}

create_config_with_multiple_env_refs() {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "custom-server": {
      "command": "custom-mcp-server",
      "env": {
        "API_KEY": "${CUSTOM_VAR}",
        "API_SECRET": "${ANOTHER_VAR}",
        "ENDPOINT": "https://api.example.com/v1"
      },
      "enabled": true,
      "description": "Custom server with multiple env vars"
    }
  }
}
EOF
  echo "${config_file}"
}

create_config_with_missing_env_ref() {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@2026.1.14"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${MISSING_VAR}"
      },
      "enabled": true,
      "description": "GitHub integration"
    }
  }
}
EOF
  echo "${config_file}"
}

create_config_with_literal_strings() {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "mcp-server-memory",
      "env": {
        "MEMORY_FILE_PATH": "/home/dev/.local/share/mcp-memory/memory.json",
        "LOG_LEVEL": "info"
      },
      "enabled": true,
      "description": "Knowledge graph memory"
    }
  }
}
EOF
  echo "${config_file}"
}

# =============================================================================
# T012 - Environment variable substitution
# =============================================================================

@test "T012: substitutes \${VAR_NAME} with env var value" {
  local config_file
  config_file="$(create_config_with_env_refs)"

  export CONTEXT7_API_KEY="my-test-api-key-12345"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # The generated config should have the resolved value, not the placeholder
  local resolved_value
  resolved_value="$(jq -r '.mcpServers["context7"].env.CONTEXT7_API_KEY' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${resolved_value}" == "my-test-api-key-12345" ]]

  # The placeholder syntax should NOT remain in output
  local raw_content
  raw_content="$(cat "${MCP_OUTPUT_CLAUDE}")"
  [[ "${raw_content}" != *'${CONTEXT7_API_KEY}'* ]]
}

@test "T012: warns when referenced env var is not set" {
  local config_file
  config_file="$(create_config_with_missing_env_ref)"

  # Ensure MISSING_VAR is unset
  unset MISSING_VAR

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code
  # Script should still succeed (non-fatal warning)
  [[ "${status}" -eq 0 ]]

  # Should produce a warning about the missing variable (in stderr captured by run)
  assert_output_contains "MISSING_VAR"
  assert_output_contains "WARN"
}

@test "T012: leaves non-env strings unchanged" {
  local config_file
  config_file="$(create_config_with_literal_strings)"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # Literal path should be preserved exactly
  local memory_path
  memory_path="$(jq -r '.mcpServers["memory"].env.MEMORY_FILE_PATH' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${memory_path}" == "/home/dev/.local/share/mcp-memory/memory.json" ]]

  # Literal string without ${} should be unchanged
  local log_level
  log_level="$(jq -r '.mcpServers["memory"].env.LOG_LEVEL' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${log_level}" == "info" ]]
}

# =============================================================================
# T027 - Context7 credential warning
# =============================================================================

@test "T027: warns about CONTEXT7_API_KEY when unset but server enabled" {
  local config_file
  config_file="$(create_config_with_env_refs)"

  # Ensure CONTEXT7_API_KEY is unset
  unset CONTEXT7_API_KEY

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code
  # Script should succeed (missing key is non-fatal)
  [[ "${status}" -eq 0 ]]

  # Warning should mention the specific variable name
  assert_output_contains "CONTEXT7_API_KEY"
  assert_output_contains "WARN"
}

@test "T027: no warning when CONTEXT7_API_KEY is set" {
  local config_file
  config_file="$(create_config_with_env_refs)"

  export CONTEXT7_API_KEY="valid-key-for-testing"

  # Capture stderr only
  local stderr_file="${TEST_TMPDIR}/stderr.log"
  bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code 2>"${stderr_file}"

  local stderr_content
  stderr_content="$(cat "${stderr_file}")"

  # No WARN about CONTEXT7_API_KEY should appear
  [[ "${stderr_content}" != *"WARN"*"CONTEXT7_API_KEY"* ]]
}

# =============================================================================
# T031/T033 - Special character handling in env var values
# =============================================================================

@test "T031: env var value with double quotes is properly JSON-escaped" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "test-server": {
      "command": "test-cmd",
      "env": {
        "MY_VALUE": "${MY_VALUE}"
      },
      "enabled": true,
      "description": "Test special chars"
    }
  }
}
EOF

  export MY_VALUE='value with "quotes" inside'

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # File must be valid JSON (jq handles escaping)
  jq empty "${MCP_OUTPUT_CLAUDE}"

  # The resolved value should be retrievable via jq
  local resolved
  resolved="$(jq -r '.mcpServers["test-server"].env.MY_VALUE' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${resolved}" == 'value with "quotes" inside' ]]
}

@test "T031: env var value with backslashes is properly JSON-escaped" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "test-server": {
      "command": "test-cmd",
      "env": {
        "MY_PATH": "${MY_PATH}"
      },
      "enabled": true,
      "description": "Test backslashes"
    }
  }
}
EOF

  export MY_PATH='C:\Users\dev\path'

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # File must be valid JSON
  jq empty "${MCP_OUTPUT_CLAUDE}"

  local resolved
  resolved="$(jq -r '.mcpServers["test-server"].env.MY_PATH' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${resolved}" == 'C:\Users\dev\path' ]]
}

@test "T033: env var value with newlines is properly JSON-escaped" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "test-server": {
      "command": "test-cmd",
      "env": {
        "MULTI_LINE": "${MULTI_LINE}"
      },
      "enabled": true,
      "description": "Test newlines"
    }
  }
}
EOF

  export MULTI_LINE="line1
line2
line3"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # File must be valid JSON despite multiline value
  jq empty "${MCP_OUTPUT_CLAUDE}"

  local resolved
  resolved="$(jq -r '.mcpServers["test-server"].env.MULTI_LINE' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${resolved}" == "line1
line2
line3" ]]
}

@test "T033: env var value with special JSON chars (tab, unicode) is escaped" {
  local config_file="${MCP_SOURCE_DIR}/config.json"
  cat > "${config_file}" <<'EOF'
{
  "mcpServers": {
    "test-server": {
      "command": "test-cmd",
      "env": {
        "SPECIAL": "${SPECIAL}"
      },
      "enabled": true,
      "description": "Test special JSON chars"
    }
  }
}
EOF

  # Tab character and ampersand
  export SPECIAL=$'value\twith\ttabs & <special>'

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # File must be valid JSON
  jq empty "${MCP_OUTPUT_CLAUDE}"

  local resolved
  resolved="$(jq -r '.mcpServers["test-server"].env.SPECIAL' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${resolved}" == $'value\twith\ttabs & <special>' ]]
}

# =============================================================================
# T012 - Multiple env vars
# =============================================================================

@test "T012: handles multiple env vars in same config" {
  local config_file
  config_file="$(create_config_with_multiple_env_refs)"

  export CUSTOM_VAR="custom-key-abc"
  export ANOTHER_VAR="secret-value-xyz"

  run bash "${GENERATE_SCRIPT}" --source "${config_file}" --tools claude-code --quiet
  [[ "${status}" -eq 0 ]]

  assert_file_exists "${MCP_OUTPUT_CLAUDE}"

  # Both env vars should be resolved
  local api_key
  api_key="$(jq -r '.mcpServers["custom-server"].env.API_KEY' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${api_key}" == "custom-key-abc" ]]

  local api_secret
  api_secret="$(jq -r '.mcpServers["custom-server"].env.API_SECRET' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${api_secret}" == "secret-value-xyz" ]]

  # Literal endpoint should be unchanged
  local endpoint
  endpoint="$(jq -r '.mcpServers["custom-server"].env.ENDPOINT' "${MCP_OUTPUT_CLAUDE}")"
  [[ "${endpoint}" == "https://api.example.com/v1" ]]
}
