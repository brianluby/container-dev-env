# Getting Started Troubleshooting

This page covers common failures when building, starting, or attaching to the development container.

Applies to: `main`

## Prerequisites

- You ran (or attempted) the [Getting Started](index.md) guide
- You can run `docker` and `docker compose` on the host

## Common problems

### Docker is not installed or not running

Symptoms:

- `docker: command not found`
- `Cannot connect to the Docker daemon`

Fix:

- Install Docker Engine (Linux) or Docker Desktop (macOS/Windows)
- Start the daemon / Docker Desktop

Verify:

```bash
docker version
docker compose version
```

### Docker Compose v2 is missing

Symptoms:

- `docker: 'compose' is not a docker command`

Fix:

- Install Docker Desktop (includes Compose)
- On Linux, install the Compose v2 plugin for your distro

Verify:

```bash
docker compose version
```

### Build fails (network, registry rate limiting)

Symptoms:

- `failed to solve: ...` during `docker compose ... --build`
- `429 Too Many Requests` pulling images

Fix:

- Retry; transient failures are common when pulling base images
- If you are hitting rate limits, authenticate to your registry (Docker Hub) or use a mirrored base image (if your org provides one)

Verify:

```bash
docker compose -f docker/docker-compose.yml build
```

### Container starts then exits immediately

Symptoms:

- `docker compose ps` shows `Exit 1`

Diagnosis:

```bash
docker compose -f docker/docker-compose.yml ps
docker compose -f docker/docker-compose.yml logs --no-color dev
```

Fix:

- Follow the last error in logs; common causes are missing files, permission problems, or a failing entrypoint step.

### Cannot attach (`docker compose exec` fails)

Symptoms:

- `service "dev" is not running`

Fix:

- Ensure the container is up:

```bash
docker compose -f docker/docker-compose.yml up -d
```

- Re-check status:

```bash
docker compose -f docker/docker-compose.yml ps
```

### Permissions / UID-GID mismatch

Symptoms:

- Files created in the container become unwritable on the host
- `Permission denied` writing under `/workspace`

Fix:

- Stop the container
- Export host UID/GID
- Start again

```bash
docker compose -f docker/docker-compose.yml down
export LOCAL_UID="$(id -u)"
export LOCAL_GID="$(id -g)"
docker compose -f docker/docker-compose.yml up -d --build
```

Verify:

Inside the container:

```bash
id
stat -c '%u:%g %n' /workspace 2>/dev/null || stat -f '%u:%g %N' /workspace
```

### macOS: bind mount is slow or files do not appear

Fix:

- Docker Desktop: enable VirtioFS
- Prefer keeping your repo on a local disk (avoid network home directories)

Verify:

- Edit a file on the host; ensure it updates inside `/workspace`

### Windows/WSL2: workspace path issues

Fix:

- Prefer cloning the repo inside WSL2 (Linux filesystem) instead of `C:\...`
- Ensure Docker Desktop is configured to use WSL2 integration

Verify:

- Run Compose from inside WSL2

### Line endings (CRLF) break shell scripts

Symptoms:

- `bash: ./script.sh: /usr/bin/env: bad interpreter: No such file or directory`

Fix:

- Configure git to avoid CRLF conversions for shell scripts
- Re-checkout after fixing git settings

Verify:

```bash
file scripts/*.sh | head -n 5
```

## Known issues

Some failures are currently known and tracked outside this docs overhaul:

- [Known Issues](../reference/known-issues.md)

## Related

- [Getting Started](index.md)
- [Operations Troubleshooting](../operations/troubleshooting.md)
- [Configuration Reference](../reference/configuration.md)

## Next steps

- If you are running maintenance tasks: [Operations](../operations/index.md)
- If you are enabling features: [Features](../features/index.md)
