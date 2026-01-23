# Implementation Plan: Git Worktree Compatibility

**Branch**: `007-git-worktree-compat` | **Date**: 2026-01-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-git-worktree-compat/spec.md`

## Summary

Add git worktree detection and validation to the container entrypoint script. On every container start, the script checks whether the workspace contains a git worktree (`.git` file) and validates that the referenced git metadata directory is accessible. If inaccessible, a non-blocking stderr warning is printed with an actionable fix recommendation. AI agents (Claude Code, Aider) natively support worktrees — no agent-side changes needed.

## Technical Context

**Language/Version**: Bash (POSIX-compatible, targeting bash 5.x in Debian Bookworm)
**Primary Dependencies**: git CLI (already in base image per 001-container-base-image)
**Storage**: N/A (filesystem checks only)
**Testing**: BATS (Bash Automated Testing System) for unit tests; Docker-based integration tests
**Target Platform**: Linux (Debian Bookworm-slim container, arm64 + amd64)
**Project Type**: Single (shell script addition to existing entrypoint)
**Performance Goals**: Worktree validation completes in <100ms (SC-002 allows 2s, but check is trivial)
**Constraints**: Non-blocking (must not prevent container startup), stderr-only output, no additional dependencies
**Scale/Scope**: Single workspace directory per container instance

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | PASS | Entrypoint script runs inside container; no host-side changes |
| II. Multi-Language Standards | PASS | Bash follows shell best practices (set -e, shellcheck) |
| III. Test-First Development | PASS | BATS tests written before implementation |
| IV. Security-First Design | PASS | No secrets involved; validates paths without following symlinks unsafely |
| V. Reproducibility & Portability | PASS | Deterministic behavior; works on arm64 + amd64 identically |
| VI. Observability & Debuggability | PASS | Uses structured stderr logging (matches existing `log_warning` pattern) |
| VII. Simplicity & Pragmatism | PASS | ~30 lines of shell code added to existing entrypoint; no new dependencies |

**Gate Result**: ALL PASS — proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/007-git-worktree-compat/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── build-contract.md
│   └── test-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
docker/
└── entrypoint.sh            # Existing entrypoint; add validate_worktree() function

tests/
├── unit/
│   └── test_worktree_validation.bats   # BATS unit tests for validation logic
└── integration/
    └── test_worktree_container.sh      # Docker-based integration tests
```

**Structure Decision**: The implementation adds a single function (`validate_worktree`) to the existing `docker/entrypoint.sh` file. Tests use BATS for unit testing the function logic in isolation, and shell scripts with Docker for integration testing the full container startup behavior.

## Complexity Tracking

> No violations detected. No complexity justifications needed.
