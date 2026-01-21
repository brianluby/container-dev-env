# Implementation Plan: Container Base Image

**Branch**: `001-container-base-image` | **Date**: 2026-01-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-container-base-image/spec.md`

## Summary

Create a reproducible, multi-architecture development container image based on Debian Bookworm-slim. The container provides a non-root user (`dev`) with sudo access, pre-installed development tools (git, curl, wget, jq, make, build-essential), Python 3.14+ with pip/uv, Node.js LTS with npm, and a properly configured bash shell. The image must build in under 5 minutes, remain under 2GB compressed, and work identically on arm64 (Apple Silicon) and amd64 architectures.

## Technical Context

**Language/Version**: Dockerfile (multi-stage), Bash for shell configuration
**Primary Dependencies**: Debian Bookworm-slim base image, Python 3.14+, Node.js LTS (22.x)
**Storage**: N/A (stateless container image)
**Testing**: Shell-based acceptance tests (`docker run` commands), GitHub Actions CI
**Target Platform**: Linux containers on arm64 (Apple Silicon) and amd64 (Intel/AMD)
**Project Type**: Single project (Dockerfile + supporting scripts)
**Performance Goals**: Build time <5 minutes on CI, container startup <5 seconds
**Constraints**: Image size <2GB compressed, all components MIT-compatible licensed
**Scale/Scope**: Foundation layer for development environment, blocks 3 downstream PRDs

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence/Notes |
|-----------|--------|----------------|
| **I. Container-First Architecture** | PASS | Feature is literally the container base image; Dockerfile is source of truth |
| **II. Multi-Language Standards** | PASS | Python 3.14+ and Node.js LTS included per spec; Go/Rust optional (COULD) |
| **III. Test-First Development** | PASS | Acceptance scenarios defined in spec with docker run commands |
| **IV. Security-First Design** | PASS | Non-root user `dev` with sudo; no secrets baked in; slim base image |
| **V. Reproducibility & Portability** | PASS | Multi-arch (arm64+amd64); pinned versions; weekly rebuild for CVEs |
| **VI. Observability & Debuggability** | PASS | Health check mechanism (FR-010); bash with history/aliases configured |
| **VII. Simplicity & Pragmatism** | PASS | Single Dockerfile; minimal tool set; no premature optimization |

**Gate Result**: PASS - All constitution principles satisfied. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-container-base-image/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (minimal for container)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (build/test contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Dockerfile                    # Main container definition
.dockerignore                 # Build context optimization
scripts/
├── health-check.sh          # Container health check script
└── test-container.sh        # Acceptance test runner
.github/
└── workflows/
    └── container-build.yml  # Weekly rebuild + multi-arch CI
```

**Structure Decision**: Single project structure. This is a foundation-layer container image with no application code. The Dockerfile lives at repository root for standard `docker build .` workflow. Supporting scripts in `scripts/` directory. CI workflow for automated weekly rebuilds with multi-architecture support.

## Complexity Tracking

> No violations. Constitution check passed with no justified complexity.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 design completion.*

| Principle | Status | Post-Design Evidence |
|-----------|--------|---------------------|
| **I. Container-First Architecture** | PASS | Dockerfile is sole source; multi-stage build; pinned base image |
| **II. Multi-Language Standards** | PASS | Python 3.14 via official image; Node 22.x via NodeSource |
| **III. Test-First Development** | PASS | test-contract.md defines 30+ acceptance tests before implementation |
| **IV. Security-First Design** | PASS | Non-root `dev` user; UID 1000 for volume compatibility; no secrets |
| **V. Reproducibility & Portability** | PASS | Date-pinned base image; multi-arch manifest; weekly CVE rebuilds |
| **VI. Observability & Debuggability** | PASS | health-check.sh validates tools; structured test output |
| **VII. Simplicity & Pragmatism** | PASS | Single Dockerfile; NodeSource vs multi-stage Node; minimal layers |

**Post-Design Gate Result**: PASS - Design artifacts comply with all constitution principles.

## Generated Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Research | `research.md` | Technical decisions for multi-arch, Python, Node, base image |
| Data Model | `data-model.md` | Entity definitions for container, user, tools |
| Build Contract | `contracts/build-contract.md` | Build inputs, outputs, success criteria |
| Test Contract | `contracts/test-contract.md` | 30+ acceptance tests with commands |
| Quickstart | `quickstart.md` | Developer onboarding guide |
| Agent Context | `CLAUDE.md` | Updated with feature technology stack |

## Next Steps

Run `/speckit.tasks` to generate the implementation task breakdown.
