# Implementation Plan: Agentic Assistant

**Branch**: `006-agentic-assistant` | **Date**: 2026-01-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/006-agentic-assistant/spec.md`

## Summary

Integrate autonomous AI coding agents into the container development environment by installing OpenCode (primary, MIT, CLI/TUI) and optionally Claude Code (secondary, proprietary) as CLI binaries within the container Dockerfile. A Bash wrapper script (`agent`) provides a unified interface for tool selection, approval modes, checkpoint management, action logging, and session persistence. Agent state persists to Docker volumes; API keys are injected via environment variables (PRD 003 pattern).

## Technical Context

**Language/Version**: Bash 5.x (wrapper scripts, entrypoint), Dockerfile (container layer)
**Primary Dependencies**: OpenCode (MIT, CLI/TUI binary, pinned version), Claude Code (proprietary, native binary, optional, pinned version)
**Version Pinning**: OpenCode pinned via `OPENCODE_VERSION` build arg (direct binary from GitHub releases); Claude Code pinned via `CLAUDE_CODE_VERSION` build arg. No `curl | bash` with unpinned versions.
**Storage**: Docker volumes for agent state (`~/.local/share/opencode/`, `~/.claude/`, `~/.local/share/agent/`); git stashes for checkpoints
**Testing**: Container integration tests (bash-based), shellcheck for scripts, BATS for CLI testing
**Target Platform**: Linux container (Debian Bookworm-slim), multi-arch (arm64 + amd64)
**Project Type**: Single project (container infrastructure layer)
**Performance Goals**: Container startup with agents < 30s; checkpoint operations < 5s; headless server response < 1s
**Constraints**: Image size < 2GB total (constitution); agent layer ~200-500MB; non-root execution; no GUI/X11
**Scale/Scope**: Single-user development container; 1 primary + 1 optional agent; sessions persist across restarts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ✅ PASS | Agents installed via Dockerfile; run headless in container; no host deps |
| II. Multi-Language Standards | ✅ PASS | Bash scripts use shellcheck; BATS for testing; formatters configured |
| III. Test-First Development | ✅ PASS | Integration tests for container startup, checkpoint ops, CLI interface |
| IV. Security-First Design | ✅ PASS | Non-root user; API keys from env vars; never logged; file exclusions |
| V. Reproducibility & Portability | ✅ PASS | Multi-arch via buildx; version pinning; HTTPS-verified installers |
| VI. Observability & Debuggability | ✅ PASS | Action log (JSONL); structured output; exit codes; health checks |
| VII. Simplicity & Pragmatism | ⚠️ JUSTIFIED | Dual-tool adds complexity; justified by M-10 (OSS primary) + M-3 (best checkpoints are proprietary) |

### Post-Phase 1 Re-check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First | ✅ | Data model uses volumes; no host filesystem access |
| II. Multi-Language | ✅ | Bash + Dockerfile; shellcheck + BATS |
| III. Test-First | ✅ | Contract tests for CLI, integration tests for container |
| IV. Security-First | ✅ | Exclusion patterns, non-root, credential filtering in logs |
| V. Reproducibility | ✅ | Deterministic installs from official HTTPS endpoints |
| VI. Observability | ✅ | JSONL action logs, session metadata, token usage tracking |
| VII. Simplicity | ⚠️ JUSTIFIED | See Complexity Tracking below |

## Project Structure

### Documentation (this feature)

```text
specs/006-agentic-assistant/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research output
├── data-model.md        # Phase 1 data model
├── quickstart.md        # Phase 1 quickstart guide
├── contracts/           # Phase 1 interface contracts
│   ├── cli-interface.md
│   ├── container-interface.md
│   └── config-schema.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
src/
├── agent/
│   ├── agent.sh                 # Main wrapper script
│   ├── lib/
│   │   ├── checkpoint.sh        # Git-based checkpoint operations
│   │   ├── config.sh            # Configuration loading and validation
│   │   ├── exclusions.sh        # .agentignore parsing and application
│   │   ├── log.sh               # Action log writing and reading
│   │   ├── provider.sh          # Provider availability checking
│   │   ├── session.sh           # Session metadata management
│   │   └── usage.sh             # Token usage aggregation
│   └── defaults/
│       └── agentignore          # Default exclusion patterns

docker/
├── Dockerfile.agent             # Agent layer (added to base image)
├── docker-compose.agent.yml     # Compose override for agent volumes/env
└── healthcheck.sh               # Container health check script

tests/
├── integration/
│   ├── test_container_startup.sh    # Agent starts headless, no X11
│   ├── test_api_key_validation.sh   # Missing/invalid key behavior
│   ├── test_checkpoint_ops.sh       # Create, list, rollback checkpoints
│   ├── test_session_persistence.sh  # Survive container restart
│   └── test_file_exclusions.sh      # .agentignore enforcement
├── unit/
│   ├── test_config.bats             # Config loading/merging
│   ├── test_exclusions.bats         # Pattern matching
│   ├── test_provider.bats           # Provider selection logic
│   └── test_session.bats            # Session metadata CRUD
└── contract/
    ├── test_cli_interface.bats      # CLI flags, exit codes, subcommands
    └── test_action_log_format.bats  # JSONL schema validation
```

**Structure Decision**: Single project with `src/agent/` for the wrapper script library, `docker/` for container configuration, and `tests/` organized by test type (unit/integration/contract) per constitution.

## Complexity Tracking

> **Violation justified: Dual-tool approach**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Two agent binaries (OpenCode + Claude Code) | M-10 requires OSS primary tool; best autonomous features (native checkpoints, sub-agents) are only in proprietary Claude Code (M-3, S-1) | Single OSS tool lacks mature checkpoints and sub-agent parallelism; single proprietary tool violates M-10 and S-4 (multi-provider) |
| Wrapper script abstraction | Unified CLI interface for two different tools; handles checkpoint/logging uniformly | Direct tool invocation requires users to learn two CLIs; no unified action log or checkpoint management |

## Phase 0 Outputs

- [research.md](research.md) — 10 research topics resolved: tool installation, state persistence, checkpoints, exclusions, wrapper design, headless modes, multi-arch, action logging

## Phase 1 Outputs

- [data-model.md](data-model.md) — 8 entities: Session, Checkpoint, Task, SubAgent, BackgroundTask, ActionLogEntry, TokenUsage, ExclusionPattern
- [contracts/cli-interface.md](contracts/cli-interface.md) — `agent` wrapper CLI contract: options, subcommands, exit codes, env vars
- [contracts/container-interface.md](contracts/container-interface.md) — Dockerfile args, volumes, ports, resource expectations, network ACLs
- [contracts/config-schema.md](contracts/config-schema.md) — Configuration JSON schema, .agentignore format, session/log schemas
- [quickstart.md](quickstart.md) — Build, run, first-use, common workflows, troubleshooting
