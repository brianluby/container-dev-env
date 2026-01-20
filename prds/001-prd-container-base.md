# 001-prd-container-base

## Problem Statement

Development environment configuration is not reproducible across machines.
Installing tools directly on host creates drift, conflicts, and "works on my
machine" problems. A containerized base image provides isolation and
repeatability for all subsequent AI-assisted development tooling.

## Requirements

### Must Have (M)

- [ ] Single Dockerfile produces working dev container
- [ ] Non-root user with sudo access
- [ ] Common dev tools: git, curl, wget, jq, make, build-essential
- [ ] Shell environment: bash with sane defaults
- [ ] Works on arm64 (Apple Silicon) and amd64
- [ ] Image builds in under 5 minutes on CI
- [ ] Base image is open source with MIT-compatible license

### Should Have (S)

- [ ] Python 3.14+ with pip and ux available
- [ ] Node.js LTS with npm available
- [ ] Container size under 2GB
- [ ] Health check endpoint or script

### Could Have (C)

- [ ] Go toolchain pre-installed
- [ ] Rust toolchain pre-installed
- [ ] Pre-configured locale (UTF-8)
- [ ] Alpine variant for users who prefer minimal images (requires musl workarounds)

### Won't Have (W)

- [ ] GUI applications
- [ ] Desktop environment
- [ ] Specific AI tools (covered in later PRDs)
- [ ] IDE (covered in 00X-prd-containerized-ide)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| MIT-compatible license | Must | Repo will be open source |
| Multi-arch support | Must | M1/M2 Mac + Linux CI |
| Active maintenance | High | Updates for CVEs |
| Minimal attack surface | High | Smaller is better |
| Ecosystem familiarity | Medium | Debian/Ubuntu preferred for docs availability |
| Build speed | Medium | Fast iteration during development |

## Tool Candidates

| Base Image | License | Pros | Cons | Spike Result |
|------------|---------|------|------|--------------|
| Debian Bookworm-slim | DFSG (MIT-compatible) | Stable, glibc compat, smaller than Ubuntu, fully open | Slightly older packages | **Selected** |
| Ubuntu 24.04 | Mixed (but container use OK) | Familiar, huge ecosystem, great docs | Larger size, some non-free components | Not evaluated |
| Wolfi | Apache 2.0 | Minimal, security-focused, apk fast | Newer, smaller ecosystem, less familiar | Not evaluated |
| Alpine | MIT | Tiny, fast builds | musl libc breaks some Python/Node packages | Future variant |

## Selected Approach

**Debian Bookworm-slim** as the primary base image.

Rationale:

- **glibc compatibility**: Python wheels and Node.js native extensions work without workarounds
- **Developer productivity**: No time spent debugging musl-specific issues
- **License**: DFSG-compliant, suitable for open source project
- **Size**: Slim variant keeps image reasonably small (~80MB base)
- **Ecosystem**: Excellent documentation and community support

Note: Alpine variant may be added as a "Could Have" in the future for users who prefer minimal images and are willing to handle musl compatibility.

## Acceptance Criteria

- [ ] Given a clean Docker host, when I run `docker build -t devcontainer .`, then build completes without error
- [ ] Given the built image, when I run `docker run --rm devcontainer whoami`, then output is non-root username
- [ ] Given the built image, when I run `docker run --rm devcontainer git --version`, then git is available
- [ ] Given the built image, when I run `docker run --rm devcontainer python3 --version`, then Python 3.11+ responds
- [ ] Given the built image, when I run `docker run --rm devcontainer node --version`, then Node LTS responds
- [ ] Given arm64 and amd64 hosts, when I build the image, then both architectures succeed
- [ ] Given the Dockerfile, when reviewed for licenses, then all components are MIT-compatible

## Dependencies

- Requires: none (this is the foundation)
- Blocks: 002-prd-dotfile-management, 003-prd-secret-injection, 004-prd-volume-architecture

## Spike Tasks

- [ ] Build Debian Bookworm-slim base with all Must Have requirements
- [ ] Measure image size and build time
- [ ] Test Python package installation (numpy, pandas)
- [ ] Test Node package installation (typescript, eslint)
- [ ] Verify multi-arch build with `docker buildx` (arm64 + amd64)
- [ ] Document license audit for Debian base components
