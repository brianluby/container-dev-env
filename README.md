# container-dev-env

Reproducible, containerized development environments with optional AI coding assistants.

Who this is for:

- Developers who want a portable, pre-configured dev environment across machines
- Contributors who want a spec-driven workflow (specs/plans/tasks)
- Users who want optional AI tooling (OpenCode, Claude Code) inside the container

## Documentation

Start here:

- Getting started: `docs/getting-started/index.md`
- Features: `docs/features/index.md`
- Operations: `docs/operations/index.md`
- Contributing: `docs/contributing/index.md`
- Architecture: `docs/architecture/index.md`
- Reference: `docs/reference/index.md`
- Glossary: `docs/glossary.md`

If you are not sure where something lives, use `docs/navigation.md`.

## Quick start

These steps match `docs/getting-started/index.md`.

1. (Recommended) export your host UID/GID:

```bash
export LOCAL_UID="$(id -u)"
export LOCAL_GID="$(id -g)"
```

2. Build and start the dev container:

```bash
docker compose -f docker/docker-compose.yml up -d --build
```

3. Attach a shell:

```bash
docker compose -f docker/docker-compose.yml exec dev bash
```

4. Verify health (inside the container):

```bash
/usr/local/bin/health-check.sh
```

## Optional: secrets

Secrets are managed with Chezmoi + age encryption and injected as environment variables at runtime.

- Guide: `docs/features/secrets-management.md`
