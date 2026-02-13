# Implementation Plan: Pin Base Images to Immutable Digests

**Branch**: `001-pin-image-digests` | **Date**: 2026-02-12 | **Spec**: `/Users/bluby/personal_repos/container-dev-env_specs/001-pin-image-digests/specs/001-pin-image-digests/spec.md`
**Input**: Feature specification from `/specs/001-pin-image-digests/spec.md`

## Summary

Pin external base image `FROM` references to immutable digests for four in-scope Dockerfiles (`Dockerfile`, `docker/Dockerfile`, `docker/Dockerfile.ide`, `docker/memory.Dockerfile`) to eliminate upstream tag drift. Enforce full multi-architecture digest coverage (amd64 + arm64), and require both local and CI verification before completion.

## Technical Context

**Language/Version**: Dockerfile syntax, Bash 5.x, Markdown  
**Primary Dependencies**: Docker Buildx, Docker Compose v2, GitHub Actions workflows  
**Storage**: Git repository files (Dockerfiles, docs, workflow files)  
**Testing**: Existing local verification scripts + CI build/test workflows (including multi-arch build validation)  
**Target Platform**: Linux containers on `linux/amd64` and `linux/arm64`  
**Project Type**: Single repository infrastructure/tooling project  
**Performance Goals**: Preserve existing CI build expectations (under 5 minutes target) and image size budget constraints  
**Constraints**: Scope limited to four Dockerfiles; fail on missing multi-arch digest coverage; pass local and CI gates  
**Scale/Scope**: One feature touching four Dockerfiles plus planning/design artifacts and verification guidance

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate Review

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Container-First Architecture | Declarative, versioned container definitions | PASS | Feature strengthens this by pinning immutable digest references. |
| II. Multi-Language Standards | Follow language quality gates | PASS | No new language runtime code introduced. Existing standards unchanged. |
| III. Test-First Development | Automated validation for new behavior | PASS | Validation criteria include local and CI build verification for pinned references. |
| IV. Security-First Design | Pin digests, reduce supply-chain drift | PASS | Feature directly addresses digest pinning requirement. |
| V. Reproducibility & Portability | Deterministic builds on amd64 + arm64 | PASS | Clarified to fail if both supported architectures are not covered. |
| VI. Observability & Debuggability | Clear validation and failure signals | PASS | Plan includes explicit verification outputs and failure conditions. |
| VII. Simplicity & Pragmatism | Minimize blast radius | PASS | Scope constrained to four Dockerfiles only. |

**Gate Result (Pre-Research)**: PASS

## Project Structure

### Documentation (this feature)

```text
specs/001-pin-image-digests/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Dockerfile
docker/
├── Dockerfile
├── Dockerfile.ide
└── memory.Dockerfile

.github/
├── workflows/
└── pull_request_template.md

scripts/
tests/
```

**Structure Decision**: Use the existing single-repository infrastructure layout and modify only in-scope Dockerfiles plus any required verification/documentation paths.

## Phase 0: Outline & Research

### Research Inputs

- Best-practice research on digest pinning strategy for multi-arch images.
- Decision strategy for missing digest coverage across supported architectures.
- Verification approach ensuring deterministic behavior in both local and CI environments.

### Research Output

- `/Users/bluby/personal_repos/container-dev-env_specs/001-pin-image-digests/specs/001-pin-image-digests/research.md`

## Phase 1: Design & Contracts

### Design Artifacts

- Data model: `/Users/bluby/personal_repos/container-dev-env_specs/001-pin-image-digests/specs/001-pin-image-digests/data-model.md`
- Contracts directory: `/Users/bluby/personal_repos/container-dev-env_specs/001-pin-image-digests/specs/001-pin-image-digests/contracts/`
- Quickstart: `/Users/bluby/personal_repos/container-dev-env_specs/001-pin-image-digests/specs/001-pin-image-digests/quickstart.md`

### Contract Strategy

- Define an OpenAPI-style planning contract for digest compliance validation workflows (scope check, coverage validation, verification gate execution).
- Map each core user action in spec to a contract operation for implementation and test decomposition.

### Agent Context Update

- Run `.specify/scripts/bash/update-agent-context.sh opencode` after design artifacts are created.

## Post-Design Constitution Re-Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | PASS | Design remains container-definition centric; no host-only behavior added. |
| III. Test-First Development | PASS | Plan artifacts define verifiable acceptance checks for local + CI. |
| IV. Security-First Design | PASS | Digest pinning and architecture coverage enforcement maintained. |
| V. Reproducibility & Portability | PASS | Multi-arch determinism and failure-on-missing-coverage captured in requirements. |
| VII. Simplicity & Pragmatism | PASS | Scope isolation to four Dockerfiles preserved. |

**Gate Result (Post-Design)**: PASS

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

## Verification Evidence Summary

- In-scope Dockerfiles use `tag@digest` for external `FROM` references.
- Digest validator script is wired for both local and CI execution.
- Reproducibility check requires two matching validator runs.
- Refresh workflow includes explicit under-30-minute timing validation.
