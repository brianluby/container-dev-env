# Quickstart: Volume Architecture

**Feature**: 004-volume-architecture
**Date**: 2026-01-20

## Prerequisites

- Docker Desktop 4.6+ (with VirtioFS enabled - default on macOS)
- Docker Compose v2.x
- Project source code on host machine

## Quick Start

### 1. Set Environment Variables (macOS)

```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc)
export LOCAL_UID=$(id -u)  # macOS: 501, Linux: typically 1000
export LOCAL_GID=$(id -g)  # macOS: 20, Linux: typically 1000
```

### 2. Start the Container

```bash
# From project root
docker compose up -d

# Or with VS Code
code --folder-uri vscode-remote://dev-container+$(pwd)/workspace
```

### 3. Verify Volumes

```bash
# Check volume status (from project root)
./scripts/volume-health.sh

# Or from inside container, check entrypoint logs
docker compose logs dev | grep "Volume Status" -A 10
```

## Volume Architecture Overview

| Path | Type | Persistence | Purpose |
|------|------|-------------|---------|
| `/workspace` | Bind mount | Permanent | Source code (host IDE access) |
| `/home/dev` | Named volume | Session | Shell history, config, tools |
| `/home/dev/.npm` | Named volume | Session | npm cache (fast installs) |
| `/workspace/node_modules` | Named volume | Session | Dependencies (10x faster) |
| `/tmp` | tmpfs | Ephemeral | Temporary files (cleared on restart) |

## Common Operations

### Edit Source Code

```bash
# Edit on host (your IDE)
vim ~/projects/myapp/src/index.ts

# Changes visible in container immediately (<1 second)
docker compose exec dev cat /workspace/src/index.ts
```

### Install Dependencies (Fast!)

```bash
# In container - uses named volume (10x faster)
docker compose exec dev npm install

# Expected: 50+ packages in ~5 seconds (not 60+ seconds)
```

### Preserve Shell History

```bash
# Your history persists across restarts
docker compose restart dev
docker compose exec dev history | tail -5
```

### Clean Temporary Files

```bash
# Restart clears /tmp automatically
docker compose restart dev
docker compose exec dev ls /tmp  # Empty!
```

## Permission Issues?

If you see permission errors:

```bash
# Check your UID
id -u  # Should show 501 (macOS) or 1000 (Linux)

# Ensure environment variables are set
echo $LOCAL_UID $LOCAL_GID

# Force permission fix
docker compose exec dev sudo chown -R $(id -u):$(id -g) /home/dev
```

## Data Safety

### Safe Operations
- `docker compose down` - Source code preserved (bind mount)
- `docker compose restart` - All named volumes preserved
- `docker system prune` - Named volumes preserved (explicit names)

### Destructive Operations
- `docker volume rm devenv-home` - Loses home directory config
- `docker volume prune -f` - Loses all caches (need confirmation)

## Performance Tips

1. **Keep node_modules on named volume** - 10-19x faster npm install
2. **Use `:cached` flag** - Optimizes IDE → container sync
3. **Increase tmpfs size** for large builds: `tmpfs: /tmp:size=1G`

## Troubleshooting

### Container won't start

```bash
# Check if workspace path exists
ls -la ./src  # Should exist

# Check logs for error
docker compose logs dev | grep entrypoint
```

### Files not syncing

```bash
# Verify VirtioFS is enabled (Docker Desktop)
# Settings > Resources > File sharing > VirtioFS

# Check mount status
docker compose exec dev mount | grep workspace
```

### Permission denied errors

```bash
# Check current ownership
docker compose exec dev ls -la /workspace

# Fix if needed
docker compose exec dev sudo chown -R $LOCAL_UID:$LOCAL_GID /workspace
```

## Next Steps

- Read full documentation: `docs/volume-architecture.md`
- Review docker compose.yml volume configuration
- Test with your project's dependency installation
