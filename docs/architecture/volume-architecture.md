# Volume Architecture

This page describes the hybrid volume architecture used by the dev container.
It balances host IDE ergonomics, container I/O performance, and persistence.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`

## Overview

The architecture balances three competing concerns:

1. **Host IDE Access**: Source code must be editable from host IDE with <1 second sync
2. **Performance**: Package caches and build artifacts need native filesystem speed
3. **Persistence**: Development environment state should survive container restarts

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    Development Container                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  /workspace ←──── Bind Mount (host source code)                 │
│       │                                                          │
│       ├── /workspace/node_modules ←── Named Volume (fast I/O)  │
│       └── /workspace/target ←──────── Named Volume (fast I/O)  │
│                                                                  │
│  /home/dev ←───── Named Volume (persistent config)              │
│       ├── .npm ←── Named Volume (npm cache)                     │
│       ├── .cache/pip ←── Named Volume (pip cache)               │
│       └── .cargo/registry ←── Named Volume (cargo cache)        │
│                                                                  │
│  /tmp ←────────── tmpfs (ephemeral, auto-clean)                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Volume Types Explained

### Bind Mounts (Source Code)

**Path**: `/workspace`

Bind mounts map a host directory directly into the container. Changes made on either side are immediately visible to the other.

**Use case**: Source code editing with your host IDE (VS Code, IntelliJ, etc.)

**Characteristics**:
- Real-time sync between host and container
- Survives all Docker operations (data lives on host)
- Uses `:cached` consistency flag for optimal IDE write performance
- Performance varies by platform (excellent on Linux, good on macOS with VirtioFS)

### Named Volumes (Persistent Data)

**Paths**: `/home/dev`, cache directories, build output directories

Named volumes are managed by Docker and stored in Docker's data directory. They provide native filesystem performance within containers.

**Use cases**:
- Shell history and dotfiles (`/home/dev`)
- Package manager caches (npm, pip, cargo)
- Build artifacts (node_modules, target)

**Characteristics**:
- Native filesystem performance (10x faster than bind mounts for I/O-heavy operations)
- Persist across container restarts
- Survive `docker system prune` (named volumes are protected)
- Require explicit `docker volume rm` to delete

### tmpfs (Ephemeral Storage)

**Path**: `/tmp`

tmpfs is an in-memory filesystem that is extremely fast but completely ephemeral.

**Use case**: Temporary files that should be cleaned automatically

**Characteristics**:
- RAM-speed I/O performance
- Automatically cleared on container restart
- Size-limited (512MB by default) to prevent memory exhaustion
- World-writable with sticky bit (mode 1777)

## Persistence Model

| Path | Type | Persists Across Restart | Survives Prune | Safe to Delete |
|------|------|------------------------|----------------|----------------|
| `/workspace` | Bind Mount | Yes (host filesystem) | Yes | N/A (host data) |
| `/home/dev` | Named Volume | Yes | Yes | **No** (loses config) |
| `/home/dev/.npm` | Named Volume | Yes | Yes | Yes (rebuilds) |
| `/home/dev/.cache/pip` | Named Volume | Yes | Yes | Yes (rebuilds) |
| `/home/dev/.cargo/registry` | Named Volume | Yes | Yes | Yes (rebuilds) |
| `/workspace/node_modules` | Named Volume | Yes | Yes | Yes (rebuilds) |
| `/workspace/target` | Named Volume | Yes | Yes | Yes (rebuilds) |
| `/tmp` | tmpfs | **No** | N/A | N/A (auto-cleaned) |

## Common Scenarios FAQ

### Q: I edited a file in VS Code but don't see changes in the container

**A**: This shouldn't happen with VirtioFS on modern Docker Desktop. Check that:
1. You're editing files within the mounted workspace directory
2. The container is running (files sync in real-time, not on restart)
3. Your Docker Desktop is using VirtioFS (Settings → Resources → File Sharing)

### Q: My shell history/aliases disappeared after rebuilding the image

**A**: This shouldn't happen. Shell history and dotfiles are stored in the `/home/dev` named volume, which is independent of the image. If this occurs:
1. Check that the container was started with the correct volume mounts
2. Run `./scripts/volume-health.sh` to verify volume status

### Q: npm install is slow

**A**: Ensure node_modules is on a named volume, not the bind mount:
```bash
# Check where node_modules is mounted
docker compose exec dev mount | grep node_modules
```
The output should show a Docker volume, not a bind mount.

### Q: I want to start fresh with a clean environment

**A**: Different levels of "fresh":

```bash
# Remove only cache volumes (keeps shell config)
docker volume rm devenv-npm-cache devenv-pip-cache devenv-cargo-registry

# Remove all devenv volumes (full reset)
docker volume rm $(docker volume ls -q | grep '^devenv-')

# Nuclear option: remove everything
docker compose down -v
```

### Q: Will my code be deleted if I run docker system prune?

**A**: No. Your source code is on the host filesystem (bind mount), completely outside Docker's control. Named volumes also survive `docker system prune` because they have explicit names.

## Troubleshooting

### Issue: Permission denied errors

**Symptoms**: Cannot write to `/workspace`, `/home/dev`, or cache directories

**Solution**: The entrypoint script should fix permissions automatically. If issues persist:

1. Check your LOCAL_UID and LOCAL_GID environment variables match your host user:
   ```bash
   echo "LOCAL_UID=$(id -u) LOCAL_GID=$(id -g)"
   ```

2. Manually fix permissions:
   ```bash
   docker compose exec dev sudo chown -R dev:dev /home/dev
   ```

### Issue: Volume not found

**Symptoms**: Container fails to start with volume mount error

**Solution**:
1. Ensure Docker Compose version is 2.x or higher
2. Try recreating volumes:
   ```bash
   docker compose down
   docker compose up
   ```

### Issue: Disk space running low

**Symptoms**: Build failures, "no space left on device" errors

**Solution**: Clean cache volumes (safe to delete, will rebuild):
```bash
docker volume rm devenv-npm-cache devenv-pip-cache devenv-cargo-registry
docker volume rm devenv-node-modules devenv-cargo-target
```

### Issue: Changes in /tmp persist (shouldn't happen)

**Symptoms**: Files in /tmp survive container restart

**Solution**: Verify tmpfs is configured:
```bash
docker compose exec dev df -T /tmp
# Should show "tmpfs" as filesystem type
```

## Diagnostic Commands

Check volume status:
```bash
./scripts/volume-health.sh
```

View all devenv volumes:
```bash
docker volume ls | grep devenv
```

Inspect a specific volume:
```bash
docker volume inspect devenv-home
```

## Related

- `docs/getting-started/index.md`
- `docs/operations/volume-cleanup.md`

## Next steps

- If disk space is low: `docs/operations/volume-cleanup.md`
```

Check mount points inside container:
```bash
docker compose exec dev mount | grep -E "(workspace|home|tmp)"
```

## Further Reading

- [Docker Volumes Documentation](https://docs.docker.com/storage/volumes/)
- [Docker Compose Volume Configuration](https://docs.docker.com/compose/compose-file/07-volumes/)
- [VirtioFS for macOS](https://docs.docker.com/desktop/settings/mac/#file-sharing)
