# Build Contract: Container Base Image

**Feature**: 001-container-base-image
**Date**: 2026-01-20

## Overview

This contract defines the expected inputs, outputs, and behavior of the container build process.

## Build Command

```bash
# Local single-arch build
docker build -t devcontainer .

# Multi-arch build (CI)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  -t ghcr.io/OWNER/devcontainer:latest \
  -t ghcr.io/OWNER/devcontainer:$(date +%Y-%m-%d) \
  .
```

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| Dockerfile | file | Yes | Container build specification |
| .dockerignore | file | No | Build context exclusions |
| scripts/health-check.sh | file | Yes | Health check script |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| Container Image | OCI image | Multi-arch manifest with amd64 + arm64 |
| Build Logs | text | stdout/stderr from build process |

## Build Arguments

| ARG | Default | Description |
|-----|---------|-------------|
| USERNAME | dev | Non-root user name |
| USER_UID | 1000 | User ID |
| USER_GID | 1000 | Group ID |

## Environment Variables (Runtime)

| Variable | Value | Description |
|----------|-------|-------------|
| HOME | /home/dev | User home directory |
| USER | dev | Current user |
| SHELL | /bin/bash | Default shell |
| LANG | en_US.UTF-8 | Locale setting |
| PATH | /usr/local/bin:... | Executable search path |

## Success Criteria

| Criterion | Check Command | Expected Output |
|-----------|---------------|-----------------|
| Build completes | `docker build .` | Exit code 0 |
| Non-root user | `docker run --rm IMG whoami` | `dev` |
| Git available | `docker run --rm IMG git --version` | `git version X.Y.Z` |
| Python available | `docker run --rm IMG python3 --version` | `Python 3.14.X` |
| Node available | `docker run --rm IMG node --version` | `v22.X.Y` |
| Sudo works | `docker run --rm IMG sudo whoami` | `root` |
| UTF-8 locale | `docker run --rm IMG locale` | Contains `UTF-8` |

## Error Conditions

| Error | Cause | Resolution |
|-------|-------|------------|
| `E: Unable to locate package` | Network issue or repo unavailable | Retry build; check network |
| `no space left on device` | Insufficient disk space | Free disk space; prune images |
| `failed to solve` | Dockerfile syntax error | Check Dockerfile syntax |
| `exec format error` | Wrong architecture binary | Verify multi-arch build setup |

## Build Time Limits

| Phase | Max Duration | Action on Exceed |
|-------|--------------|------------------|
| apt-get update | 60s | Retry once |
| apt-get install | 120s | Fail build |
| Python setup | 60s | Fail build |
| Node setup | 60s | Fail build |
| Total build | 300s | Fail build |

## Layer Optimization

Expected layer structure for cache efficiency:

1. Base image (debian:bookworm-slim)
2. System packages (apt-get install)
3. Python installation
4. Node.js installation
5. User creation
6. Shell configuration
7. Health check script

## Multi-Architecture Manifest

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "platform": { "architecture": "amd64", "os": "linux" }
    },
    {
      "platform": { "architecture": "arm64", "os": "linux" }
    }
  ]
}
```
