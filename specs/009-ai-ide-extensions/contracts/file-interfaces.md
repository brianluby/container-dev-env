# File Interface Contracts: AI IDE Extensions

**Feature Branch**: `009-ai-ide-extensions`
**Date**: 2026-01-23

## Overview

This feature has no REST APIs or network services to define. All interfaces are file-based configuration contracts between components. This document defines the exact file formats, locations, and validation rules.

---

## Contract 1: Extension Manifest

**Producer**: Build system (Dockerfile)
**Consumer**: Container entrypoint script
**Format**: Declarative list of extensions to install

### Schema

```yaml
# Location: /opt/ide/extensions.yaml (baked into image)
extensions:
  - id: string          # Required. Format: publisher.extensionName
    version: string     # Required. Pinned semver version
    source: enum        # Required. Values: open-vsx
    vsix_path: string   # Required. Path to pre-downloaded VSIX in image
```

### Validation Rules

- `id` must match pattern `^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$`
- `version` must be valid semver
- `vsix_path` must point to existing file in the image
- All listed extensions must activate without errors in OpenVSCode-Server

---

## Contract 2: Continue Configuration

**Producer**: Chezmoi template (user-scoped) or workspace `.continue/config.yaml` (project override)
**Consumer**: Continue extension
**Format**: YAML (schema v1)

### Schema (Required Fields)

```yaml
# Location: ~/.continue/config.yaml
name: string          # Required. Config profile name
version: string       # Required. Config version (e.g., "0.0.1")
schema: v1            # Required. Must be "v1"

models:               # Required. At least one model entry
  - name: string      # Required. Display name
    provider: enum    # Required. Values: anthropic, openai, ollama, mistral
    model: string     # Required. Provider-specific model ID
    apiKey: string    # Conditional. Required for cloud providers. Format: ${{ secrets.VAR }}
    roles: [string]   # Required. Values: chat, edit, autocomplete, embed, apply
    apiBase: string   # Optional. Custom endpoint URL (required for Ollama)
    autocompleteOptions:  # Optional. Only for autocomplete role
      disable: boolean
      debounceDelay: integer
      maxPromptTokens: integer

mcpServers:           # Optional. MCP server declarations
  - name: string      # Required. Server display name
    command: string   # Required for stdio. Executable command
    args: [string]    # Optional. Command arguments
    env: object       # Optional. Environment variables for subprocess
```

### Validation Rules

- At least one model with `roles: [chat]` must be defined
- Models with cloud providers (anthropic, openai, mistral) must have `apiKey` field
- `apiKey` must use `${{ secrets.VAR }}` syntax (never literal keys)
- Ollama models must specify `apiBase` or use default `http://localhost:11434`
- MCP server `args` for filesystem must include only `/workspace` path (not `/` or `~`)

### Workspace Override Behavior

- Workspace config at `.continue/config.yaml` merges with user config
- Workspace `models` entries ADD to user models (don't replace)
- Workspace `mcpServers` entries ADD to user servers

---

## Contract 3: Continue Secrets File

**Producer**: Container entrypoint script
**Consumer**: Continue extension (resolves `${{ secrets.* }}` references)
**Format**: Dotenv (KEY=VALUE)

### Schema

```bash
# Location: ~/.continue/.env
# Permissions: 600 (owner read/write only)
ANTHROPIC_API_KEY=string   # Required if using Anthropic provider
OPENAI_API_KEY=string      # Required if using OpenAI provider
MISTRAL_API_KEY=string     # Required if using Mistral provider (for autocomplete)
```

### Validation Rules

- File permissions MUST be 600
- File MUST NOT be committed to version control
- Keys MUST NOT contain whitespace
- Keys MUST NOT be empty strings
- File is recreated on each container start (not persisted across rebuilds)

### Producer Script Contract

```bash
# Entrypoint must produce this file from env vars
# Input: OS environment variables (from 003-secret-injection)
# Output: ~/.continue/.env
# Behavior: Skip missing optional keys, error on no keys at all
```

---

## Contract 4: Cline MCP Settings

**Producer**: Container initialization script
**Consumer**: Cline extension
**Format**: JSON

### Schema

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "string",       // Required. Executable path
      "args": ["string"],        // Required. Command arguments
      "env": {},                 // Optional. Environment variables
      "disabled": false,         // Optional. Default: false
      "autoApprove": [],         // Required. Must be empty array (human-in-the-loop)
      "transportType": "stdio"   // Optional. Default: "stdio"
    }
  }
}
```

### Location

```
~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
```

### Validation Rules

- `autoApprove` MUST be empty array `[]` (never pre-approve tools)
- Filesystem server args must scope to `/workspace` only
- `command` must reference pre-installed binaries (no `npx -y` runtime downloads)
- Parent directories must be created before file is written

---

## Contract 5: VS Code User Settings

**Producer**: Container initialization / Chezmoi template
**Consumer**: OpenVSCode-Server
**Format**: JSON

### Required Settings

```json
{
  "telemetry.telemetryLevel": "off"
}
```

### Location

```
~/.config/Code/User/settings.json
```

### Validation Rules

- `telemetry.telemetryLevel` MUST be `"off"` (SEC requirement)
- File must be valid JSON
- Additional settings may be added but must not override telemetry setting

---

## Contract 6: Telemetry Hosts Blocklist

**Producer**: Dockerfile
**Consumer**: Container networking (DNS resolution)
**Format**: /etc/hosts entries

### Schema

```
0.0.0.0 data.cline.bot
0.0.0.0 us.posthog.com
0.0.0.0 eu.posthog.com
```

### Validation Rules

- All entries resolve to 0.0.0.0 (not 127.0.0.1, to avoid connection timeout delays)
- Must not block LLM API domains (api.anthropic.com, api.openai.com, api.mistral.ai)
- Applied at image build time (not runtime)
