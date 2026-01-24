# MCP Server Configuration

This directory contains the default MCP (Model Context Protocol) server configuration for the containerized development environment.

## Quick Start

MCP servers are configured automatically at container startup. The source configuration at `/workspace/.mcp/config.json` is translated into each AI tool's native format.

## Configuration File

Edit `/workspace/.mcp/config.json` to customize which MCP servers are available:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "binary-or-npx",
      "args": ["arg1", "arg2"],
      "env": {
        "API_KEY": "${ENV_VAR_NAME}"
      },
      "enabled": true,
      "description": "Human-readable description"
    }
  }
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `command` | Yes | Executable command (must be on PATH) |
| `args` | No | Array of command-line arguments |
| `env` | No | Environment variables passed to the server |
| `enabled` | No | `true` (default) or `false` to disable |
| `description` | No | Human-readable description (stripped from output) |

### Environment Variable Substitution

Use `${VARIABLE_NAME}` syntax in `env` values. The actual value is resolved from the container's environment at config generation time.

```json
"env": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
}
```

**Never put credentials directly in config files.** Always use environment variable references.

## Adding a Custom MCP Server

1. Install the server package in your Dockerfile or verify it's available on PATH
2. Add an entry to `/workspace/.mcp/config.json`:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "my-mcp-server",
      "args": ["--workspace", "/workspace"],
      "enabled": true,
      "description": "My custom MCP server"
    }
  }
}
```

3. Regenerate configs: `bash /home/dev/.mcp/generate-configs.sh`
4. Restart your AI tool to pick up the new server

## Enabling Optional Servers

The following servers are pre-installed but disabled by default:

| Server | Description | Required Credential |
|--------|-------------|-------------------|
| `github` | GitHub API (issues, PRs, repos) | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| `git` | Git repository introspection | None |
| `playwright` | Browser automation | None (needs Chromium) |

To enable, change `"enabled": false` to `"enabled": true` in the config and regenerate.

## Scripts

| Script | Purpose |
|--------|---------|
| `generate-configs.sh` | Generates tool-native configs from source |
| `validate-mcp.sh` | Validates server availability and config |

### generate-configs.sh

```bash
generate-configs.sh [OPTIONS]

Options:
  --source PATH     Path to source config (default: /workspace/.mcp/config.json)
  --tools TOOLS     Comma-separated: claude-code,cline,continue
  --dry-run         Print configs to stdout without writing
  --quiet           Suppress informational output
  --help            Show usage
```

### validate-mcp.sh

```bash
validate-mcp.sh [OPTIONS]

Options:
  --source PATH     Path to source config
  --quiet           Only output errors/warnings
  --json            Output results as JSON
  --help            Show usage
```

## Troubleshooting

**Server not available after config change:**
- Run `bash /home/dev/.mcp/generate-configs.sh` to regenerate
- Restart your AI tool (Claude Code, Cline, or Continue)

**"WARN: VARIABLE not set":**
- The referenced environment variable isn't in the container environment
- Set it via Docker env, .env file, or docker-compose environment section

**"ERROR: binary not found":**
- The server's command isn't installed in the container
- Add the package to your Dockerfile or install via npm/pip

**File permission errors:**
- Generated configs use 0600 permissions (owner read/write only)
- This is intentional for security when configs contain resolved credentials
