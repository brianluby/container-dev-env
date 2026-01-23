# Implementation Plan: Terminal AI Agent

**Branch**: `005-terminal-ai-agent` | **Date**: 2026-01-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-terminal-ai-agent/spec.md`

## Summary

Install OpenCode as a SHA256-verified Go binary in the container image, with Chezmoi-managed default configuration and environment variable-based API key injection from 003-secret-injection. The implementation adds a single binary (~30MB) to the Dockerfile, a config template to the dotfile management system, and integration tests validating startup, connectivity, and git operations.

## Technical Context

**Language/Version**: Bash (Dockerfile, scripts), Go templates (Chezmoi configs)
**Primary Dependencies**: OpenCode (pre-built Go binary, MIT license)
**Storage**: File-based (`~/.local/share/opencode/sessions/` for history, `~/.config/opencode/config.yaml` for settings)
**Testing**: Shell-based integration tests (container build verification, smoke tests)
**Target Platform**: Linux (Debian Bookworm-slim), amd64 + arm64
**Project Type**: Single (container configuration + integration tests)
**Performance Goals**: Agent ready to accept input within 3 seconds of invocation
**Constraints**: <50MB image size increase, zero runtime dependencies, API keys from env vars only
**Scale/Scope**: Single-user development tool within containerized environment

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ✅ PASS | Binary installed in Dockerfile; SHA256 pinned; multi-arch; declarative |
| II. Multi-Language Standards | ✅ PASS | Agent supports Py/TS/Rust/Go; Dockerfile/Bash follows formatting standards |
| III. Test-First Development | ✅ PASS | Integration tests for build verification, startup, git ops |
| IV. Security-First Design | ✅ PASS | No secrets in image; env vars only; SHA256 supply chain verification |
| V. Reproducibility & Portability | ✅ PASS | Pinned version + checksum; amd64 + arm64; deterministic build |
| VI. Observability & Debuggability | ✅ PASS | CLI tool with stderr logging; exit codes; JSON output mode available |
| VII. Simplicity & Pragmatism | ✅ PASS | Single binary; MIT license; minimal config; no extra runtimes |

**Gate Result: PASS** — No violations. Proceeding to Phase 0.

**Post-Phase 1 Re-check**: All gates still PASS after design phase. No new violations introduced by data model, contracts, or file layout decisions.

**Note on image size**: Constitution states <2GB for full-stack image; PRD resolved Q3 at 3GB total. The agent adds ~30MB, well within either limit. No conflict in practice.

## Project Structure

### Documentation (this feature)

```text
specs/005-terminal-ai-agent/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── cli-interface.md
│   └── env-vars.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
src/
├── docker/
│   └── Dockerfile           # OpenCode binary installation stage
├── chezmoi/
│   └── dot_config/
│       └── opencode/
│           └── config.yaml.tmpl  # Chezmoi template for default config
└── scripts/
    └── opencode-verify.sh   # SHA256 verification helper

tests/
├── integration/
│   ├── test_opencode_install.sh   # Binary present, executable, correct arch
│   ├── test_opencode_startup.sh   # Starts within 3s, reads env vars
│   ├── test_opencode_git.sh       # Auto-commit with conventional format
│   └── test_opencode_conflict.sh  # File conflict detection
└── contract/
    └── test_env_vars.sh           # API key env var contract
```

**Structure Decision**: Single project layout. The feature adds Dockerfile instructions, a Chezmoi config template, and shell-based integration tests. No application code is written — OpenCode is a pre-built binary.

## Complexity Tracking

No constitution violations to justify. Implementation is minimal: one Dockerfile stage, one config template, one verification script, and integration tests.
