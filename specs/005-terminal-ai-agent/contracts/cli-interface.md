# CLI Interface Contract: OpenCode Agent

**Date**: 2026-01-22
**Feature**: 005-terminal-ai-agent

## Binary Location

```
/usr/local/bin/opencode
```

## Invocation

```bash
# Interactive TUI mode (primary usage)
opencode

# One-shot mode with inline prompt
opencode "add a function to parse JSON from file"

# Version check (used in smoke tests)
opencode --version

# Help
opencode --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (normal exit or task completed) |
| 1 | General error (unspecified) |
| 2 | Configuration error (missing API key, invalid config) |
| 127 | Binary not found (installation failed) |

## Startup Behavior

1. Read configuration from `~/.config/opencode/config.yaml`
2. Read API key from environment variable (based on configured provider)
3. If no provider configured: display error with setup instructions
4. If no API key found: display error naming the required env var
5. If all valid: initialize TUI within 3 seconds

## Agent Modes

| Mode | Description | File Access | Shell Access |
|------|-------------|-------------|--------------|
| `plan` | Read-only analysis and planning | Read only | No |
| `build` | Full development with modifications | Read/Write | With approval |

## User Interaction Flow

```
Developer types prompt
    → Agent reads project files for context
    → Agent sends prompt + context to LLM API (60s timeout, 1 retry)
    → Agent receives generated response
    → Agent displays proposed changes as diff
    → Developer approves or rejects
        → If approved: write files, git commit (current branch)
        → If rejected: discard, await next prompt
        → If file conflict detected: warn, ask to re-request
```

## Shell Command Approval

When the agent proposes a shell command:

```
Agent: I'd like to run: `npm test`
       [Approve] [Deny]
```

- Approval: command executes, output displayed
- Denial: command skipped, agent continues without it

## Auto-Commit Format

Commits created by the agent follow conventional commit format:

```
<type>(<scope>): <description>

<body - what was changed and why>
```

Types: feat, fix, refactor, docs, test, chore
Scope: inferred from modified files
