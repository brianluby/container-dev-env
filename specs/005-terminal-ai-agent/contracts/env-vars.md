# Environment Variable Contract: Terminal AI Agent

**Date**: 2026-01-22
**Feature**: 005-terminal-ai-agent

## Required Environment Variables

At least ONE provider API key must be set for the agent to function.

| Variable | Provider | Required | Format | Example |
|----------|----------|----------|--------|---------|
| OPENAI_API_KEY | OpenAI | Conditional | `sk-...` (51 chars) | `sk-abc123...` |
| ANTHROPIC_API_KEY | Anthropic | Conditional | `sk-ant-...` (variable) | `sk-ant-abc123...` |

**Conditional requirement**: At least one API key must be present. If none are set, the agent exits with code 2 and a descriptive error.

## Optional Environment Variables

| Variable | Purpose | Default | Valid Values |
|----------|---------|---------|--------------|
| OPENCODE_PROVIDER | Override configured provider | (from config.yaml) | openai, anthropic, ollama, azure, ... |
| OPENCODE_MODEL | Override configured model | (from config.yaml) | Provider-specific model ID |
| OPENCODE_MODE | Override agent mode | build | plan, build |

## Variable Source

All environment variables are injected by **003-secret-injection** at container start:

```
003-secret-injection decrypts age-encrypted secrets
    → Exports as environment variables
    → Available to all processes in container
    → Never written to disk
```

## Validation Rules

- API keys are validated by attempting a lightweight API call on first use
- Invalid keys result in a clear error message with the provider's dashboard URL
- Keys with insufficient quota trigger a specific quota-exceeded error (exit code 2)
- Environment variable names are case-sensitive

## Security Constraints

- API keys MUST NOT appear in:
  - Log output (any verbosity level)
  - Error messages (mask all but last 4 characters)
  - Session history files
  - Git commits or diffs
  - Process arguments visible in `ps`

- API keys are read ONCE at startup and held in process memory only
- No key refresh mechanism needed (keys are long-lived)

## Integration with 003-secret-injection

The agent expects 003-secret-injection to have already run before the agent starts. If secrets are not yet injected:

```bash
# User sees this error:
"Error: No API key found. Expected one of: OPENAI_API_KEY, ANTHROPIC_API_KEY
Ensure secrets are loaded (see 003-secret-injection docs)."
```

## Testing Contract

```bash
# Verify API key is available (contract test)
test -n "${OPENAI_API_KEY:-}" || test -n "${ANTHROPIC_API_KEY:-}"

# Verify no key in process args
ps aux | grep opencode | grep -v grep | grep -qv "sk-"
```
