# Implementation Plan: Secret Injection for Development Containers

**Branch**: `003-secret-injection` | **Date**: 2026-01-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-secret-injection/spec.md`

## Summary

Implement secure secret injection for development containers using age-encrypted dotfiles managed by Chezmoi. Secrets are encrypted at rest, decrypted at container startup, and exposed as environment variables. The system integrates with the existing dotfile management (002-dotfile-management) and requires no external services after initial setup.

## Technical Context

**Language/Version**: Bash (shell scripts), Go templates (Chezmoi)
**Primary Dependencies**: Chezmoi (dotfile manager), age (encryption), existing base container image
**Storage**: Encrypted files on host filesystem, decrypted to environment variables at runtime
**Testing**: Integration tests via container startup verification, manual validation
**Target Platform**: Docker containers on macOS/Linux hosts (arm64 + amd64)
**Project Type**: Single project (shell scripts + Chezmoi templates)
**Performance Goals**: Secrets available within 2 seconds of container startup
**Constraints**: No external network calls after setup, <10MB image size increase, offline-capable
**Scale/Scope**: Single developer secrets (10-50 key-value pairs typical)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First | ✅ PASS | Secrets injected at runtime, not baked into images |
| II. Multi-Language Standards | ✅ PASS | Bash scripts follow shell best practices |
| III. Test-First Development | ✅ PASS | Integration tests for secret loading |
| IV. Security-First Design | ✅ PASS | Secrets encrypted at rest, never in images/logs |
| V. Reproducibility & Portability | ✅ PASS | Works on arm64/amd64, pinned tool versions |
| VI. Observability & Debuggability | ✅ PASS | Clear error messages, structured logging |
| VII. Simplicity & Pragmatism | ✅ PASS | Uses existing Chezmoi/age, minimal new code |

**Gate Status**: PASSED - No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/003-secret-injection/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (CLI interface specs)
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
scripts/
├── secrets-common.sh    # Shared utilities (logging, validation, dependency checks)
├── secrets-setup.sh     # First-time setup wizard
├── secrets-load.sh      # Runtime decryption script (entrypoint)
└── secrets-edit.sh      # Helper for editing encrypted secrets

docs/
└── secrets-guide.md     # User documentation

templates/
├── chezmoi/
│   └── private_dot_secrets.env.age.tmpl  # Chezmoi encrypted template
└── devcontainer/
    └── devcontainer.json                 # Sample devcontainer with secrets integration
```

**Structure Decision**: Single project structure with shell scripts for orchestration and Chezmoi templates for secret storage. Scripts integrate with existing container entrypoint.

## Complexity Tracking

> No violations - section not required.
