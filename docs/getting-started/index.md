# Getting Started

This guide gets you from a fresh clone to a working shell in a reproducible development container.
It is written to be copy/paste friendly and to work without reading other pages (except where linked).

Applies to: `main`

Tested with: Docker Compose v2 (`docker compose`), Docker Desktop (recent versions)

## Prerequisites

- Docker Engine (Linux) or Docker Desktop (macOS/Windows)
- Docker Compose v2 (`docker compose ...`)
- Git
- Enough free disk space for images + named volumes (plan for multiple GB)

Optional but recommended:

- A working `bash` + standard UNIX tools on your host
- macOS: enable VirtioFS in Docker Desktop for faster bind mounts

## Quick start

1. (Recommended) export your host UID/GID for correct file ownership inside the container:

```bash
export LOCAL_UID="$(id -u)"
export LOCAL_GID="$(id -g)"
```

If you skip this, the Compose file defaults to `1000:1000`.

2. Build and start the dev container:

```bash
docker compose -f docker/docker-compose.yml up -d --build
```

3. Attach a shell:

```bash
docker compose -f docker/docker-compose.yml exec dev bash
```

## Verification checklist

Run these to confirm you have a healthy baseline.

Inside the container:

```bash
/usr/local/bin/health-check.sh
```

From the host (optional):

```bash
docker compose -f docker/docker-compose.yml ps
```

Verify the hybrid volume setup (optional):

```bash
./scripts/volume-health.sh
```

## Workspace path (optional)

By default, the container bind-mounts the repository root to `/workspace`.
If you want a different host path mounted as `/workspace`, set `WORKSPACE_PATH` before running Compose:

```bash
export WORKSPACE_PATH="/absolute/path/to/your/workspace"
docker compose -f docker/docker-compose.yml up -d --build
```

## Secrets (optional, recommended for AI tooling)

Secrets are managed with Chezmoi + age encryption and injected at runtime.

Inside the container:

```bash
./scripts/secrets-setup.sh
chezmoi edit ~/.secrets.env
chezmoi apply
exit
```

Restart so secrets load at container startup:

```bash
docker compose -f docker/docker-compose.yml restart
docker compose -f docker/docker-compose.yml exec dev bash
```

Validate (inside the container):

```bash
./scripts/secrets-edit.sh validate
```

## Stop, restart, reset

Safe stop:

```bash
docker compose -f docker/docker-compose.yml down
```

Destructive reset (removes named volumes and persisted state):

```bash
docker compose -f docker/docker-compose.yml down -v
```

## Host OS notes

macOS:

- Prefer VirtioFS for better bind mount performance.
- If you see permission issues, ensure you exported `LOCAL_UID`/`LOCAL_GID` before starting.

Linux:

- Prefer Docker Engine + Compose v2.
- If you use rootless Docker, ensure your user has access to the Docker socket and volume permissions behave as expected.

Windows:

- Prefer WSL2 + Docker Desktop.
- Keep the repo inside your Linux filesystem (e.g. `~/src/...`) for better performance and fewer path issues.

## Related

- `docs/features/index.md`
- `docs/operations/index.md`
- `docs/reference/configuration.md`

## Next steps

- If setup failed: `docs/getting-started/troubleshooting.md`
- Enable AI assistants: `docs/features/ai-assistants.md`
