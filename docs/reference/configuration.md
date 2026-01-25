# Configuration Reference

This page documents user-configurable settings for the development environment.
Settings are grouped by subsystem and follow a consistent per-setting schema.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`
- If you use secrets: `docs/features/secrets-management.md`

## Docker Compose (dev container)

### WORKSPACE_PATH

- Name/key: `WORKSPACE_PATH`
- Where: environment variable consumed by `docker/docker-compose.yml`
- Type: string (path)
- Default: `..` (repo root, relative to the Compose file under `docker/`)
- Allowed: any host path readable by Docker Desktop/Engine
- Security notes: avoid mounting sensitive directories into `/workspace`
- Example:

```bash
export WORKSPACE_PATH="/absolute/path/to/your/workspace"
docker compose -f docker/docker-compose.yml up -d --build
```

### LOCAL_UID / LOCAL_GID

- Name/key: `LOCAL_UID`, `LOCAL_GID`
- Where: environment variables consumed by `docker/docker-compose.yml` and entrypoint
- Type: integer
- Default: `1000` / `1000`
- Allowed: positive integers
- Security notes: incorrect values can cause permission problems on bind mounts
- Example:

```bash
export LOCAL_UID="$(id -u)"
export LOCAL_GID="$(id -g)"
docker compose -f docker/docker-compose.yml up -d --build
```

## AI assistants (agent wrapper)

### AGENT_BACKEND

- Name/key: `AGENT_BACKEND`
- Where: environment variable read by `agent`
- Type: string
- Default: `opencode`
- Allowed: `opencode`, `claude`
- Security notes: none
- Example:

```bash
export AGENT_BACKEND="claude"
agent "summarize docs/navigation.md"
```

### AGENT_MODE

- Name/key: `AGENT_MODE`
- Where: environment variable read by `agent`
- Type: string
- Default: `manual`
- Allowed: `manual`, `auto`, `hybrid`
- Security notes: `auto` may allow the tool to apply changes without prompting
- Example:

```bash
export AGENT_MODE="hybrid"
agent "rename variables for clarity"
```

### AGENT_STATE_DIR

- Name/key: `AGENT_STATE_DIR`
- Where: environment variable read by `agent`
- Type: string (path)
- Default: `~/.local/share/agent/`
- Allowed: any writable path inside the container
- Security notes: state may contain task history; keep permissions private
- Example:

```bash
export AGENT_STATE_DIR="$HOME/.local/share/agent"
agent status
```

### OPENCODE_SERVER_PASSWORD

- Name/key: `OPENCODE_SERVER_PASSWORD`
- Where: environment variable used by OpenCode server mode
- Type: string
- Default: unset
- Allowed: non-empty string
- Security notes: treat as a secret; set it via secrets injection (not in git)
- Example:

```bash
export OPENCODE_SERVER_PASSWORD="EXAMPLE_PASSWORD_VALUE"
agent --serve
```

### Provider API keys (examples)

- Name/key: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`
- Where: environment variables loaded via secrets management
- Type: string
- Default: unset
- Allowed: provider-specific
- Security notes: never commit; prefer secrets injection
- Example:

```env
OPENAI_API_KEY=EXAMPLE_OPENAI_API_KEY_VALUE
ANTHROPIC_API_KEY=EXAMPLE_ANTHROPIC_API_KEY_VALUE
```

## OpenCode configuration

### OPENCODE_PROVIDER / OPENCODE_MODEL / OPENCODE_MODE

- Name/key: `OPENCODE_PROVIDER`, `OPENCODE_MODEL`, `OPENCODE_MODE`
- Where: environment variables consumed by the Chezmoi template at `src/chezmoi/dot_config/opencode/config.yaml.tmpl`
- Type: string
- Default: provider/model are required for meaningful use; mode defaults to `build`
- Allowed:
  - provider: OpenCode provider IDs (example: `openai`, `anthropic`)
  - model: provider-specific model ID
  - mode: `plan`, `build`
- Security notes: provider/model are not secrets; API keys are secrets
- Example:

```bash
export OPENCODE_PROVIDER="openai"
export OPENCODE_MODEL="gpt-4o"
export OPENCODE_MODE="build"
```

## MCP

### .mcp/config.json

- Name/key: `mcpServers` entries
- Where: `/workspace/.mcp/config.json`
- Type: object
- Default: no config (you create it)
- Allowed: per `src/mcp/defaults/README.md`
- Security notes: use `${ENV_VAR}` references; do not inline credentials
- Example:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true
    }
  }
}
```

## Containerized IDE

### CONNECTION_TOKEN

- Name/key: `CONNECTION_TOKEN`
- Where: `.env` used by `src/docker/docker-compose.ide.yml`
- Type: string
- Default: unset (generate one)
- Allowed: any sufficiently random value
- Security notes: treat as a secret; do not commit `.env`
- Example:

```bash
./src/scripts/generate-token.sh > .env
docker compose -f src/docker/docker-compose.ide.yml up -d
```

## Mobile notifications

### NTFY_SERVER / NTFY_TOPIC / NTFY_TOKEN

- Name/key: `NTFY_SERVER`, `NTFY_TOPIC`, `NTFY_TOKEN`
- Where: environment variables + `~/.config/notify/notify.yaml`
- Type: string
- Default: unset
- Allowed: depends on your push service
- Security notes: `NTFY_TOKEN` is a secret
- Example:

```env
NTFY_SERVER=https://ntfy.sh
NTFY_TOPIC=example-topic
NTFY_TOKEN=EXAMPLE_NTFY_TOKEN_VALUE
```

## Related

- `docs/features/index.md`
- `docs/reference/search.md`

## Next steps

- If you want to enable a feature: `docs/features/index.md`
- If you want runbooks: `docs/operations/index.md`
