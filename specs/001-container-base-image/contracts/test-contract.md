# Test Contract: Container Base Image

**Feature**: 001-container-base-image
**Date**: 2026-01-20

## Overview

This contract defines the acceptance tests for validating the container base image.

## Test Categories

### 1. Build Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| BUILD-001 | Dockerfile builds without error | `docker build -t test .` | Exit 0 |
| BUILD-002 | Build completes in <5 minutes | `time docker build .` | <300s |
| BUILD-003 | Image size under 2GB | `docker images --format "{{.Size}}"` | <2GB |

### 2. User Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| USER-001 | Default user is non-root | `docker run --rm IMG whoami` | `dev` |
| USER-002 | Home directory exists | `docker run --rm IMG ls -la /home/dev` | Exit 0 |
| USER-003 | Sudo access works | `docker run --rm IMG sudo whoami` | `root` |
| USER-004 | UID is 1000 | `docker run --rm IMG id -u` | `1000` |
| USER-005 | GID is 1000 | `docker run --rm IMG id -g` | `1000` |

### 3. Tool Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| TOOL-001 | Git is available | `docker run --rm IMG git --version` | `git version *` |
| TOOL-002 | Curl is available | `docker run --rm IMG curl --version` | `curl *` |
| TOOL-003 | Wget is available | `docker run --rm IMG wget --version` | `GNU Wget *` |
| TOOL-004 | Jq is available | `docker run --rm IMG jq --version` | `jq-*` |
| TOOL-005 | Make is available | `docker run --rm IMG make --version` | `GNU Make *` |
| TOOL-006 | GCC is available | `docker run --rm IMG gcc --version` | `gcc *` |

### 4. Runtime Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| PY-001 | Python 3.14+ available | `docker run --rm IMG python3 --version` | `Python 3.14.*` |
| PY-002 | Pip is available | `docker run --rm IMG pip --version` | `pip *` |
| PY-003 | Uv is available | `docker run --rm IMG uv --version` | `uv *` |
| PY-004 | Can install numpy | `docker run --rm IMG pip install numpy` | Exit 0 |
| NODE-001 | Node.js 22.x LTS available | `docker run --rm IMG node --version` | `v22.*` |
| NODE-002 | Npm is available | `docker run --rm IMG npm --version` | `*.*.*` |
| NODE-003 | Can install typescript | `docker run --rm IMG npm install -g typescript` | Exit 0 |

### 5. Shell Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| SHELL-001 | Bash is default shell | `docker run --rm IMG echo $SHELL` | `/bin/bash` |
| SHELL-002 | ll alias works | `docker run --rm IMG bash -ic "type ll"` | `alias` |
| SHELL-003 | la alias works | `docker run --rm IMG bash -ic "type la"` | `alias` |
| SHELL-004 | HISTSIZE is set | `docker run --rm IMG bash -c 'echo $HISTSIZE'` | `1000` |

### 6. Locale Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| LOCALE-001 | UTF-8 configured | `docker run --rm IMG locale` | Contains `UTF-8` |
| LOCALE-002 | LANG is set | `docker run --rm IMG echo $LANG` | `en_US.UTF-8` |

### 7. Architecture Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| ARCH-001 | amd64 build succeeds | `docker buildx build --platform linux/amd64 .` | Exit 0 |
| ARCH-002 | arm64 build succeeds | `docker buildx build --platform linux/arm64 .` | Exit 0 |
| ARCH-003 | Manifest includes both | `docker manifest inspect IMG` | Both platforms listed |

### 8. Health Check Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| HEALTH-001 | Health check passes | `docker run --rm IMG scripts/health-check.sh` | Exit 0 |
| HEALTH-002 | Container reports healthy | `docker inspect --format='{{.State.Health.Status}}'` | `healthy` |

## Test Runner Script

```bash
#!/bin/bash
# scripts/test-container.sh

set -e

IMAGE="${1:-devcontainer}"

echo "=== Build Tests ==="
docker build -t "$IMAGE" .

echo "=== User Tests ==="
[ "$(docker run --rm $IMAGE whoami)" = "dev" ]
[ "$(docker run --rm $IMAGE id -u)" = "1000" ]
docker run --rm $IMAGE sudo whoami | grep -q root

echo "=== Tool Tests ==="
docker run --rm $IMAGE git --version
docker run --rm $IMAGE curl --version | head -1
docker run --rm $IMAGE jq --version
docker run --rm $IMAGE make --version | head -1

echo "=== Runtime Tests ==="
docker run --rm $IMAGE python3 --version | grep -q "3.14"
docker run --rm $IMAGE node --version | grep -q "v22"
docker run --rm $IMAGE npm --version

echo "=== Shell Tests ==="
docker run --rm $IMAGE bash -ic "type ll" | grep -q alias

echo "=== Locale Tests ==="
docker run --rm $IMAGE locale | grep -q UTF-8

echo "=== All tests passed ==="
```

## CI Integration

```yaml
# .github/workflows/container-build.yml (test job)
test:
  runs-on: ubuntu-latest
  needs: build
  steps:
    - uses: actions/checkout@v4
    - name: Run acceptance tests
      run: ./scripts/test-container.sh devcontainer
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Test assertion failed |
| 2 | Container not found |
| 3 | Build failed |
