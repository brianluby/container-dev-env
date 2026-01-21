# Research: Container Base Image

**Feature**: 001-container-base-image
**Date**: 2026-01-20
**Status**: Complete

## Research Questions

### 1. Multi-Architecture Docker Build Strategy

**Decision**: Use Docker buildx with `docker-container` driver and native GitHub Actions runners per architecture.

**Rationale**:
- QEMU emulation is 5-20x slower for compiled code; native runners eliminate this bottleneck
- Matrix strategy with dedicated arm64 runners (e.g., `ubuntu-24.04-arm`) provides fastest builds
- `docker-container` driver is required for true multi-platform support (default `docker` driver cannot build multi-arch)
- Push-by-digest pattern allows parallel builds that merge into single manifest

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|------------------|
| QEMU-only emulation | Too slow for Python/Node native extensions; violates <5min build time constraint |
| Single-arch builds | Violates FR-006 multi-architecture requirement |
| Buildpacks | Over-engineered for base image; adds complexity without benefit |

**Implementation Pattern**:
```yaml
# GitHub Actions matrix for native multi-arch
strategy:
  matrix:
    include:
      - platform: linux/amd64
        runner: ubuntu-latest
      - platform: linux/arm64
        runner: ubuntu-24.04-arm
```

---

### 2. Python 3.14+ Installation Method

**Decision**: Use multi-stage build copying Python from official `python:3.14-slim-bookworm` image.

**Rationale**:
- Python 3.14 is NOT in Debian Bookworm repos (only Python 3.11.2 available)
- deadsnakes PPA is Ubuntu-only; unsupported on Debian
- Official Python Docker images are pre-compiled, tested, and support both arm64/amd64
- Multi-stage build avoids bloat from build dependencies
- uv package manager included for modern, fast dependency management

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|------------------|
| Build from source | Slow (>10min), complex, bloats image with build-essential |
| deadsnakes PPA | Ubuntu-only; no official Debian support |
| pyenv | Adds ~150MB overhead; overkill for single-version container |
| System Python 3.11 | Does not meet FR-008 requirement for Python 3.14+ |

**Implementation Pattern**:
```dockerfile
# Stage 1: Get Python from official image
FROM python:3.14-slim-bookworm AS python-base

# Stage 2: Final image
FROM debian:bookworm-slim
COPY --from=python-base /usr/local /usr/local
# Install uv for fast package management
RUN pip install uv
```

---

### 3. Node.js LTS Installation Method

**Decision**: Use NodeSource APT repository for Node.js 22.x LTS.

**Rationale**:
- NodeSource provides official, tested packages for Debian Bookworm
- Supports both arm64 and amd64 architectures
- apt-based installation integrates cleanly with Debian package management
- Provides npm by default; no additional configuration needed
- Version pinning via repo selection (node_22.x) ensures reproducibility

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|------------------|
| Official Node Docker image | Requires multi-stage complexity; adds extra layer to manage |
| NVM | Not recommended for production; complex environment handling |
| Direct binary | Manual arch detection required; harder to maintain |
| Debian repos | Only provides Node 18.x; does not provide LTS 22.x |

**Implementation Pattern**:
```dockerfile
# Add NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*
```

---

### 4. Base Image Selection

**Decision**: Debian Bookworm-slim with date-pinned tag (e.g., `debian:bookworm-20260115-slim`).

**Rationale**:
- glibc compatibility ensures Python wheels and Node.js native extensions work without workarounds
- DFSG-compliant licensing meets FR-007 MIT-compatible requirement
- Slim variant (~80MB base) minimizes attack surface per constitution principle IV
- Date-pinned tags enable reproducible builds per constitution principle V
- Multi-architecture manifest exists for both arm64 and amd64

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|------------------|
| Ubuntu 24.04 | Larger size; some non-free components |
| Alpine | musl libc breaks Python/Node native extensions; violates simplicity principle |
| Wolfi | Newer ecosystem; less familiar; smaller community for troubleshooting |
| Debian :latest | Floating tag violates reproducibility (constitution principle V) |

---

### 5. Non-Root User Configuration

**Decision**: Create user `dev` with UID/GID 1000, sudo access, home directory `/home/dev`.

**Rationale**:
- UID/GID 1000 matches typical host user; simplifies volume mount permissions
- Short username `dev` is container convention; self-documenting
- Passwordless sudo enables administrative tasks without image rebuild
- Per clarification session: username confirmed as `dev`

**Implementation Pattern**:
```dockerfile
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME
```

---

### 6. Bash Shell Configuration

**Decision**: Configure bash with colored prompt, 1000-line history, `ll`/`la` aliases, proper PATH.

**Rationale**:
- Per clarification session: standard set selected over minimal or extended options
- Colored prompt improves UX without adding complexity
- 1000-line history is sufficient for debugging sessions
- `ll` and `la` aliases are universally expected by developers
- Extended options (git prompt, vi-mode) deferred to dotfile layer (002-prd)

**Implementation Pattern**:
```bash
# /home/dev/.bashrc additions
export HISTSIZE=1000
export HISTFILESIZE=2000
alias ll='ls -alF'
alias la='ls -A'
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
```

---

### 7. Health Check Implementation

**Decision**: Simple script checking core tools are executable.

**Rationale**:
- FR-010 requires health check for orchestration tools
- Constitution principle VI requires health checks for all containers
- Script-based approach is simpler than HTTP endpoint for dev container
- Validates actual functionality, not just process status

**Implementation Pattern**:
```bash
#!/bin/bash
# scripts/health-check.sh
set -e
python3 --version
node --version
git --version
exit 0
```

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["scripts/health-check.sh"]
```

---

### 8. Weekly CI Rebuild Strategy

**Decision**: GitHub Actions scheduled workflow with `--pull` to get latest base image.

**Rationale**:
- Per clarification session: weekly automated rebuild selected
- `docker build --pull` ensures latest base image with security patches
- Schedule trigger (`0 0 * * 0`) runs every Sunday at midnight UTC
- Multi-arch build in same workflow ensures both platforms updated
- No vulnerability scanning gate (manual review for CVEs acceptable for dev container)

**Implementation Pattern**:
```yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  push:
    branches: [main]

jobs:
  build:
    steps:
      - uses: docker/build-push-action@v6
        with:
          platforms: linux/amd64,linux/arm64
          push: true
          pull: true  # Always pull latest base image
```

---

## Summary

All technical decisions resolved. No remaining NEEDS CLARIFICATION items.

| Topic | Decision | Key Rationale |
|-------|----------|---------------|
| Multi-arch strategy | Native runners + buildx | Speed (vs QEMU), <5min builds |
| Python 3.14 | Multi-stage from official image | Not in Debian repos; pre-compiled |
| Node.js LTS | NodeSource APT repo | Official support; apt integration |
| Base image | debian:bookworm-YYYYMMDD-slim | glibc, MIT-compatible, reproducible |
| User config | `dev` UID 1000 with sudo | Convention; volume mount compat |
| Bash config | Standard set (colors, history, aliases) | Clarification session decision |
| Health check | Script checking tool versions | Constitution compliance |
| Weekly rebuild | GitHub Actions cron + --pull | Clarification session decision |
