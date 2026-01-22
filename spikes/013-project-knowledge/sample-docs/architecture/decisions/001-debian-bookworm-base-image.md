# ADR-001: Use Debian Bookworm-slim as Container Base Image

<!--
AI Agent Instructions:
- This ADR documents the foundation of the container-dev-env project
- The base image affects all downstream components
- Do not propose Alpine or other base images without reviewing trade-offs
- glibc compatibility is critical for Python and Node.js packages
-->

## Metadata

| Field | Value |
|-------|-------|
| Status | Accepted |
| Date | 2024-01-15 |
| Decision Makers | @brianluby |
| Tags | infrastructure, container, foundation |

## Context

The container-dev-env project needs a base container image that provides:

1. **Reproducibility**: Same environment across all developers and CI
2. **Tool compatibility**: Python, Node.js, and native packages must work
3. **Architecture support**: Must run on arm64 (Apple Silicon) and amd64
4. **Open source**: MIT-compatible license for the project
5. **Developer productivity**: Minimize time spent debugging container issues

The choice of base image fundamentally affects all subsequent tooling decisions and developer experience.

## Decision

We will use **Debian Bookworm-slim** as the primary base container image.

### Implementation Details

1. Use `debian:bookworm-slim` as the FROM image in Dockerfile
2. Install common dev tools: git, curl, wget, jq, make, build-essential
3. Create non-root user with sudo access
4. Configure UTF-8 locale
5. Use multi-stage builds to minimize final image size

## Consequences

### Positive

- **glibc compatibility**: Python wheels and Node.js native extensions work without workarounds
- **Familiar ecosystem**: Debian/Ubuntu commands and documentation apply
- **Stable packages**: Bookworm is a stable release with security updates
- **Small base**: Slim variant is ~80MB, much smaller than full Debian/Ubuntu
- **Wide architecture support**: Official arm64 and amd64 images available
- **DFSG-compliant license**: Fully compatible with MIT open source project

### Negative

- **Slightly older packages**: May need to add upstream repos for latest versions
- **Not as minimal as Alpine**: Larger than musl-based images
- **Mitigation**: Use multi-stage builds and cleanup to reduce size

### Neutral

- Build time is acceptable (~2-3 minutes on CI)
- Image size will grow as tools are added (managed via multi-stage builds)

## Alternatives Considered

### Alternative 1: Alpine Linux

**Description**: Minimal Linux distribution using musl libc and busybox

**Pros**:
- Extremely small base image (~5MB)
- Fast builds
- Security-focused with minimal attack surface

**Cons**:
- musl libc breaks many Python packages (numpy, pandas require special builds)
- Node.js native modules often fail
- Developer time wasted debugging musl-specific issues

**Why Rejected**: glibc compatibility is essential for developer productivity. The time saved on smaller images is lost debugging musl issues.

### Alternative 2: Ubuntu 24.04

**Description**: Popular Linux distribution with extensive ecosystem

**Pros**:
- Huge ecosystem and documentation
- Very familiar to most developers
- Latest packages available

**Cons**:
- Larger base size than Debian-slim
- Some non-free components in default install
- More bloat than needed for dev containers

**Why Rejected**: Debian-slim provides the same glibc compatibility with smaller size and cleaner licensing.

### Alternative 3: Wolfi

**Description**: Security-focused, minimal container OS by Chainguard

**Pros**:
- Purpose-built for containers
- Excellent security posture
- Fast package manager (apk)

**Cons**:
- Newer project with smaller ecosystem
- Less familiar to developers
- Fewer pre-built packages available

**Why Rejected**: Ecosystem maturity and familiarity favor Debian for this project's goals.

## References

- [PRD-001: Container Base Image](../../../prds/001-prd-container-base.md)
- [Debian Bookworm Release Notes](https://www.debian.org/releases/bookworm/)
- [Docker Official Debian Images](https://hub.docker.com/_/debian)
- [Discussion: Alpine vs Debian for containers](https://pythonspeed.com/articles/alpine-docker-python/)
