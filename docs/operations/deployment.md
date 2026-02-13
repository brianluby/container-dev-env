# Deployment

This page is a reference for building and running the container images and Compose stacks.
For step-by-step operational procedures, use the runbooks in [Operations](index.md).

Applies to: `main`

## Prerequisites

- Docker + Compose v2
- [Getting Started](../getting-started/index.md)

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

## Digest Implementation Notes

### In-scope Dockerfiles

- `Dockerfile`
- `docker/Dockerfile`
- `docker/Dockerfile.ide`
- `docker/memory.Dockerfile`

### Out-of-scope Dockerfiles

- Any Dockerfiles under `spikes/`
- Any Dockerfiles not explicitly listed in the in-scope inventory above

### Validation gates

- All external `FROM` references in in-scope Dockerfiles must use `tag@digest`
- `scripts/validate-base-image-digests.sh` must pass locally
- CI `container-build.yml` must pass with digest validation enabled
- Digest coverage must include both `linux/amd64` and `linux/arm64`

### Evidence requirements

- Record old and new digest values per updated Dockerfile
- Record local validator output
- Record CI run URL proving digest validation passed
- Record reproducibility evidence from two successive validation runs

### Hard failure policy for unsupported architectures

If any selected digest does not cover both `linux/amd64` and `linux/arm64`, treat the change as failed. Do not merge partial architecture coverage.

### Two-run reproducibility evidence

Run digest validation twice with no source changes and record that outputs match.

```bash
./scripts/validate-base-image-digests.sh --json > /tmp/digest-run-1.json
./scripts/validate-base-image-digests.sh --json > /tmp/digest-run-2.json
diff -u /tmp/digest-run-1.json /tmp/digest-run-2.json
```

### Digest refresh procedure

1. Identify upstream tags currently referenced in in-scope Dockerfiles.
2. Resolve new candidate digest values.
3. Confirm `linux/amd64` and `linux/arm64` coverage for each digest.
4. Update in-scope Dockerfiles to new `tag@digest` references.
5. Run local validation and repeat-run reproducibility checks.
6. Push branch and verify CI digest validation passes.
7. Capture evidence in PR (old/new digest map + validation outputs).

### Timed refresh validation (under 30 minutes)

Measure one end-to-end refresh cycle and verify completion in less than 30 minutes.

```bash
start_ts=$(date +%s)
# perform refresh procedure steps
end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))
echo "Refresh cycle duration: ${elapsed} seconds"
test "${elapsed}" -lt 1800
```

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

- [Operations](index.md)
- [Architecture Overview](../architecture/overview.md)

## Next steps

- If you need a rebuild procedure: [Container Rebuild](container-rebuild.md)
