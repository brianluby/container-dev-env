# Container Interface Contract: Agent Layer

**Version**: 1.0.0
**Date**: 2026-01-22

## Dockerfile Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `INSTALL_CLAUDE_CODE` | `false` | Install Claude Code as optional secondary agent |
| `OPENCODE_VERSION` | `0.5.2` | Pin OpenCode to specific release version (REQUIRED, no `latest`) |
| `CLAUDE_CODE_VERSION` | `1.0.23` | Pin Claude Code to specific release version |
| `AGENT_USER` | `developer` | Non-root user to run agents as |

## Volume Mounts

| Mount Point | Purpose | Required | Persist Across |
|-------------|---------|----------|----------------|
| `/workspace` | Project source code | Yes | Restarts + Rebuilds |
| `/home/${AGENT_USER}/.local/share/opencode` | OpenCode state (auth, sessions) | Yes | Restarts |
| `/home/${AGENT_USER}/.config/opencode` | OpenCode configuration | Yes | Restarts |
| `/home/${AGENT_USER}/.claude` | Claude Code state (sessions, settings) | Conditional | Restarts |
| `/home/${AGENT_USER}/.local/share/agent` | Wrapper state (logs, session metadata) | Yes | Restarts |

## Environment Variables (Runtime)

| Variable | Classification | Injected By | Description |
|----------|---------------|-------------|-------------|
| `ANTHROPIC_API_KEY` | Restricted | PRD 003 | Anthropic API key |
| `OPENAI_API_KEY` | Restricted | PRD 003 | OpenAI API key |
| `GOOGLE_API_KEY` | Restricted | PRD 003 | Google API key |
| `AWS_ACCESS_KEY_ID` | Restricted | PRD 003 | AWS Bedrock access |
| `AWS_SECRET_ACCESS_KEY` | Restricted | PRD 003 | AWS Bedrock secret |
| `AGENT_BACKEND` | Internal | User config | Backend selection |
| `AGENT_MODE` | Internal | User config | Default approval mode |
| `OPENCODE_SERVER_PASSWORD` | Restricted | PRD 003 | Headless server auth |

## Exposed Ports

| Port | Service | Condition |
|------|---------|-----------|
| 4096 | OpenCode headless server | Only when `agent --serve` is running |

## Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD opencode --version > /dev/null 2>&1 || exit 1
```

## Container User

```dockerfile
# Agent MUST run as non-root (FR-012, SEC-1)
USER ${AGENT_USER}
WORKDIR /workspace
```

## Resource Expectations

| Resource | Minimum | Recommended | Notes |
|----------|---------|-------------|-------|
| Memory | 2 GB | 4 GB | LLM context windows can be large |
| CPU | 1 core | 2 cores | Sub-agents benefit from parallelism |
| Disk (agent layer) | 200 MB | 500 MB | Both agents installed |
| Disk (state volume) | 100 MB | 1 GB | Grows with session history |

## Filesystem Permissions

| Path | Owner | Mode | Notes |
|------|-------|------|-------|
| `/workspace` | `${AGENT_USER}` | 755 | Project files (read/write) |
| `~/.local/share/agent` | `${AGENT_USER}` | 700 | Private state (logs, sessions) |
| `~/.config/opencode` | `${AGENT_USER}` | 700 | Private config |
| `~/.claude` | `${AGENT_USER}` | 700 | Private state |
| `/usr/local/bin/agent` | root | 755 | Wrapper script (read/exec) |
| `/usr/local/bin/opencode` | root | 755 | OpenCode binary (read/exec) |
| `/usr/local/bin/claude` | root | 755 | Claude Code binary (read/exec) |

## Network Access

| Direction | Destination | Protocol | Purpose |
|-----------|-------------|----------|---------|
| Outbound | `api.anthropic.com` | HTTPS (443) | Anthropic API |
| Outbound | `api.openai.com` | HTTPS (443) | OpenAI API |
| Outbound | `generativelanguage.googleapis.com` | HTTPS (443) | Google Gemini |
| Outbound | `openrouter.ai` | HTTPS (443) | OpenRouter |
| Outbound | `*.bedrock.*.amazonaws.com` | HTTPS (443) | AWS Bedrock |
| Inbound | localhost:4096 | HTTP | Headless server (optional) |
| **Denied** | All other inbound | * | No inbound except headless |
