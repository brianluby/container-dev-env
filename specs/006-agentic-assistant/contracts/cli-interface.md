# CLI Interface Contract: `agent` Wrapper

**Version**: 1.0.0
**Date**: 2026-01-22

## Command Syntax

```
agent [OPTIONS] [TASK_DESCRIPTION]
agent <SUBCOMMAND>
```

## Options

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--claude` | | bool | false | Force Claude Code backend |
| `--mode` | `-m` | enum | manual | Approval mode: `manual`, `auto`, `hybrid` |
| `--resume` | `-r` | bool | false | Resume previous session |
| `--serve` | | bool | false | Start headless server (OpenCode only) |
| `--format` | `-f` | enum | text | Output format: `text`, `json` |
| `--version` | `-V` | bool | | Print version and exit |
| `--help` | `-h` | bool | | Print help and exit |

## Subcommands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `agent log` | View action log for current/specified session | `[--session ID]` `[--tail N]` `[--format json\|text]` |
| `agent checkpoints` | List checkpoints | `[--session ID]` |
| `agent rollback` | Rollback to checkpoint | `<CHECKPOINT_ID>` |
| `agent usage` | Display token/cost metrics | `[--session ID]` `[--format json\|text]` |
| `agent sessions` | List all sessions | `[--status active\|completed\|all]` |
| `agent status` | Show current session status | |
| `agent bg` | List background tasks | `[--kill ID]` |
| `agent config` | Show effective configuration | `[--validate]` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Missing API key |
| 4 | Backend tool not installed |
| 5 | Session not found (for --resume) |
| 6 | Checkpoint not found (for rollback) |
| 10 | Provider unavailable (after retries) |
| 11 | Rate limited (after backoff exhausted) |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | For Claude Code | Anthropic API key |
| `OPENAI_API_KEY` | For OpenCode/OpenAI | OpenAI API key |
| `GOOGLE_API_KEY` | For OpenCode/Gemini | Google API key |
| `AGENT_BACKEND` | No | Default backend: `opencode` (default) or `claude` |
| `AGENT_MODE` | No | Default approval mode: `manual` (default), `auto`, `hybrid` |
| `AGENT_STATE_DIR` | No | Override state directory (default: `~/.local/share/agent/`) |
| `OPENCODE_SERVER_PASSWORD` | No | Authentication for headless server mode |

## Standard I/O Behavior

- **stdin**: Task description (alternative to positional argument)
- **stdout**: Agent output, status messages, results
- **stderr**: Errors, warnings, progress indicators
- **JSON mode** (`--format json`): Structured output on stdout; errors as JSON on stderr

## Examples

```bash
# Start autonomous task
agent --mode auto "Refactor the auth module to use dependency injection"

# Resume previous session
agent --resume

# Force Claude Code backend
agent --claude "Add comprehensive error handling to all API endpoints"

# View what the agent did
agent log --tail 20

# Rollback last change
agent rollback stash@{0}

# Check spending
agent usage

# Start headless server
agent --serve

# Non-interactive with JSON output
echo "Fix lint errors" | agent --format json
```
