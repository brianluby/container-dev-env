# Data Model: AI IDE Extensions

**Feature Branch**: `009-ai-ide-extensions`
**Date**: 2026-01-23

## Overview

This feature uses file-based configuration only — no database. All state is stored in configuration files, environment files, and extension storage volumes.

## Entities

### Extension Manifest

The list of extensions to install, with pinned versions.

```yaml
# extensions.json (or extensions.yaml) — Dockerfile build artifact
extensions:
  - id: Continue.continue
    version: "1.2.14"
    source: open-vsx
    vsix_url: "https://open-vsx.org/api/Continue/continue/1.2.14/file/Continue.continue-1.2.14.vsix"
  - id: saoudrizwan.claude-dev
    version: "3.51.0"
    source: open-vsx
    vsix_url: "https://open-vsx.org/api/saoudrizwan/claude-dev/3.51.0/file/saoudrizwan.claude-dev-3.51.0.vsix"
```

**Attributes**: id (extension identifier), version (pinned), source (registry), vsix_url (download location)
**Lifecycle**: Defined at build time → installed in Dockerfile → persisted in extensions volume

---

### Continue Configuration

Provider definitions, model assignments, and MCP server declarations.

**Location**: `~/.continue/config.yaml` (user-scoped default), `.continue/config.yaml` (workspace override)

```yaml
name: container-dev-env
version: 0.0.1
schema: v1

models:
  - name: Claude Sonnet (Chat)
    provider: anthropic
    model: claude-sonnet-4-20250514
    apiKey: ${{ secrets.ANTHROPIC_API_KEY }}
    roles:
      - chat
      - edit

  - name: Codestral (Autocomplete)
    provider: mistral
    model: codestral-latest
    apiKey: ${{ secrets.MISTRAL_API_KEY }}
    roles:
      - autocomplete
    autocompleteOptions:
      disable: false
      debounceDelay: 250

  - name: GPT-4o (Alternative)
    provider: openai
    model: gpt-4o
    apiKey: ${{ secrets.OPENAI_API_KEY }}
    roles:
      - chat

  - name: Qwen Coder (Local Autocomplete)
    provider: ollama
    model: qwen2.5-coder:1.5b
    roles:
      - autocomplete

mcpServers:
  - name: filesystem
    command: mcp-server-filesystem
    args:
      - /workspace
```

**State transitions**: Template → populated with secrets bridge → active (extension reads at startup)

---

### Continue Secrets File

API keys bridged from container environment variables.

**Location**: `~/.continue/.env`

```bash
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
MISTRAL_API_KEY=...
```

**Lifecycle**: Created by entrypoint script from container env vars → read by Continue extension → session lifetime
**Security**: File permissions 600, never committed, created at runtime only

---

### Cline MCP Settings

MCP server declarations for Cline extension.

**Location**: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "disabled": false,
      "autoApprove": []
    },
    "git": {
      "command": "python",
      "args": ["-m", "mcp_server_git", "--repository", "/workspace"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

**State transitions**: Template → copied to globalStorage path at container init → read by Cline
**Note**: `autoApprove: []` ensures all MCP tool calls require human approval

---

### VS Code Settings

Global IDE settings for telemetry control and workspace behavior.

**Location**: `~/.config/Code/User/settings.json` (user-scoped)

```json
{
  "telemetry.telemetryLevel": "off",
  "workbench.startupEditor": "none"
}
```

---

### Telemetry Blocklist

Network-level telemetry prevention.

**Location**: `/etc/hosts` additions in Dockerfile

```
0.0.0.0 data.cline.bot
0.0.0.0 us.posthog.com
0.0.0.0 eu.posthog.com
```

---

## Entity Relationships

```
Extension Manifest (build-time)
  ├── Continue Extension
  │   ├── reads: Continue Configuration (~/.continue/config.yaml)
  │   ├── reads: Continue Secrets File (~/.continue/.env)
  │   └── spawns: MCP Servers (filesystem)
  └── Cline Extension
      ├── reads: ANTHROPIC_API_KEY env var
      ├── reads: Cline MCP Settings (globalStorage path)
      ├── respects: VS Code Settings (telemetry.telemetryLevel)
      └── spawns: MCP Servers (filesystem, git)
```

## Volume Persistence

| Path | Volume | Purpose | Survives Rebuild |
|------|--------|---------|-----------------|
| `~/.continue/` | config volume | Continue config + secrets | Yes (config), No (secrets recreated) |
| `~/.config/Code/User/` | vscode-user volume | VS Code settings, Cline globalStorage | Yes |
| Extension install dir | extensions volume | Installed VSIX binaries | Yes |
| `/workspace` | workspace volume | Project source code | Yes |
