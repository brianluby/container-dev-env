# Containerized IDE (OpenVSCode Server)

This feature runs a browser-based IDE inside a container so you can develop from any machine with a web browser.

Applies to: `main`

## Prerequisites

- Docker + Compose v2
- [Getting Started](../getting-started/index.md) (recommended baseline)

## Setup

1. Generate a connection token (treat it like a password):

```bash
./src/scripts/generate-token.sh > .env
```

2. Start the IDE:

```bash
docker compose -f docker/docker-compose.ide.yml up -d
```

3. Access the IDE in a browser:

- URL: `http://localhost:3000/?tkn=<token-from-.env>`

## Configuration

- `CONNECTION_TOKEN` is read from `.env` (treat it like a password)
- Optional extensions can be declared in `src/config/extensions.json`

## Verification

```bash
docker compose -f docker/docker-compose.ide.yml ps
```

If the container is healthy, the IDE should load and provide a terminal and file explorer.

## Troubleshooting

- 401 unauthorized: token mismatch; regenerate `.env` and restart the IDE container
- connection refused: container not running; check `docker compose ... ps` and `docker compose ... logs`

## Related

- [IDE Extensions](ide-extensions.md)
- [Configuration Reference](../reference/configuration.md)

## Next steps

- Add AI IDE extensions: [IDE Extensions](ide-extensions.md)
