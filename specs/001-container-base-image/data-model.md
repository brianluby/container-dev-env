# Data Model: Container Base Image

**Feature**: 001-container-base-image
**Date**: 2026-01-20

## Overview

This feature has minimal data modeling requirements as it produces a stateless container image. The "entities" are configuration artifacts rather than database entities.

## Entities

### ContainerImage

The built Docker image artifact.

| Attribute | Type | Description | Constraints |
|-----------|------|-------------|-------------|
| name | string | Image name | `devcontainer` |
| tag | string | Version/date tag | SemVer or date (e.g., `1.0.0`, `2026-01-20`) |
| base_image | string | Debian base reference | `debian:bookworm-YYYYMMDD-slim` |
| architectures | string[] | Supported platforms | `["linux/amd64", "linux/arm64"]` |
| size_compressed | integer | Image size in bytes | <2GB (2,147,483,648 bytes) |
| build_time | integer | Build duration in seconds | <300 seconds |

### DeveloperUser

The non-root user account inside the container.

| Attribute | Type | Description | Constraints |
|-----------|------|-------------|-------------|
| username | string | Account name | `dev` |
| uid | integer | User ID | 1000 |
| gid | integer | Group ID | 1000 |
| home | string | Home directory path | `/home/dev` |
| shell | string | Default shell | `/bin/bash` |
| sudo_access | boolean | Passwordless sudo | `true` |

### InstalledTools

Development tools available in the container.

| Tool | Category | Version Constraint | Required |
|------|----------|-------------------|----------|
| git | VCS | Latest in Debian repos | MUST |
| curl | HTTP client | Latest in Debian repos | MUST |
| wget | HTTP client | Latest in Debian repos | MUST |
| jq | JSON processor | Latest in Debian repos | MUST |
| make | Build tool | Latest in Debian repos | MUST |
| build-essential | C/C++ toolchain | Latest in Debian repos | MUST |
| python3 | Runtime | 3.14+ | SHOULD |
| pip | Python pkg mgr | Latest | SHOULD |
| uv | Python pkg mgr | Latest | SHOULD |
| node | Runtime | LTS (22.x) | SHOULD |
| npm | Node pkg mgr | Bundled with Node | SHOULD |

### BashConfiguration

Shell environment settings.

| Setting | Value | Description |
|---------|-------|-------------|
| HISTSIZE | 1000 | Command history lines in memory |
| HISTFILESIZE | 2000 | Command history lines on disk |
| PS1 | Colored prompt | `\u@\h:\w\$` with ANSI colors |
| ll alias | `ls -alF` | Long listing with indicators |
| la alias | `ls -A` | List all except . and .. |
| PATH | Standard + /usr/local/bin | Python/Node binaries accessible |

## Relationships

```
ContainerImage
    └── contains → DeveloperUser (1:1)
    └── contains → InstalledTools (1:many)
    └── contains → BashConfiguration (1:1)
```

## State Transitions

### Container Lifecycle

```
[Not Built] → docker build → [Built/Tagged]
[Built/Tagged] → docker push → [Published]
[Published] → docker pull → [Available Locally]
[Available Locally] → docker run → [Running]
[Running] → docker stop → [Stopped]
[Stopped] → docker rm → [Removed]
```

### Weekly Rebuild Trigger

```
[Published] → weekly cron → [Rebuilding]
[Rebuilding] → build success → [Published (new digest)]
[Rebuilding] → build failure → [Alert maintainer]
```

## Validation Rules

1. **Image Size**: MUST be under 2GB compressed
2. **Build Time**: MUST complete in under 5 minutes on CI
3. **User Check**: `whoami` inside container MUST return `dev`
4. **Tool Check**: All MUST tools respond to `--version`
5. **Architecture**: Image manifest MUST list both `linux/amd64` and `linux/arm64`
6. **License**: All packages MUST be MIT-compatible (DFSG-compliant)
