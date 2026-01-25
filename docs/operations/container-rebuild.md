# Runbook: Container Rebuild

This runbook helps you rebuild the dev container image and recreate the container when dependencies or base layers change.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`

## Symptoms

- Dockerfile changes are not reflected in the running container
- You suspect the image is corrupted or out of date
- A dependency install during build failed and you want a clean rebuild

## Diagnosis

```bash
docker compose -f docker/docker-compose.yml ps
docker images | head -n 5
```

## Procedure

1. Stop the container:

```bash
docker compose -f docker/docker-compose.yml down
```

2. Rebuild and recreate:

```bash
docker compose -f docker/docker-compose.yml up -d --build
```

3. Re-attach:

```bash
docker compose -f docker/docker-compose.yml exec dev bash
```

## Verification

Inside the container:

```bash
/usr/local/bin/health-check.sh
```

## Rollback / safety

- If you need a truly clean rebuild, you can remove the image and rebuild. Be aware this will re-download layers:

```bash
docker image rm devenv:latest
docker compose -f docker/docker-compose.yml build
```

- Avoid removing named volumes unless you intend to lose persisted state.

## Related

- `docs/operations/volume-cleanup.md`
- `docs/getting-started/troubleshooting.md`

## Next steps

- If problems persist: `docs/operations/troubleshooting.md`
