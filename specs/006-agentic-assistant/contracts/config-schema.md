# Configuration Schema Contract

**Version**: 1.0.0
**Date**: 2026-01-22

## Agent Wrapper Configuration

**File**: `~/.config/agent/config.json` (global) or `.agent.json` (project)
**Format**: JSON

```json
{
  "$schema": "https://container-dev-env/schemas/agent-config.json",
  "backend": "opencode | claude",
  "mode": "manual | auto | hybrid",
  "checkpoint": {
    "enabled": true,
    "retention": {
      "max_count": 50,
      "max_age_days": 30
    },
    "auto_prune": true
  },
  "exclusions": {
    "file": ".agentignore",
    "defaults": true
  },
  "logging": {
    "action_log": true,
    "format": "jsonl",
    "directory": "~/.local/share/agent/logs"
  },
  "providers": {
    "failover": "pause",
    "retry": {
      "max_attempts": 3,
      "backoff_seconds": [5, 15, 60]
    }
  },
  "shell": {
    "timeout_seconds": 300,
    "dangerous_patterns": [
      "rm -rf",
      "git push --force",
      "git reset --hard",
      "chmod 777",
      "dd if=",
      "> /dev/"
    ]
  }
}
```

## .agentignore File

**Location**: Project root (`/workspace/.agentignore`)
**Format**: Gitignore-compatible glob patterns (one per line)
**Purpose**: Files/directories the agent must not read or send to LLM providers

### Default Patterns (applied even without file)

```gitignore
# Secrets and credentials
.env
.env.*
*.pem
*.key
*.p12
*.pfx
credentials/
secrets/
.secret*

# Auth tokens
.npmrc
.pypirc
.docker/config.json

# Databases with potential sensitive data
*.sqlite
*.db

# SSH keys
.ssh/
id_rsa*
id_ed25519*
```

### Custom Pattern Example

```gitignore
# Project-specific exclusions
config/production.yml
internal/proprietary/
data/customer-exports/
```

## Session Metadata Schema

**File**: `$AGENT_STATE_DIR/sessions/{uuid}.json`
**Format**: JSON

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "backend": "opencode",
  "started_at": "2026-01-22T10:00:00Z",
  "ended_at": null,
  "status": "active",
  "task_description": "Refactor auth module",
  "approval_mode": "hybrid",
  "workspace": "/workspace",
  "checkpoints": [
    {
      "id": "stash@{0}",
      "created_at": "2026-01-22T10:05:00Z",
      "description": "Before renaming AuthService",
      "operation_type": "multi_file",
      "status": "passed",
      "files_affected": ["src/auth.rs", "src/main.rs", "tests/auth_test.rs"]
    }
  ],
  "token_usage": {
    "input_tokens": 45000,
    "output_tokens": 12000,
    "total_tokens": 57000,
    "estimated_cost_usd": 0.85,
    "model": "claude-sonnet-4-20250514",
    "provider": "anthropic"
  },
  "action_log_path": "~/.local/share/agent/logs/550e8400.jsonl"
}
```

## Action Log Entry Schema

**File**: `$AGENT_STATE_DIR/logs/{session-id}.jsonl`
**Format**: JSON Lines (one JSON object per line)

```json
{"timestamp":"2026-01-22T10:00:00Z","action":"checkpoint","target":"stash@{0}","details":"Pre-operation checkpoint","result":"success"}
{"timestamp":"2026-01-22T10:00:01Z","action":"file_edit","target":"src/auth.rs","details":"Renamed AuthService to AuthenticationService","result":"success"}
{"timestamp":"2026-01-22T10:00:02Z","action":"file_edit","target":"src/main.rs","details":"Updated import for AuthenticationService","result":"success"}
{"timestamp":"2026-01-22T10:00:03Z","action":"command_exec","target":"cargo test","details":"Running test suite","result":"success"}
{"timestamp":"2026-01-22T10:00:10Z","action":"checkpoint","target":"stash@{1}","details":"Post-operation checkpoint (passed)","result":"success"}
```

### Action Types

| Action | Description | Target Format |
|--------|-------------|---------------|
| `file_edit` | Modified existing file | File path |
| `file_create` | Created new file | File path |
| `file_delete` | Deleted file | File path |
| `command_exec` | Ran shell command | Command string |
| `checkpoint` | Created/restored checkpoint | Checkpoint ID |
| `rollback` | Rolled back to checkpoint | Checkpoint ID |
| `decision` | Agent made a routing decision | Decision description |
| `error` | Error occurred | Error context |
| `sub_agent_spawn` | Spawned sub-agent | Sub-agent ID |
| `sub_agent_complete` | Sub-agent finished | Sub-agent ID |
| `provider_switch` | Developer switched LLM provider | Provider name |
| `session_pause` | Session paused (provider unavailable, etc.) | Reason |
| `session_resume` | Session resumed | Previous session ID |
