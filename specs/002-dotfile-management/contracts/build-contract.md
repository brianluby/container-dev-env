# Build Contract: Dotfile Management with Chezmoi

**Feature**: 002-dotfile-management
**Date**: 2026-01-20

## Overview

This contract defines the build requirements and verification steps for adding Chezmoi to the container image.

## Build Requirements

### Dockerfile Modifications

**Location**: `Dockerfile` (extends existing base image)

**New Layer Requirements**:

1. **Chezmoi Installation**
   - Must use official installation script
   - Must pin to specific version
   - Must install to `/usr/local/bin`
   - Must work on both arm64 and amd64

2. **age Installation**
   - Must download from official GitHub releases
   - Must pin to specific version
   - Must install both `age` and `age-keygen`
   - Must work on both arm64 and amd64

### Version Pinning

| Component | Version | Source |
|-----------|---------|--------|
| Chezmoi | v2.47.1 (or latest stable) | get.chezmoi.io |
| age | v1.1.1 (or latest stable) | GitHub releases |

### Size Constraints

| Metric | Limit | Notes |
|--------|-------|-------|
| Total size increase | <50MB | From spec SC-004 |
| Chezmoi binary | ~15MB | Expected |
| age + age-keygen | ~10MB | Expected |

## Build Verification

### Pre-Build Checks

```bash
# Verify base image exists
docker image inspect devcontainer:base || docker build -t devcontainer:base .
```

### Build Command

```bash
# Standard build
docker build -t devcontainer .

# Multi-arch build (CI)
docker buildx build --platform linux/amd64,linux/arm64 -t devcontainer .
```

### Post-Build Verification

| Check | Command | Expected |
|-------|---------|----------|
| Chezmoi exists | `docker run --rm devcontainer which chezmoi` | `/usr/local/bin/chezmoi` |
| Chezmoi version | `docker run --rm devcontainer chezmoi --version` | `chezmoi version v2.47.1...` |
| age exists | `docker run --rm devcontainer which age` | `/usr/local/bin/age` |
| age version | `docker run --rm devcontainer age --version` | `v1.1.1` |
| age-keygen exists | `docker run --rm devcontainer which age-keygen` | `/usr/local/bin/age-keygen` |
| Permissions | `docker run --rm devcontainer ls -la /usr/local/bin/chezmoi` | `-rwxr-xr-x` |
| Size delta | Compare image sizes | <50MB increase |

### Architecture-Specific Verification

```bash
# amd64
docker run --platform linux/amd64 --rm devcontainer chezmoi --version
docker run --platform linux/amd64 --rm devcontainer age --version

# arm64
docker run --platform linux/arm64 --rm devcontainer chezmoi --version
docker run --platform linux/arm64 --rm devcontainer age --version
```

## Layer Ordering

Chezmoi installation should be placed:
- **After**: apt packages, Python, Node.js installations
- **Before**: User creation and shell configuration

This ensures:
1. curl is available for installation script
2. Chezmoi is available for health checks
3. Layer caching is maximized

## Dockerfile Snippet

```dockerfile
# =============================================================================
# Chezmoi Installation for Dotfile Management
# Feature: 002-dotfile-management
# =============================================================================

# Install Chezmoi (pinned version for reproducibility)
ARG CHEZMOI_VERSION=v2.47.1
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin -t ${CHEZMOI_VERSION}

# Install age for encrypted dotfile support
ARG AGE_VERSION=v1.1.1
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-${ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin --strip-components=1 age/age age/age-keygen && \
    chmod +x /usr/local/bin/age /usr/local/bin/age-keygen
```

## CI/CD Integration

### GitHub Actions Additions

```yaml
# In .github/workflows/container-build.yml

- name: Verify Chezmoi installation
  run: |
    docker run --rm devcontainer:test chezmoi --version
    docker run --rm devcontainer:test age --version

- name: Check size increase
  run: |
    BASE_SIZE=$(docker image inspect devcontainer:base --format='{{.Size}}')
    NEW_SIZE=$(docker image inspect devcontainer:test --format='{{.Size}}')
    DELTA=$((($NEW_SIZE - $BASE_SIZE) / 1024 / 1024))
    echo "Size increase: ${DELTA}MB"
    if [ $DELTA -gt 50 ]; then
      echo "ERROR: Size increase exceeds 50MB limit"
      exit 1
    fi
```

## Rollback Plan

If build fails or verification fails:

1. Revert Dockerfile changes
2. Previous image remains tagged and usable
3. No data migration needed (new binaries only)
