# Quickstart: Agentic Assistant

**Feature Branch**: `006-agentic-assistant`
**Date**: 2026-01-22

## Prerequisites

- Docker 24+ with buildx support
- At least one LLM provider API key (Anthropic, OpenAI, Google, etc.)
- Container base image from PRD 001 (Debian Bookworm-slim)
- Secret injection configured per PRD 003
- Volume architecture per PRD 004

## Build

```bash
# Build with OpenCode only (default)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t devcontainer:agent .

# Build with both OpenCode + Claude Code
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg INSTALL_CLAUDE_CODE=true \
  -t devcontainer:agent-full .
```

## Run

```bash
# Start container with agent support
docker run -it \
  -v $(pwd):/workspace \
  -v agent-state:/home/developer/.local/share \
  -v agent-config:/home/developer/.config \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
  -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
  devcontainer:agent

# Inside container:
agent "Add error handling to all API endpoints"
```

## Docker Compose

```yaml
services:
  dev:
    build:
      context: .
      args:
        INSTALL_CLAUDE_CODE: "true"
    volumes:
      - .:/workspace
      - agent-state:/home/developer/.local/share
      - agent-config:/home/developer/.config
      - claude-state:/home/developer/.claude
    environment:
      - ANTHROPIC_API_KEY
      - OPENAI_API_KEY
      - AGENT_MODE=manual
    ports:
      - "4096:4096"  # Optional: headless server

volumes:
  agent-state:
  agent-config:
  claude-state:
```

## First Use

```bash
# 1. Verify installation
agent --version
opencode --version
claude --version  # if installed

# 2. Check configuration
agent config --validate

# 3. Run a simple task (manual mode - approve each action)
agent "List all TODO comments in the codebase"

# 4. Try autonomous mode on a safe task
agent --mode auto "Fix all lint warnings"

# 5. View what happened
agent log

# 6. Check token usage
agent usage
```

## Common Workflows

### Autonomous Refactoring

```bash
# Let the agent work freely with checkpoints
agent --mode auto "Refactor the user service to use repository pattern"

# If something went wrong:
agent checkpoints
agent rollback stash@{2}
```

### Interactive Code Review

```bash
# Manual mode: approve each change
agent --mode manual "Review and fix security issues in auth module"
```

### Resume After Interruption

```bash
# List previous sessions
agent sessions

# Resume the last one
agent --resume
```

### Headless Server (CI/CD)

```bash
# Start server with auth
export OPENCODE_SERVER_PASSWORD="secure-password"
agent --serve

# In another terminal or CI pipeline:
curl -u opencode:secure-password http://localhost:4096/api/run \
  -d '{"prompt": "Run tests and fix failures"}'
```

### Claude Code for Complex Tasks

```bash
# Use Claude Code for tasks needing sub-agents
agent --claude --mode auto "Implement the payment processing module with tests"
```

## File Exclusion

Create `.agentignore` in project root:

```gitignore
# Don't send these to the LLM
.env
.env.*
secrets/
*.key
config/production.yml
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Missing API key" (exit 3) | Set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` env var |
| "Backend not installed" (exit 4) | Rebuild container; check build args |
| "Provider unavailable" (exit 10) | Agent will pause and suggest alternatives; switch with `agent config` |
| Agent hangs on command | Default timeout is 300s; configure in `.agent.json` |
| Too many checkpoints using disk | Run `agent checkpoints --prune` or adjust retention in config |

## Configuration Reference

See `contracts/config-schema.md` for full schema. Quick config:

```json
// .agent.json (project root)
{
  "mode": "hybrid",
  "checkpoint": { "retention": { "max_count": 30 } },
  "shell": { "timeout_seconds": 120 }
}
```
