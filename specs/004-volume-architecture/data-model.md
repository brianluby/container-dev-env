# Data Model: Volume Architecture

**Feature**: 004-volume-architecture
**Date**: 2026-01-20

## Entities

### Volume

Abstract base concept for all storage types in the container architecture.

| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | Unique identifier for the volume |
| type | enum | `bind`, `named`, `tmpfs` |
| containerPath | string | Mount point inside container |
| persistence | enum | `ephemeral`, `session`, `permanent` |
| hostAccess | boolean | Whether host can directly access contents |

---

### WorkspaceVolume (extends Volume)

Bind-mounted directory containing source code. Bidirectional sync between host and container.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| type | enum | `bind` | Always bind mount |
| hostPath | string | required | Absolute path on host (e.g., `./src`) |
| containerPath | string | `/workspace` | Mount point in container |
| consistency | enum | `cached` | Cache consistency flag |
| persistence | enum | `permanent` | Survives all operations (host filesystem) |
| hostAccess | boolean | `true` | IDE can read/write directly |

**Validation Rules**:
- `hostPath` MUST exist on host before container start
- `hostPath` MUST be writable by host user
- Container MUST fail fast if path doesn't exist

**State Transitions**: None (static bind mount)

---

### HomeVolume (extends Volume)

Named volume containing user configuration, shell history, and local tools.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| type | enum | `named` | Docker-managed volume |
| volumeName | string | `devenv-home` | Docker volume name |
| containerPath | string | `/home/dev` | User home directory |
| persistence | enum | `session` | Survives restarts, not prune |
| hostAccess | boolean | `false` | Not directly visible on host |
| ownerUID | int | dynamic | Set at container start |
| ownerGID | int | dynamic | Set at container start |

**Validation Rules**:
- Volume created automatically if missing (log warning)
- Ownership fixed to container user UID/GID at startup
- Survives `docker system prune` (named volume with explicit name)

**State Transitions**:
```
[Not Exists] --container start--> [Created (root:root)]
[Created (root:root)] --entrypoint fix--> [Ready (dev:dev)]
[Ready] --container restart--> [Ready] (no change)
[Ready] --docker volume rm--> [Not Exists]
```

---

### CacheVolume (extends Volume)

Named volume(s) for package manager caches. Improves performance, can be safely pruned.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| type | enum | `named` | Docker-managed volume |
| volumeName | string | varies | e.g., `devenv-npm-cache` |
| containerPath | string | varies | Package manager cache path |
| packageManager | enum | `npm`, `pip`, `cargo` | Which cache this serves |
| persistence | enum | `session` | Can be pruned without data loss |
| hostAccess | boolean | `false` | Not directly visible on host |

**Cache Volume Instances**:

| Volume Name | Container Path | Package Manager |
|-------------|----------------|-----------------|
| `devenv-npm-cache` | `/home/dev/.npm` | npm |
| `devenv-pip-cache` | `/home/dev/.cache/pip` | pip |
| `devenv-cargo-registry` | `/home/dev/.cargo/registry` | cargo |
| `devenv-node-modules` | `/workspace/node_modules` | npm (dependencies) |

**Validation Rules**:
- Created automatically if missing (log warning)
- Ownership fixed to container user at startup
- Safe to delete - only performance impact

**State Transitions**: Same as HomeVolume

---

### EphemeralStorage (extends Volume)

tmpfs mount for temporary files. Fast, memory-backed, automatically cleared on restart.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| type | enum | `tmpfs` | In-memory filesystem |
| containerPath | string | `/tmp` | Mount point |
| size | string | `512M` | Maximum size |
| persistence | enum | `ephemeral` | Cleared on restart |
| hostAccess | boolean | `false` | Memory-only |

**Validation Rules**:
- Size should be 25% of available RAM or less
- Data WILL be lost on container stop/restart
- No ownership fixes needed (created fresh each time)

**State Transitions**:
```
[Not Exists] --container start--> [Mounted (empty)]
[Mounted] --container stop--> [Not Exists] (data lost)
```

---

## Entity Relationships

```
Container
    │
    ├── WorkspaceVolume (1) ─────── bind mount to host
    │       └── source code
    │
    ├── HomeVolume (1) ─────────── named volume
    │       ├── .bashrc
    │       ├── .zshrc
    │       ├── .bash_history
    │       └── local tools
    │
    ├── CacheVolume (*) ────────── named volumes
    │       ├── npm-cache
    │       ├── pip-cache
    │       ├── cargo-registry
    │       └── node-modules
    │
    └── EphemeralStorage (*) ───── tmpfs mounts
            └── /tmp
```

---

## Configuration Model

### DockerComposeVolumeConfig

```yaml
# Volume definitions (top-level)
volumes:
  home-data:
    name: devenv-home              # Explicit name survives prune
  npm-cache:
    name: devenv-npm-cache
  pip-cache:
    name: devenv-pip-cache
  node-modules:
    name: devenv-node-modules

# Service volume mounts
services:
  dev:
    volumes:
      # WorkspaceVolume
      - type: bind
        source: ./src
        target: /workspace
        consistency: cached

      # HomeVolume
      - type: volume
        source: home-data
        target: /home/dev

      # CacheVolumes
      - type: volume
        source: npm-cache
        target: /home/dev/.npm
      - type: volume
        source: pip-cache
        target: /home/dev/.cache/pip
      - type: volume
        source: node-modules
        target: /workspace/node_modules

    # EphemeralStorage
    tmpfs:
      - /tmp:size=512M
```

---

## Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `LOCAL_UID` | int | `1000` | Host user UID for permission mapping |
| `LOCAL_GID` | int | `1000` | Host user GID for permission mapping |

---

## Invariants

1. **Source code accessibility**: WorkspaceVolume MUST be readable/writable from both host and container
2. **Permission consistency**: All files created in container MUST be accessible by host user
3. **Cache performance**: CacheVolume operations MUST be at least 5x faster than equivalent bind mount
4. **Ephemeral guarantee**: EphemeralStorage MUST be empty after container restart
5. **Prune safety**: WorkspaceVolume (bind mount) MUST survive all Docker prune operations
6. **Single-container access**: Named volumes MUST NOT be shared between concurrent containers
