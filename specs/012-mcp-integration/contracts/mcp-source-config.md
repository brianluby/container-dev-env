# Contract: MCP Source Configuration

**Feature**: 012-mcp-integration
**Date**: 2026-01-23
**Type**: Configuration file schema

## Overview

The MCP source configuration (`.mcp/config.json`) is the single source of truth for all MCP server definitions in a project. It is consumed by the `generate-configs.sh` script at container startup to produce tool-native configurations.

## File Location

```
/workspace/.mcp/config.json
```

Fallback if not present: `/home/dev/.mcp/defaults/mcp-config.json` (copy of `src/mcp/defaults/mcp-config.json` baked into image).

## JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "MCP Source Configuration",
  "type": "object",
  "required": ["mcpServers"],
  "properties": {
    "$schema": {
      "type": "string",
      "description": "JSON Schema reference for editor support"
    },
    "description": {
      "type": "string",
      "description": "Human-readable description of this configuration"
    },
    "mcpServers": {
      "type": "object",
      "description": "Map of server name to server definition",
      "additionalProperties": {
        "$ref": "#/$defs/ServerDefinition"
      },
      "propertyNames": {
        "pattern": "^[a-z][a-z0-9-]*$"
      }
    }
  },
  "$defs": {
    "ServerDefinition": {
      "type": "object",
      "required": ["command"],
      "properties": {
        "command": {
          "type": "string",
          "minLength": 1,
          "description": "Executable command (binary name on PATH or absolute path)"
        },
        "args": {
          "type": "array",
          "items": { "type": "string" },
          "default": [],
          "description": "Arguments passed to the command"
        },
        "env": {
          "type": "object",
          "additionalProperties": { "type": "string" },
          "propertyNames": {
            "pattern": "^[A-Z_][A-Z0-9_]*$"
          },
          "default": {},
          "description": "Environment variables. Values may contain ${VAR_NAME} for substitution."
        },
        "enabled": {
          "type": "boolean",
          "default": true,
          "description": "Whether this server is active. Disabled servers are excluded from generated configs."
        },
        "description": {
          "type": "string",
          "description": "Human-readable purpose (not passed to AI tools)"
        }
      },
      "additionalProperties": false
    }
  }
}
```

## Default Configuration

The default config shipped with the container image:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "description": "MCP Server Configuration for Container Dev Env",
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true,
      "description": "Secure file operations within allowed directories"
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@2.1.0"],
      "env": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      },
      "enabled": true,
      "description": "Up-to-date library documentation and code examples"
    },
    "memory": {
      "command": "mcp-server-memory",
      "env": {
        "MEMORY_FILE_PATH": "/home/dev/.local/share/mcp-memory/memory.json"
      },
      "enabled": true,
      "description": "Knowledge graph-based persistent memory"
    },
    "sequential-thinking": {
      "command": "mcp-server-sequential-thinking",
      "enabled": true,
      "description": "Dynamic and reflective problem-solving"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@2026.1.14"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      },
      "enabled": false,
      "description": "GitHub API integration (requires personal access token)"
    },
    "git": {
      "command": "python3",
      "args": ["-m", "mcp_server_git", "--repository", "/workspace"],
      "enabled": false,
      "description": "Git repository introspection (diffs, history, branches)"
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@0.0.28"],
      "enabled": false,
      "description": "Browser automation (requires Chromium installation)"
    }
  }
}
```

## Validation Rules

1. File MUST be valid JSON (parse error → abort with clear message)
2. `mcpServers` key MUST exist and be an object
3. Each server name MUST match `^[a-z][a-z0-9-]*$`
4. Each server MUST have a non-empty `command` string
5. `env` values containing `${...}` are substituted; unresolved refs produce warnings
6. Unknown fields on server definitions are rejected (strict schema)

## Environment Variable Substitution

Pattern: `${VARIABLE_NAME}`

- Recognized in `env` object values only (not in `command` or `args`)
- If the referenced env var is set → substitute its value
- If the referenced env var is unset and the server is enabled → log warning, server marked as `WARN`
- If the referenced env var is unset and the server is disabled → silently ignored
- Literal `${` not intended as substitution → not currently supported (escape not needed in practice since env var names are `[A-Z_]+`)

## Compatibility

This config format is consumed by:
- `src/mcp/generate-configs.sh` (primary consumer)
- `src/mcp/validate-mcp.sh` (validation only)

It is NOT directly consumed by any AI tool — tools read their generated native configs.
