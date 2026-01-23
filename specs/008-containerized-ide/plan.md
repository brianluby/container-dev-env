# Implementation Plan: Containerized IDE

**Branch**: `008-containerized-ide` | **Date**: 2026-01-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-containerized-ide/spec.md`

## Summary

Implement a browser-accessible VS Code-compatible IDE by layering OpenVSCode-Server (Gitpod, MIT license) onto the existing base container image. The IDE exposes a single HTTP/WebSocket port (3000) with connection-token authentication, uses Docker named volumes for workspace and extension persistence, and supports declarative extension management via a JSON manifest. The implementation is a Dockerfile layer, an entrypoint script, a Docker Compose service definition, and integration tests.

## Technical Context

**Language/Version**: Bash 5.x (scripts, entrypoint), Dockerfile syntax (container layer)
**Primary Dependencies**: OpenVSCode-Server (gitpod/openvscode-server, MIT), Open VSX registry (extensions)
**Storage**: Docker named volumes (workspace at `/home/workspace`, extensions at `/home/.openvscode-server/extensions`)
**Testing**: Bash integration tests (container lifecycle), curl/wget for HTTP assertions, `docker stats` for resource validation
**Target Platform**: Linux containers (Debian Bookworm-slim base), multi-arch (linux/amd64, linux/arm64)
**Project Type**: Single project (Dockerfile + scripts + compose)
**Performance Goals**: <30s cold start, <50MB idle memory, <1GB image size
**Constraints**: 512MB memory limit, single port (3000), non-root (UID 1000), localhost binding by default, MIT/Apache licensed dependencies only
**Scale/Scope**: Single-user local development; one container instance per developer

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ✅ PASS | IDE runs entirely in Docker; Dockerfile is source of truth; multi-arch via buildx |
| II. Multi-Language Standards | ✅ PASS | Bash scripts follow shellcheck; no application code in other languages for this feature |
| III. Test-First Development | ✅ PASS | Integration tests validate container behavior (HTTP response, auth, volumes) |
| IV. Security-First Design | ✅ PASS | Non-root user, token auth, no secrets in image, localhost binding |
| V. Reproducibility & Portability | ✅ PASS | Pinned image version, multi-arch manifest, named volumes, declarative config |
| VI. Observability & Debuggability | ✅ PASS | Server logs to stdout/stderr; docker logs captures output; health check on :3000 |
| VII. Simplicity & Pragmatism | ✅ PASS | Single Dockerfile layer + entrypoint script; no microservices, no orchestration beyond compose |

**Gate Result**: PASS — No violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/008-containerized-ide/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── docker-compose.yml
├── checklists/
│   └── requirements.md  # Quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
src/
├── docker/
│   ├── Dockerfile.ide           # IDE layer (FROM gitpod/openvscode-server)
│   └── docker-compose.ide.yml   # IDE service definition
├── scripts/
│   ├── ide-entrypoint.sh        # Extension install + server launch
│   └── generate-token.sh        # Token generation helper
└── config/
    └── extensions.json          # Declarative extension manifest

tests/
├── integration/
│   ├── test-ide-startup.sh      # Container starts, HTTP 200 on :3000
│   ├── test-ide-auth.sh         # Token auth rejects/accepts correctly
│   ├── test-ide-extensions.sh   # Extensions install from manifest
│   ├── test-ide-volumes.sh      # Workspace/extension persistence
│   ├── test-ide-terminal.sh     # PTY terminal works
│   └── test-ide-multiarch.sh    # arm64/amd64 build verification
└── contract/
    └── test-ide-interface.sh    # Port, user, binding validation
```

**Structure Decision**: Single project with Dockerfile + Bash scripts. No application code beyond container configuration and integration tests. This aligns with Constitution Principle VII (simplicity) — the IDE is a pre-built binary configured via Dockerfile, not custom application code.

## Complexity Tracking

No violations to justify. Architecture is minimal: one Dockerfile layer, one entrypoint script, one compose service.
