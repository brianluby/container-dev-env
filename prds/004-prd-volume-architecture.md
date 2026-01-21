# 004-prd-volume-architecture

## Problem Statement

Container filesystems are ephemeral by default—data is lost when containers stop.
Development workflows require persistence for source code, dependencies, and user
configuration, but also benefit from ephemeral storage for build artifacts and
temporary files. Without clear volume boundaries, developers face data loss,
permission conflicts, slow bind mounts (especially on macOS), and confusion about
what persists versus what resets. A well-designed volume architecture establishes
clear boundaries between workspace, home, and ephemeral storage to optimize for
both persistence and performance.

## Requirements

### Must Have (M)

- [ ] Source code persists across container restarts (workspace volume)
- [ ] User configuration persists (home directory or subset)
- [ ] Clear documentation of what persists vs what resets
- [ ] No permission conflicts between host and container users
- [ ] Works with the container base image (001-prd-container-base)
- [ ] Compatible with VS Code devcontainers and docker-compose

### Should Have (S)

- [ ] Build artifacts and caches persist for performance (node_modules, .cache, target/)
- [ ] Temporary/ephemeral storage clearly separated (resets on restart)
- [ ] Reasonable performance on macOS (mitigate bind mount slowness)
- [ ] Named volumes for data that should survive `docker system prune`
- [ ] Works with dotfile management (002-prd-dotfile-management)
- [ ] Works with secret injection (003-prd-secret-injection)

### Could Have (C)

- [ ] Multiple workspace support (polyrepo development)
- [ ] Shared cache volumes across projects (npm, pip, cargo caches)
- [ ] Snapshot/backup capability for workspace state
- [ ] Performance profiles (fast-but-ephemeral vs slow-but-persistent)
- [ ] Volume encryption for sensitive workspaces

### Won't Have (W)

- [ ] Network-attached storage (NAS/NFS) configuration
- [ ] Distributed filesystem support (GlusterFS, Ceph)
- [ ] Database volume management (separate concern)
- [ ] Kubernetes persistent volume claims
- [ ] Cloud storage mounting (S3, GCS as filesystems)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Data safety | Must | Source code never lost unexpectedly |
| Performance | High | Especially important on macOS |
| Simplicity | High | Easy to understand boundaries |
| Permission handling | High | No chown/chmod nightmares |
| Docker-native | High | Standard docker/compose patterns |
| Devcontainer compatible | High | Works with VS Code remote containers |
| Cross-platform | Medium | Consistent behavior macOS/Linux |
| Disk efficiency | Medium | Not wasting space on duplicates |

## Architecture Candidates

| Pattern | Description | Pros | Cons | Evaluate |
|---------|-------------|------|------|----------|
| Bind mount everything | Mount host directories directly | Simple, familiar, direct access | Slow on macOS, permission issues, leaks host paths | Evaluate |
| Named volumes only | All persistence via Docker volumes | Fast, portable, no permission issues | Less visible from host, harder to backup | Evaluate |
| Hybrid (bind + named) | Workspace bind, caches named | Balance of access and performance | More complex config, two mental models | Evaluate |
| Delegated/cached mounts | macOS-optimized bind mounts | Better macOS performance | Still slower than native, macOS-only flags | Evaluate |
| Mutagen sync | File sync instead of mounts | Near-native performance | Extra tool, sync delays, complexity | Evaluate |

## Volume Boundary Design

### Proposed Boundaries

| Boundary | Type | Persists | Resets | Contents |
|----------|------|----------|--------|----------|
| `/workspace` | Bind mount | Yes | No | Source code, project files |
| `/home/dev` | Named volume | Yes | No | Dotfiles, shell history, tool config |
| `/home/dev/.cache` | Named volume | Yes | Prune | Package manager caches (pip, npm, cargo) |
| `/home/dev/.local` | Named volume | Yes | No | User-installed binaries, virtualenvs |
| `/tmp` | tmpfs | No | Yes | Temporary files, build intermediates |
| `node_modules` | Named volume | Yes | Prune | Project dependencies (performance) |
| `target/`, `dist/` | Named volume | Yes | Prune | Build outputs |

### Permission Strategy Options

| Strategy | How | Pros | Cons |
|----------|-----|------|------|
| Match UID/GID | Container user matches host user (1000:1000) | Simple, works with bind mounts | Assumes host UID, breaks if different |
| fixuid | Dynamically adjust UID at startup | Flexible, handles any host UID | Extra tool, startup delay |
| Root + gosu | Run as root, drop privileges | Maximum flexibility | Security concerns, complexity |
| Podman userns | User namespace remapping | Rootless, secure | Podman-specific, complexity |

## Selected Approach

**Hybrid Architecture with UID Matching + Entrypoint Permission Fix**

Based on spike testing (see Spike Findings below), the recommended approach is:

1. **Bind mount** for workspace/source code (host access required)
2. **Named volumes** for caches and dependencies (performance critical)
3. **UID/GID 1000:1000** matching (standard for most Linux/macOS users)
4. **Entrypoint script** to fix named volume permissions on first run
5. **tmpfs** for truly ephemeral data (/tmp)

### Recommended docker-compose Configuration

```yaml
services:
  dev:
    build: .
    volumes:
      # Source code: bind mount for host access
      - ./src:/workspace:cached

      # Home directory: named volume for persistence
      - home-data:/home/dev

      # Caches: named volumes for performance
      - npm-cache:/home/dev/.npm
      - pip-cache:/home/dev/.cache/pip
      - node-modules:/workspace/node_modules

      # Entrypoint script
      - ./entrypoint.sh:/usr/local/bin/entrypoint.sh:ro

    tmpfs:
      - /tmp:size=512M

    entrypoint: ["/usr/local/bin/entrypoint.sh"]
    command: ["/bin/bash"]

volumes:
  home-data:
  npm-cache:
  pip-cache:
  node-modules:
```

### Permission Fix via Entrypoint

Named volumes are created with root ownership by default. The entrypoint script
automatically fixes this on container startup:

```bash
#!/bin/bash
# Fix ownership of named volume mount points
VOLUME_DIRS=("/home/dev/.npm" "/home/dev/.cache/pip" "/workspace/node_modules")
for dir in "${VOLUME_DIRS[@]}"; do
    [[ -d "$dir" ]] && [[ "$(stat -c '%u' "$dir")" == "0" ]] && \
        sudo chown -R 1000:1000 "$dir"
done
exec "$@"
```

### Tradeoffs

| Aspect | Benefit | Tradeoff |
|--------|---------|----------|
| node_modules on named volume | 10-19x faster npm install | Host IDE can't see node_modules |
| Bind mount with :cached | Host file access | ~100 MB/s vs 1+ GB/s native |
| Entrypoint permission fix | Automated setup | Small startup delay on first run |

## Acceptance Criteria

- [ ] Given a new project, when I start a container with workspace mounted, then I can edit files from host or container
- [ ] Given a running container, when I stop and restart it, then my shell history and dotfiles are preserved
- [ ] Given node_modules in a named volume, when I run npm install, then performance is comparable to native
- [ ] Given a container on macOS, when I edit source files, then changes are reflected within 1 second
- [ ] Given container user (dev:1000), when I create files in workspace, then host user can read/write them
- [ ] Given `docker system prune`, when I restart my dev container, then source code is intact
- [ ] Given the volume architecture, when a new developer sets up, then they understand what persists in under 5 minutes
- [ ] Given VS Code devcontainer, when I open a project, then volumes are configured automatically
- [ ] Given docker-compose.yml, when I define the service, then volume config is under 10 lines

## Dependencies

- Requires: 001-prd-container-base (completed)
- Integrates: 002-prd-dotfile-management (dotfiles in home volume)
- Integrates: 003-prd-secret-injection (secrets may use tmpfs or volumes)
- Blocks: 005-prd-ide-integration (devcontainer config depends on volume design)

## Spike Findings

### Spike 004: Volume Architecture Prototype (2026-01-20)

**Location:** `spikes/004-volume-architecture/`

#### Benchmark Results: Sequential I/O (50MB file)

| Mount Type | Write Speed | Read Speed | vs Named Volume |
|------------|-------------|------------|-----------------|
| Bind (default) | 94 MB/s | 142 MB/s | 13x slower |
| Bind (cached) | 112 MB/s | 157 MB/s | 11x slower |
| Bind (delegated) | 117 MB/s | 286 MB/s | 10x slower |
| **Named Volume** | **1.2 GB/s** | **4.2 GB/s** | baseline |

#### Benchmark Results: Small File Operations (1000 files)

| Mount Type | Create | Read | Delete |
|------------|--------|------|--------|
| Bind (default) | 3s | 6s | 1s |
| Bind (cached) | 4s | 6s | 1s |
| Bind (delegated) | 3s | 5s | 1s |
| **Named Volume** | **<1s** | **3s** | **<1s** |

#### Benchmark Results: High Volume (5000 files)

| Mount Type | Create | List | Stat | Delete |
|------------|--------|------|------|--------|
| Bind mount | 19s | 2s | 19s | 6s |
| **Named Volume** | **1s** | **<1s** | **14s** | **<1s** |

#### Key Findings

1. **Named volumes are 10-12x faster** for sequential I/O on macOS
2. **Small file creation is 19x faster** on named volumes (critical for npm install)
3. **`cached` and `delegated` flags provide marginal improvement** (~10-20%)
4. **npm install: 70 packages in ~4 seconds** on named volume
5. **Named volumes require permission fix** - root ownership by default
6. **Entrypoint script solves permission issue** automatically on startup
7. **Host cannot see node_modules contents** (expected tradeoff)
8. **package-lock.json visible on host** (in bind-mounted workspace)

#### Artifacts Produced

- `spikes/004-volume-architecture/docker-compose.hybrid.yml` - Production-ready config
- `spikes/004-volume-architecture/docker-compose.benchmark.yml` - Benchmark suite
- `spikes/004-volume-architecture/entrypoint.sh` - Permission fix script
- `spikes/004-volume-architecture/workspace/benchmark.sh` - I/O benchmark script

## Design Tasks

- [x] Document current bind mount behavior and pain points
- [x] Benchmark bind mount vs named volume performance (macOS and Linux)
- [x] Test delegated/cached mount flags on macOS
- [x] Prototype hybrid architecture with docker-compose
- [x] Test UID/GID matching across common host configurations
- [ ] Evaluate fixuid for dynamic UID adjustment
- [ ] Design devcontainer.json volume configuration
- [x] Design docker-compose.yml volume patterns
- [ ] Test with large node_modules (>500MB) on macOS
- [ ] Test with cargo target directory (incremental compilation)
- [ ] Document backup/restore procedures for named volumes
- [ ] Create volume architecture diagram
- [ ] Write developer guide explaining boundaries
