# Implementation Plan: Volume Architecture for Development Containers

**Branch**: `004-volume-architecture` | **Date**: 2026-01-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-volume-architecture/spec.md`

## Summary

Implement a hybrid volume architecture combining bind mounts for source code (host access), named volumes for persistent data (home directory, package caches), and tmpfs for ephemeral storage (/tmp). The system uses dynamic UID detection at container start to resolve permission conflicts between macOS (UID 501) and Linux (UID 1000+) hosts.

## Technical Context

**Language/Version**: Bash (entrypoint scripts), Dockerfile (multi-stage)
**Primary Dependencies**: Docker 24+, Docker Compose 2.x, Docker Buildx (multi-arch)
**Storage**: Bind mounts (workspace), Named volumes (home, caches), tmpfs (/tmp)
**Testing**: Bash integration tests, docker-compose test scenarios
**Target Platform**: Docker Desktop (macOS VirtioFS), Linux (native), arm64 + amd64
**Project Type**: Infrastructure (container configuration)
**Performance Goals**: <1s file sync, <10s npm install (50+ deps), <3s container startup
**Constraints**: Single-container volume access only, <15 lines volume config in compose
**Scale/Scope**: Single developer workstation, multiple project workspaces

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ✅ PASS | All components containerized; bind mounts preserve host access without host pollution |
| II. Multi-Language Standards | ✅ PASS | Volume architecture supports Rust, Python, Node.js, Go package caches |
| III. Test-First Development | ✅ PASS | Integration tests planned for each volume type and permission scenario |
| IV. Security-First Design | ✅ PASS | Non-root user with dynamic UID; no secrets in volumes; tmpfs for sensitive temp data |
| V. Reproducibility & Portability | ✅ PASS | arm64 + amd64 support; dynamic UID handles cross-platform; pinned base images |
| VI. Observability & Debuggability | ✅ PASS | FR-014 requires startup logging of volume status and UID mapping |
| VII. Simplicity & Pragmatism | ✅ PASS | Minimal config (<15 lines); standard Docker patterns; no custom orchestration |

**Gate Result**: PASS - No violations. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/004-volume-architecture/
├── plan.md              # This file
├── research.md          # Phase 0: Research findings
├── data-model.md        # Phase 1: Volume entity definitions
├── quickstart.md        # Phase 1: Getting started guide
├── contracts/           # Phase 1: Configuration contracts
│   └── docker-compose.volumes.yml  # Volume configuration template
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Infrastructure configuration (container-first project)
docker/
├── Dockerfile           # Multi-stage build with volume mount points
├── docker-compose.yml   # Main compose with volume definitions
└── entrypoint.sh        # Dynamic UID detection and volume validation

scripts/
└── volume-health.sh     # Volume status diagnostic script

tests/
└── integration/
    ├── test-bind-mount.sh       # Host ↔ container sync tests
    ├── test-named-volumes.sh    # Persistence across restart tests
    ├── test-tmpfs.sh            # Ephemeral storage tests
    └── test-permissions.sh      # UID mapping tests

docs/
└── volume-architecture.md       # User-facing documentation (FR-010)
```

**Structure Decision**: Infrastructure/container configuration project. No traditional src/ directory - primary deliverables are Docker configuration files, entrypoint scripts, and integration tests.

## Complexity Tracking

> No violations - section not required.
