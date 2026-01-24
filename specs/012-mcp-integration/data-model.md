# Data Model: MCP Integration

**Feature**: 012-mcp-integration
**Date**: 2026-01-23

## Entities

### MCP Source Configuration

The canonical configuration file at `.mcp/config.json` in the project workspace.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "description": "string (human-readable description of this config)",
  "mcpServers": {
    "<server-name>": {
      "command": "string (required: binary name or path)",
      "args": ["string (optional: command arguments)"],
      "env": {
        "<ENV_VAR>": "string (value or ${VARIABLE_NAME} reference)"
      },
      "enabled": "boolean (default: true)",
      "description": "string (optional: human-readable purpose)"
    }
  }
}
```

**Fields**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `$schema` | string | No | - | JSON Schema reference for editor support |
| `description` | string | No | - | Human-readable config description |
| `mcpServers` | object | Yes | - | Map of server name to server definition |
| `mcpServers.<name>.command` | string | Yes | - | Executable command (binary name on PATH or absolute path) |
| `mcpServers.<name>.args` | string[] | No | `[]` | Arguments passed to the command |
| `mcpServers.<name>.env` | object | No | `{}` | Environment variables for the server process |
| `mcpServers.<name>.enabled` | boolean | No | `true` | Whether this server should be included in generated configs |
| `mcpServers.<name>.description` | string | No | - | Human-readable description (not passed to tools) |

**Identity**: Server name (the object key) must be unique within the config. Names should be lowercase alphanumeric with hyphens.

**Validation rules**:
- `command` must be a non-empty string
- `args` elements must be strings
- `env` keys must be valid environment variable names (`[A-Z_][A-Z0-9_]*`)
- `env` values may contain `${VARIABLE_NAME}` references for substitution
- Server names must match `^[a-z][a-z0-9-]*$`

### Generated Claude Code Config

Output at `/workspace/.claude/settings.local.json`.

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "string",
      "args": ["string"],
      "env": {
        "<KEY>": "resolved-value"
      }
    }
  }
}
```

**Transformation from source**:
- Only `enabled: true` servers included
- `enabled` and `description` fields removed
- `${VARIABLE_NAME}` in env values replaced with actual env var values
- Empty `args` and `env` omitted

### Generated Cline Config

Output at `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`.

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "string",
      "args": ["string"],
      "env": {
        "<KEY>": "resolved-value"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

**Transformation from source**:
- Only `enabled: true` servers included
- `enabled` → inverted to `disabled: false`
- `description` field removed
- `autoApprove: []` added (empty by default)
- `${VARIABLE_NAME}` in env values resolved

### Generated Continue Config (mcpServers section)

Merged into existing `~/.continue/config.yaml`.

```yaml
mcpServers:
  - name: server-name
    command: string
    args:
      - string
    env:
      KEY: resolved-value
```

**Transformation from source**:
- Only `enabled: true` servers included
- Object format → array format with explicit `name` field
- `enabled` and `description` fields removed
- `${VARIABLE_NAME}` in env values resolved
- Only the `mcpServers` section is replaced; other config sections preserved

### Memory Knowledge Graph

Persisted at `~/.local/share/mcp-memory/memory.json` in Docker named volume.

```json
{
  "entities": [
    {
      "name": "string (entity identifier)",
      "entityType": "string (category)",
      "observations": ["string (facts about entity)"]
    }
  ],
  "relations": [
    {
      "from": "string (source entity name)",
      "to": "string (target entity name)",
      "relationType": "string (relationship type)"
    }
  ]
}
```

**Notes**:
- Managed entirely by `@modelcontextprotocol/server-memory` — no custom code
- Schema defined by the MCP memory server package
- Grows over time as AI agents store observations
- No size limits enforced by this feature (volume capacity is the limit)

## Relationships

```
.mcp/config.json (Source)
    │
    ├──[generates]──→ .claude/settings.local.json (Claude Code)
    ├──[generates]──→ cline_mcp_settings.json (Cline)
    └──[generates]──→ config.yaml [mcpServers section] (Continue)

Docker Named Volume (mcp-memory)
    └──[mounts to]──→ ~/.local/share/mcp-memory/memory.json

entrypoint.sh
    ├──[calls]──→ validate-mcp.sh
    └──[calls]──→ generate-configs.sh
```

## State Transitions

### Server Status (at validation time)

```
[Config Parsed] → ENABLED / DISABLED (based on config)
    │
    ├── ENABLED → [Check Command] → READY / MISSING_BINARY
    │                                    │
    │                                    └── [Check Env] → READY / MISSING_CREDENTIAL
    │
    └── DISABLED → SKIP (not validated, not generated)
```

**Terminal states reported by validate-mcp.sh**:
- `OK`: Server ready (command found, required env vars set)
- `WARN`: Server partially ready (command found, optional env var missing)
- `ERROR`: Server not ready (command not found)
- `SKIP`: Server disabled in config

### Config Generation Flow

```
[Source Config Exists?]
    │
    ├── No → [Use defaults/mcp-config.json] → [Generate]
    │
    └── Yes → [Parse JSON]
                  │
                  ├── Invalid JSON → [Log Error, Abort Generation]
                  │
                  └── Valid → [Filter enabled] → [Substitute env vars] → [Generate per-tool configs]
```
