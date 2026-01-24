# Implementation Plan: Structured Project Knowledge for AI Agents

**Branch**: `014-project-knowledge` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/014-project-knowledge/spec.md`

## Summary

Create a structured documentation system (`docs/` directory) with standardized templates for Architecture Decision Records, a navigation guide for AI agents, domain glossary, and architecture overviews. The system uses static Markdown files with no runtime dependencies, referenced from AGENTS.md via a single pointer to a navigation guide that routes AI agents to relevant documentation categories.

## Technical Context

**Language/Version**: Bash 5.x (optional helper script for ADR creation)
**Primary Dependencies**: None (static Markdown files, no runtime dependencies)
**Storage**: File-based (`docs/` directory at project root, version-controlled)
**Testing**: BATS (for any helper scripts), manual verification (for documentation structure)
**Target Platform**: Any platform with a file system and AI coding tools
**Project Type**: Single project — documentation-only feature (static files)
**Performance Goals**: N/A (static files read at file-system speed)
**Constraints**: Individual docs under 500 lines (FR-014), Mermaid diagrams under 15 nodes, no secrets in docs (FR-008)
**Scale/Scope**: 6 documentation categories, ~10-15 files at maturity, works with 3+ AI tools

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First | **N/A** | Feature creates static files only; no container involvement |
| II. Multi-Language | **N/A** | No multi-language code; optional Bash script only |
| III. Test-First | **PASS** | Helper script (if created) requires BATS tests; static docs verified via checklist |
| IV. Security-First | **PASS** | FR-008 explicitly prohibits secrets in docs; aligns with constitution |
| V. Reproducibility | **PASS** | Static Markdown is inherently reproducible and portable |
| VI. Observability | **N/A** | No runtime component to observe |
| VII. Simplicity | **PASS** | Zero runtime dependencies; pure Markdown with optional helper script |

**Gate Result**: PASS — No violations. Feature is documentation-only with minimal tooling.

## Project Structure

### Documentation (this feature)

```text
specs/014-project-knowledge/
├── plan.md              # This file
├── research.md          # Phase 0 output (completed)
├── data-model.md        # Phase 1 output (completed)
├── quickstart.md        # Phase 1 output (completed)
├── contracts/           # Phase 1 output (completed)
│   ├── adr-template.md
│   ├── navigation-guide-template.md
│   ├── glossary-template.md
│   ├── architecture-overview-template.md
│   └── agents-md-integration.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
docs/
├── navigation.md              # AI navigation guide (entry point from AGENTS.md)
├── architecture/
│   ├── overview.md            # System structure & components
│   └── diagrams.md            # Mermaid architecture diagrams (optional)
├── decisions/
│   ├── _template.md           # ADR template for new decisions
│   └── NNN-kebab-title.md     # Sequential ADR files
├── api/
│   └── principles.md          # API design principles & endpoints
├── domain/
│   └── glossary.md            # Domain terminology & concepts
├── operations/
│   └── deployment.md          # Deployment procedures & runbooks
└── security/
    └── authentication.md      # Auth patterns & threat considerations

src/
└── scripts/
    └── new-adr.sh             # Optional: ADR creation helper script

tests/
└── unit/
    └── test_new_adr.bats      # BATS tests for helper script (if created)
```

**Structure Decision**: This feature produces a `docs/` directory at the project root containing static Markdown files organized by category. An optional helper script (`src/scripts/new-adr.sh`) automates ADR creation with sequential numbering. The AGENTS.md file gets a single additional section pointing to `docs/navigation.md`.

## Complexity Tracking

No constitution violations requiring justification.
