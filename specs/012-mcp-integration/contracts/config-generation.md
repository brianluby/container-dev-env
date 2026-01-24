# Contract: Config Generation Script

**Feature**: 012-mcp-integration
**Date**: 2026-01-23
**Type**: CLI script interface

## Overview

`generate-configs.sh` reads the MCP source configuration and generates tool-native config files for Claude Code, Cline, and Continue.

## Script Interface

```
Usage: generate-configs.sh [OPTIONS]

Options:
  --source PATH     Path to source config (default: /workspace/.mcp/config.json)
  --tools TOOLS     Comma-separated tool list (default: claude-code,cline,continue)
  --dry-run         Print generated configs to stdout without writing files
  --quiet           Suppress informational output (errors still printed to stderr)
  --help            Show usage information

Exit codes:
  0    Success (all requested tool configs generated)
  1    Source config not found or not readable
  2    Source config is not valid JSON
  3    Source config fails schema validation
  4    Write error (cannot create output file/directory)
```

## Input

**Source file**: `.mcp/config.json` (see [mcp-source-config.md](./mcp-source-config.md))

**Environment**: All environment variables in the shell environment are available for `${VAR_NAME}` substitution.

## Output

### Claude Code Output

**Path**: `/workspace/.claude/settings.local.json`

**Behavior**:
- If file exists with other keys (e.g., `permissions`), merge `mcpServers` key only
- If file does not exist, create with `mcpServers` only
- Only include servers with `enabled: true`
- Remove `enabled`, `description` fields
- Remove empty `args` and `env` objects
- Resolve all `${VAR_NAME}` references

**Example output**:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "actual-key-value"
      }
    }
  }
}
```

### Cline Output

**Path**: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

**Behavior**:
- Always overwrite entire file (Cline reads this file exclusively for MCP)
- Only include servers with `enabled: true`
- Add `disabled: false` and `autoApprove: []` to each server
- Remove `enabled`, `description` fields
- Resolve all `${VAR_NAME}` references

**Example output**:
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

### Continue Output

**Path**: `~/.continue/config.yaml`

**Behavior**:
- If file exists, replace only the `mcpServers:` section (preserve all other sections)
- If file does not exist, create with `mcpServers` section only
- Convert object format to array format with `name` field
- Only include servers with `enabled: true`
- Remove `enabled`, `description` fields
- Resolve all `${VAR_NAME}` references

**Example output** (mcpServers section only):
```yaml
mcpServers:
  - name: filesystem
    command: mcp-server-filesystem
    args:
      - /workspace
  - name: context7
    command: npx
    args:
      - -y
      - '@upstash/context7-mcp'
    env:
      CONTEXT7_API_KEY: actual-key-value
```

## Logging

Output format (to stderr):
```
[mcp-generate] === Generating MCP Configs ===
[mcp-generate]   Source: /workspace/.mcp/config.json
[mcp-generate]   Enabled servers: filesystem, context7, memory, sequential-thinking
[mcp-generate]   Skipped (disabled): github, git, playwright
[mcp-generate]   WARN: CONTEXT7_API_KEY not set (context7 server may fail to authenticate)
[mcp-generate]   Generated: /workspace/.claude/settings.local.json
[mcp-generate]   Generated: ~/.config/Code/.../cline_mcp_settings.json
[mcp-generate]   Generated: ~/.continue/config.yaml
[mcp-generate] === Generation Complete ===
```

## Security Constraints

1. MUST NOT log resolved credential values (log variable names only)
2. MUST NOT include `${VAR_NAME}` patterns in generated output (either resolve or omit)
3. Generated files MUST have permissions `0600` (user-read-write only) when they contain resolved credentials
4. Script MUST NOT follow symlinks outside the workspace when resolving source config path

## Dependencies

- `jq` (JSON processing — available in base image)
- `python3-yaml` (YAML generation for Continue config — Python already in base image, package added to Dockerfile)
- Standard POSIX utilities (mkdir, chmod, cat)

## Validation Script Interface

```
Usage: validate-mcp.sh [OPTIONS]

Options:
  --source PATH     Path to source config (default: /workspace/.mcp/config.json)
  --quiet           Only output errors and warnings
  --json            Output validation results as JSON
  --help            Show usage information

Exit codes:
  0    All enabled servers validated successfully
  1    Config file missing or unreadable
  2    Config file is not valid JSON
  3    One or more enabled servers have issues (warnings printed, non-fatal)
```

**Validation output** (to stderr):
```
[mcp-validate] === MCP Server Validation ===
[mcp-validate]   node: v22.x.x (OK)
[mcp-validate]   filesystem: OK (mcp-server-filesystem v2026.1.14)
[mcp-validate]   context7: WARN (CONTEXT7_API_KEY not set)
[mcp-validate]   memory: OK (mcp-server-memory found, volume writable)
[mcp-validate]   sequential-thinking: OK (mcp-server-sequential-thinking found)
[mcp-validate]   github: SKIP (disabled)
[mcp-validate]   git: SKIP (disabled)
[mcp-validate]   playwright: SKIP (disabled)
[mcp-validate] === Validation Complete (4 enabled, 3 OK, 1 WARN, 3 SKIP) ===
```

**JSON output mode**:
```json
{
  "node_version": "v22.x.x",
  "config_path": "/workspace/.mcp/config.json",
  "servers": {
    "filesystem": { "status": "ok", "version": "2026.1.14" },
    "context7": { "status": "warn", "reason": "CONTEXT7_API_KEY not set" },
    "memory": { "status": "ok" },
    "github": { "status": "skip", "reason": "disabled" }
  },
  "summary": { "enabled": 4, "ok": 3, "warn": 1, "skip": 3 }
}
```
