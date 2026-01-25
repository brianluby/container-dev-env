# Persistent Memory

Persistent memory adds two layers of "remembering" for AI workflows:

- Strategic memory: versioned Markdown files committed with the project (`.memory/`)
- Tactical memory: persisted per-user state on a Docker volume (not committed)

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`
- MCP set up (recommended): `docs/features/mcp.md`

## Setup

1. Initialize strategic memory in your project workspace:

```bash
memory-init
```

2. Edit at least one memory file:

```bash
$EDITOR .memory/architecture.md
```

## Configuration

- Strategic memory lives in `.memory/*.md` (version-controlled)
- Tactical memory lives in the memory server's persisted storage (not committed)

## Verification

- Strategic memory exists:

```bash
ls -la .memory/
```

- Memory server health check (if available):

```bash
python -m memory_server --health-check
```

## Troubleshooting

- AI "doesn't know" the project: make sure `.memory/*.md` contains real context
- Memory resets after restart: confirm the memory volume is mounted (see `docker/docker-compose.yml` `mcp-memory` volume)

## Related

- `docs/features/mcp.md`
- `docs/reference/configuration.md`

## Next steps

- Try a feature workflow: `docs/features/ai-assistants.md`
