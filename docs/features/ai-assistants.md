# AI Assistants (OpenCode, Claude Code)

This project ships with terminal-first AI assistants so you can work in a consistent toolchain inside the container.
The recommended default is OpenCode, with optional Claude Code support.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`
- Secrets set up if you plan to use hosted models: `docs/features/secrets-management.md`

## What you get

- A unified wrapper (`agent`) that can run OpenCode or Claude Code
- Consistent configuration via environment variables
- Optional: headless server mode (OpenCode)

## Setup

1. Ensure at least one provider key is available in the container environment.

Recommended approach: manage keys via secrets injection so they load at container startup.

Examples (placeholders):

```env
OPENAI_API_KEY=EXAMPLE_OPENAI_API_KEY_VALUE
ANTHROPIC_API_KEY=EXAMPLE_ANTHROPIC_API_KEY_VALUE
GOOGLE_API_KEY=EXAMPLE_GOOGLE_API_KEY_VALUE
```

2. (Optional) choose defaults:

```bash
export AGENT_BACKEND="opencode"   # or: claude
export AGENT_MODE="manual"        # or: auto, hybrid
```

## Configuration

Common settings:

- `AGENT_BACKEND`: default backend (`opencode` or `claude`)
- `AGENT_MODE`: default approval mode (`manual`, `auto`, `hybrid`)
- Provider keys: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`

See the full reference: `docs/reference/configuration.md`

## Usage

Run a single task:

```bash
agent "explain how the container is started"
```

Force the Claude Code backend:

```bash
agent --claude "summarize the architecture overview"
```

Change approval mode for a run:

```bash
agent --mode auto "refactor this script to be shellcheck clean"
```

## Verification

Inside the container:

```bash
agent --version
agent config --validate
```

Then run a small prompt and verify you get a response.

## Optional: OpenCode headless server mode

Server mode requires authentication. Set a password via secrets injection or environment:

```bash
export OPENCODE_SERVER_PASSWORD="EXAMPLE_PASSWORD_VALUE"
agent --serve
```

## Troubleshooting

- Missing API key: confirm secrets loaded and the env var is present: `env | grep -E '^(OPENAI|ANTHROPIC|GOOGLE)_API_KEY='`
- Backend not installed: run `which opencode` / `which claude` and confirm the binary exists
- Rate limits: try again later or switch providers/models

## Related

- `docs/features/secrets-management.md`
- `docs/reference/configuration.md`
- `docs/reference/tool-compatibility.md`

## Next steps

- Add MCP tools: `docs/features/mcp.md`
- Add persistent memory: `docs/features/persistent-memory.md`
