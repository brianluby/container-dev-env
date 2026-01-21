# Quickstart: Container Base Image

**Feature**: 001-container-base-image
**Date**: 2026-01-20

## Prerequisites

- Docker 24+ with buildx plugin
- 5GB free disk space
- Internet connection (for package downloads)

## Quick Build

```bash
# Clone the repository
git clone https://github.com/OWNER/container-dev-env.git
cd container-dev-env

# Build the container (auto-detects your architecture)
docker build -t devcontainer .

# Run the container
docker run -it --rm devcontainer
```

## Verify Installation

Inside the container, verify all tools are available:

```bash
# Check user
whoami          # → dev
id              # → uid=1000(dev) gid=1000(dev)

# Check tools
git --version   # → git version 2.x.x
python3 --version  # → Python 3.14.x
node --version  # → v22.x.x
npm --version   # → 10.x.x

# Check sudo
sudo whoami     # → root
```

## Common Use Cases

### 1. Mount Your Code

```bash
docker run -it --rm \
  -v "$(pwd)":/workspace \
  -w /workspace \
  devcontainer
```

### 2. Python Development

```bash
docker run -it --rm devcontainer bash -c "
  python3 -m venv .venv
  source .venv/bin/activate
  pip install flask
  python -c 'import flask; print(flask.__version__)'
"
```

### 3. Node.js Development

```bash
docker run -it --rm devcontainer bash -c "
  npm init -y
  npm install express
  node -e 'console.log(require(\"express\").version)'
"
```

### 4. Multi-Architecture Build

```bash
# Setup buildx (one-time)
docker buildx create --name multiarch --use

# Build for both architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t devcontainer:latest \
  --push \
  .
```

## File Locations

| Path | Description |
|------|-------------|
| `/home/dev` | User home directory |
| `/home/dev/.bashrc` | Bash configuration |
| `/usr/local/bin/python3` | Python 3.14 executable |
| `/usr/bin/node` | Node.js executable |

## Environment Variables

| Variable | Value |
|----------|-------|
| `HOME` | `/home/dev` |
| `USER` | `dev` |
| `SHELL` | `/bin/bash` |
| `LANG` | `en_US.UTF-8` |

## Troubleshooting

### Build fails with network error

```bash
# Retry with fresh layer cache
docker build --no-cache -t devcontainer .
```

### Permission denied on mounted volume

```bash
# Use same UID as container user
docker run -it --rm \
  -u "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace \
  devcontainer
```

### Wrong architecture

```bash
# Force specific platform
docker run --platform linux/amd64 -it --rm devcontainer
```

## Next Steps

After verifying the base image works:

1. **Dotfile management** - See 002-prd-dotfile-management
2. **Secret injection** - See 003-prd-secret-injection
3. **Volume architecture** - See 004-prd-volume-architecture
