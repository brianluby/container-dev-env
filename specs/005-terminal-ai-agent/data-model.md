# Data Model: Terminal AI Agent

**Phase**: 1 (Design & Contracts)
**Date**: 2026-01-22
**Feature**: 005-terminal-ai-agent

## Overview

This feature introduces no new application-level data model. OpenCode manages its own internal data structures for sessions and state. The data model here documents the configuration and file-system contracts that the container environment must provide.

## Entities

### Configuration

The agent's runtime configuration, controlling provider selection, behavior, and timeouts.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| provider | string | No | "" (empty) | LLM provider name (e.g., "openai", "anthropic", "ollama") |
| model | string | No | "" (empty) | Model identifier (e.g., "gpt-4o", "claude-sonnet-4-20250514") |
| agent.mode | enum | No | "build" | Agent mode: "plan" (read-only) or "build" (read/write) |
| agent.auto_commit | boolean | No | true | Whether to auto-commit approved changes |
| agent.commit_style | enum | No | "conventional" | Commit message format: "conventional", "descriptive", "minimal" |
| session.persist | boolean | No | true | Whether to persist conversation history |
| session.path | path | No | ~/.local/share/opencode/sessions/ | Directory for session storage |
| shell.approval_required | boolean | No | true | Require user approval for shell commands |
| api.timeout | integer | No | 60 | Seconds before LLM API timeout |
| api.retries | integer | No | 1 | Number of retries on timeout |

**Validation rules**:
- `provider` must be empty or a recognized provider name
- `model` must be empty or a valid model identifier for the configured provider
- `agent.mode` must be "plan" or "build"
- `agent.commit_style` must be "conventional", "descriptive", or "minimal"
- `api.timeout` must be > 0 and <= 300
- `api.retries` must be >= 0 and <= 3

**Source precedence** (highest wins):
1. Command-line flags (if provided)
2. Environment variables (`OPENCODE_PROVIDER`, `OPENCODE_MODEL`)
3. Config file (`~/.config/opencode/config.yaml`)
4. Built-in defaults

### Session

A persistent conversation between the developer and the agent.

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique session identifier (auto-generated) |
| project_path | path | Working directory when session was created |
| created_at | timestamp | When the session started |
| updated_at | timestamp | Last activity timestamp |
| messages | list | Ordered conversation messages (user + assistant) |
| token_usage | object | Cumulative token counts (input, output, total) |
| files_referenced | list | Files read during this session |

**Lifecycle**:
- Created: When developer starts a new conversation
- Active: During interaction
- Suspended: When developer exits the agent
- Resumed: When developer selects this session on next start
- No explicit deletion (persists until container rebuild)

**Storage**: Plaintext files in `~/.local/share/opencode/sessions/` (one file per session).

### Code Change

A proposed set of file modifications (managed by OpenCode internally).

| Field | Type | Description |
|-------|------|-------------|
| files | list | Files to be modified (path + diff) |
| state | enum | "pending", "approved", "rejected" |
| commit_sha | string | Git commit SHA (only after approval and commit) |
| commit_message | string | Generated conventional commit message |

**State transitions**:
```
[proposed] → pending
pending → approved (user approves) → committed
pending → rejected (user rejects) → discarded
pending → stale (file modified externally) → warning shown
```

### Provider

An LLM service that the agent connects to.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Provider identifier (e.g., "openai", "anthropic") |
| api_key_env | string | Environment variable name containing the API key |
| base_url | string | API endpoint URL (default per provider) |

**Known providers and their env vars**:
| Provider | Env Var | Default Endpoint |
|----------|---------|-----------------|
| openai | OPENAI_API_KEY | https://api.openai.com/v1 |
| anthropic | ANTHROPIC_API_KEY | https://api.anthropic.com |
| ollama | — (no key needed) | http://localhost:11434 |

## Relationships

```
Configuration 1──1 Provider (selected provider)
Session *──1 Configuration (created with config at time of start)
Session 1──* Code Change (changes proposed during session)
Code Change *──* File (files affected by the change)
```

## File System Layout

```
~/.config/opencode/
└── config.yaml              # User/Chezmoi-managed configuration

~/.local/share/opencode/
└── sessions/
    ├── session-{id-1}.json  # Session 1 history
    ├── session-{id-2}.json  # Session 2 history
    └── ...
```

**Permissions**:
- `~/.config/opencode/config.yaml`: 0644 (readable, no secrets)
- `~/.local/share/opencode/sessions/*`: 0600 (owner only — may contain code snippets)
