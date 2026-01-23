# Quickstart: Containerized IDE

**Feature**: 008-containerized-ide
**Time to first edit**: ~30 seconds after `docker compose up`

## Prerequisites

- Docker 24+ with Docker Compose 2.x
- Docker Buildx (for multi-arch builds)
- A modern web browser (Chrome, Firefox, Safari, Edge)
- Base container image built (001-container-base)

## Setup

### 1. Generate Connection Token

```bash
# Generate a cryptographically random 32-character hex token
./src/scripts/generate-token.sh > .env
# Or manually:
echo "CONNECTION_TOKEN=$(head -c 16 /dev/urandom | xxd -p)" > .env
```

### 2. Configure Extensions (Optional)

Edit `src/config/extensions.json` to declare project extensions:

```json
{
  "recommendations": [
    "ms-python.python",
    "rust-lang.rust-analyzer",
    "esbenp.prettier-vscode"
  ]
}
```

### 3. Start the IDE

```bash
docker compose -f src/docker/docker-compose.ide.yml up -d
```

### 4. Access the IDE

Open your browser to:

```
http://localhost:3000/?tkn=<your-token-from-.env>
```

The IDE loads with file explorer, terminal, and extension support.

## Verification

```bash
# Check container is running
docker compose -f src/docker/docker-compose.ide.yml ps

# Check health
docker inspect --format='{{.State.Health.Status}}' devenv-ide-1

# Check user (should be 1000)
docker exec devenv-ide-1 id -u

# Check memory usage
docker stats devenv-ide-1 --no-stream --format "{{.MemUsage}}"
```

## Common Operations

### Install an Extension Manually

```bash
docker exec devenv-ide-1 \
  /home/.openvscode-server/bin/openvscode-server \
  --install-extension <publisher.extension-name>
```

### Sideload a VSIX File

```bash
docker cp extension.vsix devenv-ide-1:/tmp/
docker exec devenv-ide-1 \
  /home/.openvscode-server/bin/openvscode-server \
  --install-extension /tmp/extension.vsix
```

### Stop the IDE

```bash
docker compose -f src/docker/docker-compose.ide.yml down
# To also remove volumes (loses extensions and settings):
docker compose -f src/docker/docker-compose.ide.yml down -v
```

### Rotate the Token

```bash
./src/scripts/generate-token.sh > .env
docker compose -f src/docker/docker-compose.ide.yml restart
```

## Multi-Architecture Build

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f src/docker/Dockerfile.ide \
  -t devenv-ide:latest \
  src/docker/
```

## Git Configuration

### Git Identity

Set git identity inside the container:

```bash
docker exec devenv-ide-1 git config --global user.name "Your Name"
docker exec devenv-ide-1 git config --global user.email "you@example.com"
```

Or mount a `.gitconfig` from the host via an additional volume in `docker-compose.ide.yml`:

```yaml
volumes:
  - ~/.gitconfig:/home/.gitconfig:ro
```

### Git Credential Helper

For HTTPS authentication to remote repositories, configure a credential helper:

```bash
# Option 1: Store credentials in the workspace volume
docker exec devenv-ide-1 git config --global credential.helper 'store --file /home/workspace/.git-credentials'

# Option 2: Use a credential cache (expires after timeout)
docker exec devenv-ide-1 git config --global credential.helper 'cache --timeout=3600'
```

For SSH authentication, mount your SSH key directory:

```yaml
# Add to docker-compose.ide.yml volumes:
volumes:
  - ~/.ssh:/home/.ssh:ro
```

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "Connection refused" on :3000 | Container not running | `docker compose up -d` |
| 401 Unauthorized | Wrong or missing token | Check `.env` file; ensure token matches URL param |
| Extensions missing after restart | Extensions volume not mounted | Verify `volumes:` in compose file |
| High memory usage (>500MB) | Language server indexing large project | Restart container; consider increasing `mem_limit` |
| arm64 build fails | Buildx not configured | `docker buildx create --use` |

## Resource Requirements & Tuning

### Default Limits

| Resource | Default | Configurable |
|----------|---------|--------------|
| Memory | 512MB | `mem_limit` in compose |
| Swap | 512MB (same as memory) | `memswap_limit` in compose |
| Idle memory | ~23MB | N/A (server baseline) |
| Cold start | <30s | Depends on extensions |
| Warm start | <5s | N/A |
| Image size | ~848MB | N/A (base image) |

### Tuning Memory

If you experience OOM-kills with large projects or multiple language servers:

```yaml
# In docker-compose.ide.yml, increase limits:
mem_limit: 1024m
memswap_limit: 1024m
```

### Reducing Startup Time

- Minimize extensions in `extensions.json` — each adds to startup
- Use volume-persisted extensions to avoid re-downloads
- Pre-warm by keeping the container running (`restart: unless-stopped`)

### Monitoring Usage

```bash
# Real-time stats
docker stats devenv-ide-1

# One-shot measurement
docker stats devenv-ide-1 --no-stream --format "Memory: {{.MemUsage}} | CPU: {{.CPUPerc}}"
```

## Running Tests

```bash
# All integration tests
./tests/integration/test-ide-startup.sh
./tests/integration/test-ide-terminal.sh
./tests/integration/test-ide-auth.sh
./tests/integration/test-ide-extensions.sh
./tests/integration/test-ide-git.sh
./tests/integration/test-ide-volumes.sh
./tests/integration/test-ide-resources.sh

# Contract tests
./tests/contract/test-ide-interface.sh
```
