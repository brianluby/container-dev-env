# Implementation Plan: Documentation Overhaul

**Branch**: `018-docs-overhaul` | **Date**: 2026-01-24 | **Spec**: `specs/018-docs-overhaul/spec.md`
**Input**: `/Users/bluby/personal-repos/container-dev-env_specs/018-docs-overhaul/specs/018-docs-overhaul/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command.

## Summary

Overhaul the repository documentation into a coherent `docs/` hierarchy with `README.md` as the single entry point. Deliver self-contained guides for onboarding, feature adoption, contributing, and operations; add a consistent page template (prereqs/related/next), an explicit versioning policy (docs describe `main` with per-page applicability notes), and a maintenance rule (user-facing changes update docs in the same PR).

## Technical Context

**Language/Version**: Markdown (repository docs), Bash 5.x for any helper scripts  
**Primary Dependencies**: N/A (static Markdown); Mermaid/ASCII for diagrams (no site generator)  
**Storage**: Git repository files (Markdown)  
**Testing**: BATS (if helper scripts are added), ShellCheck for shell scripts; docs QA via link checks/linting as planned in `specs/018-docs-overhaul/research.md`  
**Target Platform**: GitHub README rendering + local repo browsing  
**Project Type**: Documentation restructure (no new runtime service)  
**Performance Goals**: New user setup success using docs alone in <30 minutes; docs entry comprehension in <5 minutes (per `specs/018-docs-overhaul/spec.md`)  
**Constraints**: Docs are Markdown committed in repo; no static site generation/hosting; full-text search out of scope (rely on GitHub/IDE search); avoid new heavy tooling/deps  
**Scale/Scope**: Consolidate current `docs/` content + align with existing feature specs (`specs/`) across ~dozens of pages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes / How This Plan Complies |
|---|---|---|
| I. Container-First Architecture | PASS | Docs live in-repo; any validation scripts/tests run in the containerized dev env and avoid host-only assumptions. |
| II. Multi-Language Standards | PASS | If any new scripts are added, they follow repo standards (Bash 5.x, ShellCheck clean, tests as applicable). |
| III. Test-First Development | PASS | Any new helper tooling (e.g., link checker scripts) is added via TDD (BATS) before implementation changes. |
| IV. Security-First Design | PASS | Docs explicitly avoid secrets; examples use templates (`.env.example`) and never include real credentials. |
| V. Reproducibility & Portability | PASS | No new floating-version tooling is introduced; docs validation should run deterministically in CI/container. |
| VI. Observability & Debuggability | PASS | N/A for docs-only change; any scripts follow clear CLI output + exit codes. |
| VII. Simplicity & Pragmatism | PASS | Prefer Markdown conventions and minimal scripting over new frameworks/toolchains. |

## Project Structure

### Documentation (this feature)

```text
specs/018-docs-overhaul/
├── doc-audit.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Source Code (repository root)

```text
README.md                 # Single docs entry point (links into docs/)

docs/
├── getting-started/
├── features/
├── operations/
├── architecture/
├── contributing/
├── reference/
├── glossary.md
└── navigation.md          # Human-friendly map of the docs tree

tests/
└── ...                    # Only if adding helper scripts that need tests
```

**Structure Decision**: Keep `README.md` as the single entry point; consolidate primary docs under `docs/` with index pages and cross-links for navigation-first discoverability.

## Complexity Tracking

No constitution violations anticipated; no complexity exceptions required.

## Phase 0: Outline & Research

**Output**: `/Users/bluby/personal-repos/container-dev-env_specs/018-docs-overhaul/specs/018-docs-overhaul/research.md`

Research/decision topics (resolve in `research.md`):

- Docs information architecture: index/TOC patterns that support the 3-click rule and role-based navigation.
- Page contract: consistent, minimal sections (prerequisites / related / next steps) vs frontmatter metadata.
- Docs QA gates: broken-link checking strategy, optional markdown linting/spellchecking, and CI integration without heavy deps.

## Phase 1: Design & Contracts

**Prerequisite**: `specs/018-docs-overhaul/research.md` completed with decisions.

Outputs:

- `specs/018-docs-overhaul/data-model.md`: documentation domain model (page/category/navigation relationships + required metadata/sections).
- `specs/018-docs-overhaul/contracts/`: documentation "contracts" (page template + navigation expectations + config reference structure). This feature has no HTTP API; contracts are content/interface contracts.
- `specs/018-docs-overhaul/quickstart.md`: how to validate the docs overhaul against the user stories (manual walkthrough + any planned automated checks).

Agent context update:

- Run `/Users/bluby/personal-repos/container-dev-env_specs/018-docs-overhaul/.specify/scripts/bash/update-agent-context.sh opencode` after Phase 1 artifacts exist.

## Phase 2: Task Planning

`/speckit.tasks` generates `specs/018-docs-overhaul/tasks.md` from this plan + the spec, with phased tasks and parallel markers.
