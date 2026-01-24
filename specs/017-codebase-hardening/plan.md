# Implementation Plan: Codebase Hardening

**Branch**: `017-codebase-hardening` | **Date**: 2026-01-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/017-codebase-hardening/spec.md`

## Summary

Systematic security hardening addressing command injection in the agent wrapper, JSON injection in session/log management, missing supply-chain verification for container downloads, unsafe secrets loading via `source`, exposed network ports, incomplete CI triggers, and inconsistent shell practices. All fixes are Bash-level changes with BATS test coverage.

## Technical Context

**Language/Version**: Bash 5.x (all scripts), Dockerfile syntax
**Primary Dependencies**: jq (JSON construction), BATS (testing), ShellCheck (linting), age (encryption)
**Storage**: File-based (JSON sessions, JSONL logs, KEY=VALUE secrets files)
**Testing**: BATS unit tests, shell integration tests, container acceptance tests
**Target Platform**: Linux containers (Debian Bookworm-slim), arm64 + amd64
**Project Type**: Single project (container dev environment with shell scripts)
**Performance Goals**: N/A (security-focused feature)
**Constraints**: No new runtime dependencies beyond what's in the base image; `jq` already available
**Scale/Scope**: ~70 shell scripts, 8 Dockerfiles, 2 CI workflows, 4 secrets management scripts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First | PASS | All changes are within container image or container-executed scripts |
| II. Multi-Language Standards | PASS | Bash-only changes; ShellCheck linting applies |
| III. Test-First Development | PASS | BATS tests required for all security fixes |
| IV. Security-First Design | PASS | This feature *implements* security hardening |
| V. Reproducibility & Portability | PASS | Checksum manifest + SHA pinning improves reproducibility |
| VI. Observability & Debuggability | PASS | Standardized `[ERROR]/[WARN]` prefix improves debuggability |
| VII. Simplicity & Pragmatism | PASS | Minimal changes to fix known vulnerabilities; no over-engineering |

## Project Structure

### Documentation (this feature)

```text
specs/017-codebase-hardening/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Existing structure — files to modify
src/agent/
├── agent.sh                    # Fix eval-based command execution (FR-001)
└── lib/
    ├── session.sh              # Fix JSON injection in session creation (FR-002)
    ├── log.sh                  # Fix JSON injection in log_action (FR-002)
    └── provider.sh             # Fix build_backend_command to avoid eval (FR-001)

scripts/
├── secrets-load.sh             # Rewrite to safe line-by-line parser (FR-004/005/006/014/017)
├── secrets-edit.sh             # Fix special character handling (FR-011)
└── secrets-common.sh           # Shared utilities for hardened secrets handling

docker/
├── Dockerfile.agent            # Add checksum verification, localhost binding (FR-003/007/008)
└── docker-compose.agent.yml    # Bind port to 127.0.0.1 (FR-007)

.github/
├── workflows/
│   ├── container-build.yml     # Expand path filters, pin SHAs (FR-009/010)
│   └── worktree-tests.yml      # Pin SHAs (FR-009)
└── dependabot.yml              # New: monitor actions + base images (FR-015)

# New files
checksums.sha256                # Centralized checksum manifest (FR-003)
docs/adr/                       # Container image ADR (FR-013)
tests/unit/
├── test_secrets_load.bats      # Secrets loader security tests
├── test_agent_injection.bats   # Command injection tests
└── test_json_escape.bats       # JSON construction tests
```

**Structure Decision**: Single project with existing directory layout preserved. New test files added to existing `tests/unit/` directory. New `checksums.sha256` at repository root per clarification. New ADR under `docs/adr/`.

## Complexity Tracking

No constitution violations requiring justification.
