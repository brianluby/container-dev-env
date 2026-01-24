# Getting Started

This guide gets you from a fresh clone to a working shell in a reproducible
dev container, with optional secrets for AI tools.

## Prerequisites

- Docker Desktop or Docker Engine with Docker Compose v2
- A local checkout of this repository
- Optional (macOS): enable VirtioFS in Docker Desktop for faster bind mounts

## 1) Set UID/GID (recommended)

The container entrypoint aligns permissions using LOCAL_UID and LOCAL_GID.

```bash
export LOCAL_UID="$(id -u)"
export LOCAL_GID="$(id -g)"
```

If you skip this, the compose file defaults to 1000:1000.

## 2) Start the dev container

From the repo root (the workspace bind mount defaults to the repo root):

```bash
docker compose -f docker/docker-compose.yml up -d --build
```

What you get:

- Your repo mounted into `/workspace` for host IDE editing
- Caches and heavy I/O paths in named volumes for speed

To use a different workspace path, set `WORKSPACE_PATH` before running compose.

## 3) Attach a shell

```bash
docker compose -f docker/docker-compose.yml exec dev bash
```

## 4) Verify container health

Inside the container:

```bash
/usr/local/bin/health-check.sh
```

Optional from the host:

```bash
docker compose -f docker/docker-compose.yml ps
```

## 5) Verify volumes (optional)

From the repo root:

```bash
./scripts/volume-health.sh
```

This confirms the hybrid volume architecture (bind mount + named volumes).

## 6) Set up secrets (optional, recommended for AI tools)

Secrets are managed with Chezmoi + age encryption and injected at runtime.

Inside the container:

```bash
./scripts/secrets-setup.sh
chezmoi edit ~/.secrets.env
chezmoi apply
exit
```

Restart the container so secrets load at startup:

```bash
docker compose -f docker/docker-compose.yml restart
docker compose -f docker/docker-compose.yml exec dev bash
```

Verify (inside container):

```bash
./scripts/secrets-edit.sh validate
```

## 7) Stop or reset

Safe stop:

```bash
docker compose -f docker/docker-compose.yml down
```

Destructive reset (removes named volumes and persisted state):

```bash
docker compose -f docker/docker-compose.yml down -v
```

## Where things live

- Source code: `/workspace`
- Persistent home: `/home/dev` (named volume)
- Temp scratch: `/tmp` (tmpfs)

## Troubleshooting pointers

- Volume architecture: `docs/volume-architecture.md`
- Secrets setup: `docs/secrets-guide.md`
- Project navigation and tool context: `docs/navigation.md`
