# ADR-005: Container Image Architecture

**Status**: Accepted
**Date**: 2026-01-24
**Deciders**: Project maintainers

## Context

The repository contains multiple Dockerfiles serving different purposes (base development, agent layer, IDE extensions, etc.). Without clear documentation, contributors face confusion about which image to build, extend, or debug. The multi-stage, multi-file approach enables separation of concerns but requires explicit documentation of the layering strategy and intended use cases.

## Decision

We will maintain the following container image hierarchy, each Dockerfile serving a distinct purpose with clear build and composition patterns:

### 1. `Dockerfile` (repository root)

**Purpose**: Base development container with core tooling.

**Contains**: Debian Bookworm-slim, Python 3.14+, Node.js 22.x LTS, Chezmoi, age, non-root user, bash configuration, health check.

**When to use**: As the foundation for all other images. Build directly when you need a minimal dev container without agent or IDE features.

**Build**: `docker build -t devcontainer:base .`

**Key dependencies**: debian:bookworm-slim (pinned date tag), python:3.14-slim-bookworm (multi-stage source).

### 2. `docker/Dockerfile.agent`

**Purpose**: Agent layer extending the base image with AI coding assistants (OpenCode, optionally Claude Code).

**Contains**: OpenCode binary, Claude Code (optional), agent wrapper script, session/log management libraries.

**When to use**: When running the autonomous agent workflow (`agent.sh`) or headless server mode.

**Build**: `docker build -t devcontainer:agent -f docker/Dockerfile.agent .`

**Composition**: Use with `docker/docker-compose.agent.yml` for volume mounts (agent-state, opencode-state, claude-state) and environment configuration.

**Key dependencies**: Base image (Dockerfile root), OpenCode v0.5.2, Claude Code v1.0.23 (optional).

### 3. `src/docker/Dockerfile.ai-extensions`

**Purpose**: IDE extensions layer adding VS Code AI extensions (Continue, Cline) to the development container.

**Contains**: Continue v1.2.14 VSIX, Cline v3.51.0 VSIX, extension configuration.

**When to use**: When setting up a containerized IDE with AI coding assistance extensions.

**Build**: Referenced as a build stage or composed via docker-compose.

**Key dependencies**: Base image, Continue VSIX, Cline VSIX.

### 4. `docker/entrypoint.sh`

**Purpose**: Container entrypoint that initializes the runtime environment.

**Contains**: Secrets loading (via `secrets-load.sh`), Chezmoi initialization, volume permission fixes, exec into user command.

**When to use**: Automatically invoked as the container ENTRYPOINT. Not built separately.

## Alternatives Considered

### Single Dockerfile with build stages only
- **Pros**: Single file to maintain, simpler mental model
- **Cons**: Massive file, slow rebuilds, forces all features into one image
- **Why rejected**: Violates separation of concerns; users who don't need agent capabilities shouldn't pay the image size cost.

### Separate repositories per image
- **Pros**: Independent versioning, smaller repos
- **Cons**: Cross-repo coordination for shared base, version skew, harder testing
- **Why rejected**: The images share significant infrastructure and configuration; co-location enables atomic changes.

## Consequences

### Positive
- Each image has a single responsibility and clear ownership
- Users can choose the minimal image for their use case
- Agent and IDE features don't bloat the base image
- SHA256 verification (Feature 017) can be applied per-image independently

### Negative
- Multiple Dockerfiles require understanding the layering strategy
- Changes to the base image require rebuilding downstream images
- Docker Compose files must correctly reference the build contexts

## Follow-up Actions
- [ ] Ensure CI builds validate all Dockerfiles independently
- [ ] Add image size budgets per Dockerfile to prevent bloat
