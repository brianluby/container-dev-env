# Deployment

This page is a reference for building and running the container images and Compose stacks.
For step-by-step operational procedures, use the runbooks in `docs/operations/index.md`.

Applies to: `main`

## Prerequisites

- Docker + Compose v2
- `docs/getting-started/index.md`

## Container build workflow

### Build the base image

```bash
# Build for current architecture
docker build -t container-dev-env:latest .

# Build for multi-architecture (arm64 + amd64)
docker buildx build --platform linux/arm64,linux/amd64 -t container-dev-env:latest .
```

### Build verification

After building, verify the image meets requirements:

```bash
# Verify non-root user
docker run --rm container-dev-env:latest whoami
# Expected: developer (not root)

# Verify tools are available
docker run --rm container-dev-env:latest bash -c "git --version && python3 --version && node --version"

# Verify image size
docker images container-dev-env:latest --format "{{.Size}}"
# Expected: under 2GB
```

### Multi-Stage Build Structure

The Dockerfile uses multi-stage builds to minimize final image size:

1. **Builder stage**: Install build dependencies, compile tools
2. **Runtime stage**: Copy only necessary artifacts from builder
3. **Final stage**: Add user configuration and entrypoint

## Deployment targets

### Local development

```bash
docker compose -f docker/docker-compose.yml up -d --build
docker compose -f docker/docker-compose.yml exec dev bash
```

### CI/CD Pipeline

The container image is used in CI for consistent build environments:

- Build and test in the same image used for development
- Pin image versions in CI configuration (no `:latest` in production)
- Cache Docker layers for faster CI builds

## Volume architecture

Persistent state is maintained via Docker volumes:

See `docker/docker-compose.yml` for the authoritative volume list.

## Health checks

Container health is verified via:

```bash
# Basic health check (in Dockerfile HEALTHCHECK)
HEALTHCHECK --interval=30s --timeout=5s \
  CMD bash -c "type git && type python3 && type node" || exit 1
```

## Troubleshooting

### Common Issues

**Build fails on arm64**:
- Check that all installed packages have arm64 variants
- Use `--platform` flag with buildx

**Container exits immediately**:
- Ensure entrypoint script exists and is executable
- Check for missing environment variables

**Permission denied on mounted volumes**:
- Verify UID/GID match between host and container user
- Default container user is UID 1000

**Slow builds**:
- Enable BuildKit: `DOCKER_BUILDKIT=1`
- Use `.dockerignore` to exclude unnecessary files
- Order Dockerfile layers for optimal cache hits

## Related

- `docs/operations/index.md`
- `docs/architecture/overview.md`

## Next steps

- If you need a rebuild procedure: `docs/operations/container-rebuild.md`
