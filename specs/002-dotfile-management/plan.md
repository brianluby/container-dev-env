# Implementation Plan: Dotfile Management with Chezmoi

**Branch**: `002-dotfile-management` | **Date**: 2026-01-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-dotfile-management/spec.md`

## Summary

Add Chezmoi to the container base image for portable, template-based dotfile management. Chezmoi enables developers to bootstrap personalized shell configuration, git settings, and editor preferences from a git repository with machine-specific value substitution via Go templates. This builds on the foundation established in 001-container-base-image.

## Technical Context

**Language/Version**: Bash for installation scripts, Go templates for Chezmoi configs (user-provided)
**Primary Dependencies**: Chezmoi (single binary, MIT license), age (encryption, optional)
**Storage**: File-based (~/.local/share/chezmoi for source, ~ for targets)
**Testing**: Bash-based acceptance tests (docker run commands)
**Target Platform**: Linux containers (Debian Bookworm-slim), arm64 + amd64
**Project Type**: Container image extension (Dockerfile modification)
**Performance Goals**: Bootstrap complete in <30 seconds
**Constraints**: Image size increase <50MB, offline operation after initial sync
**Scale/Scope**: Single-user development containers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ✅ PASS | Chezmoi installed in container image via Dockerfile |
| II. Multi-Language Standards | ✅ PASS | Not language-specific; supports all language configs |
| III. Test-First Development | ✅ PASS | Acceptance tests defined in spec; test script planned |
| IV. Security-First Design | ✅ PASS | No secrets baked in; age encryption for semi-sensitive files |
| V. Reproducibility & Portability | ✅ PASS | Pinned Chezmoi version; works on arm64 + amd64 |
| VI. Observability & Debuggability | ✅ PASS | Chezmoi provides diff, status, verbose modes |
| VII. Simplicity & Pragmatism | ✅ PASS | Single binary addition; minimal complexity |

**Gate Status**: PASSED - All principles satisfied.

## Project Structure

### Documentation (this feature)

```text
specs/002-dotfile-management/
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
# Dockerfile modification (extends 001-container-base-image)
Dockerfile               # Add Chezmoi installation layer

# Supporting scripts
scripts/
├── health-check.sh      # Existing - verify Chezmoi available
└── test-container.sh    # Existing - add Chezmoi tests

# Documentation
docs/
└── dotfiles-quickstart.md  # User-facing bootstrap guide (optional)
```

**Structure Decision**: This feature extends the existing Dockerfile rather than creating new source files. The primary deliverable is Dockerfile modifications to install Chezmoi, plus documentation for users on how to bootstrap their dotfiles.

## Complexity Tracking

> No violations requiring justification. Implementation adds a single binary to the existing container image.
