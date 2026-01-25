# Runbook: Volume Cleanup

This runbook helps you reclaim disk space by pruning safe-to-remove Docker volumes used by the dev environment.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`
- You understand that removing volumes can delete cached data

## Symptoms

- Docker reports low disk space
- `docker system df` shows large volume usage
- Builds and installs slow down due to storage pressure

## Diagnosis

```bash
docker system df
docker volume ls
```

If you are using this repository's default Compose stack, look for volumes with names like `devenv-*`.

## Procedure

1. Stop the dev container:

```bash
docker compose -f docker/docker-compose.yml down
```

2. Identify candidate volumes:

```bash
docker volume ls | grep -E 'devenv-' || true
```

3. (Recommended) remove only known cache volumes first.

Examples of cache-like volumes in `docker/docker-compose.yml`:

- `devenv-npm-cache`
- `devenv-pip-cache`
- `devenv-cargo-registry`
- `devenv-node-modules`
- `devenv-cargo-target`

Remove a volume:

```bash
docker volume rm devenv-npm-cache
```

4. Start the container again:

```bash
docker compose -f docker/docker-compose.yml up -d
```

## Verification

```bash
docker system df
./scripts/volume-health.sh
```

Then reinstall dependencies as needed (cache volumes will be repopulated over time).

## Rollback / safety

- If you accidentally removed a persistent volume (for example `devenv-home`), the only recovery is restoring from backups.
- Prefer pruning caches first, not home/state volumes.

## Related

- `docs/operations/container-rebuild.md`
- `docs/architecture/volume-architecture.md`

## Next steps

- If the container is misbehaving after cleanup: `docs/operations/troubleshooting.md`
