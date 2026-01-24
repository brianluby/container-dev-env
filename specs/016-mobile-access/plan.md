# Implementation Plan: Mobile Push Notifications for AI Agent Events

**Branch**: `016-mobile-access` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-mobile-access/spec.md`

## Summary

Implement an outbound-only push notification system that alerts developers on mobile devices when AI agent events occur (task completion, failure, approval needed). Uses ntfy.sh as the primary delivery service with access token authentication, and optionally Slack webhooks as a secondary channel. Delivered as a Bash wrapper script (`notify.sh`) invoked by AI agents via shell hooks, with content sanitization, priority-based delivery, and quiet hours support.

## Technical Context

**Language/Version**: Bash 5.x (scripts), YAML (configuration)
**Primary Dependencies**: curl (HTTP client, in base image), jq (optional, for Slack JSON payloads), ntfy.sh API, Slack Webhooks API
**Storage**: File-based — notify.yaml for service config and priority mapping; environment variables for secrets (access tokens, webhook URLs)
**Testing**: bats-core (Bash Automated Testing System) for unit/integration tests
**Target Platform**: Linux container (Debian Bookworm-slim, per 001-container-base-image)
**Project Type**: Single project (CLI scripts + config templates)
**Performance Goals**: Notification delivered within 30 seconds of triggering event
**Constraints**: Outbound-only (no inbound ports), 200 char message limit, HTTPS required, no secrets in logs/config files
**Scale/Scope**: Single developer per container instance; ~10-50 notifications per day typical

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ✅ PASS | All code runs inside container; no host dependencies; curl already in base image |
| II. Multi-Language Standards | ✅ PASS | Bash not explicitly listed but cross-language requirements apply: shellcheck (lint), shfmt (format), bats-core (test) |
| III. Test-First Development | ✅ PASS | Tests via bats-core covering sanitization, priority mapping, quiet hours, retry logic |
| IV. Security-First Design | ✅ PASS | Secrets in env vars only; content sanitized before leaving container; HTTPS enforced; no secrets logged |
| V. Reproducibility & Portability | ✅ PASS | No new unpinned dependencies; bats-core version pinned; multi-arch compatible (pure Bash) |
| VI. Observability & Debuggability | ✅ PASS | Structured logging (FR-014); meaningful exit codes; errors to stderr |
| VII. Simplicity & Pragmatism | ✅ PASS | Single Bash script; minimal deps (curl required, jq optional); no over-engineering |

**Gate Result**: ALL PASS — proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/016-mobile-access/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (CLI interface spec)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/
├── notify.sh            # Main notification wrapper script
├── notify-sanitize.sh   # Content sanitization functions (sourced by notify.sh)
└── notify.yaml.template # Configuration template for service enablement

tests/
├── unit/
│   ├── test_notify_config.bats # Config parsing tests
│   ├── test_cli.bats         # CLI argument parsing tests
│   ├── test_ntfy.bats        # ntfy.sh delivery tests (mocked HTTP)
│   ├── test_sanitize.bats    # Content sanitization tests
│   ├── test_priority.bats    # Priority mapping tests
│   ├── test_slack.bats       # Slack delivery tests (mocked HTTP)
│   └── test_quiet_hours.bats # Quiet hours logic tests
├── integration/
│   ├── test_multi_service.bats # Multi-service dispatch tests
│   └── test_retry.bats        # Retry/backoff tests
└── helpers/
    └── test_helper.bash       # Common setup (mock curl, temp dirs, config helpers)
```

**Structure Decision**: Single project layout. The feature is a Bash CLI tool with supporting functions split into a sourced helper file for testability. No models/services/lib directories needed — Bash scripts are flat by nature.

## Complexity Tracking

> All NON-NEGOTIABLE constitution gates (I-V) pass. One advisory note for Principle VI below.

**Principle VI (Observability) — Advisory Deviation**:
- Principle VI recommends "Support both JSON and human-readable formats" for CLI output.
- notify.sh outputs human-readable timestamped logs to stderr only. JSON structured logging is not implemented.
- **Justification**: Principle VI is non-mandatory. notify.sh is a fire-and-forget hook script, not a long-running service. Human-readable stderr is sufficient for debugging. JSON output can be added in a future iteration if log aggregation is needed.
