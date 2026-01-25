# Phase 0 Research: Documentation Overhaul

This file records high-impact documentation design decisions for `018-docs-overhaul`.

## Decision: Documentation entry point

- Decision: Use `README.md` as the single documentation entry point.
- Rationale: Standard GitHub convention; reduces user confusion and supports the onboarding success criteria.
- Alternatives considered:
  - `docs/README.md` as the entry point (rejected: hides docs behind an extra click).
  - `docs/index.md` as the entry point (rejected: not the natural GitHub landing page).

## Decision: Primary documentation tree location

- Decision: Keep primary documentation under `docs/`.
- Rationale: Existing repo convention; keeps root uncluttered while enabling a clear hierarchy.
- Alternatives considered:
  - Multiple root-level docs (rejected: hard to navigate and maintain).

## Decision: Information architecture

- Decision: Organize docs by user intent with a small set of top-level categories:
  - `docs/getting-started/` (onboarding)
  - `docs/features/` (feature guides)
  - `docs/operations/` (runbooks)
  - `docs/contributing/` (contributor onboarding)
  - `docs/architecture/` (system overview + ADR links)
  - `docs/reference/` (configuration reference, command reference)
  - `docs/glossary.md` (canonical terms)
  - `docs/navigation.md` (human-maintained map of the tree)
- Rationale: Matches the spec audiences (new user, existing user, contributor, operator) and supports navigation-first discovery.
- Alternatives considered:
  - Organize by repository folders (rejected: reflects implementation, not user intent).

## Decision: Page structure contract

- Decision: Standardize each page to include:
  - Prerequisites
  - Related
  - Next steps
  - Optional: Applies to / Tested with (when behavior differs)
- Rationale: Directly satisfies FR-011 and reduces "where do I go next" ambiguity.
- Alternatives considered:
  - YAML frontmatter metadata (rejected: no site generator; adds cognitive/tooling overhead).

## Decision: Docs versioning strategy

- Decision: Documentation describes the current `main` branch behavior; pages add explicit applicability notes when behavior differs across releases.
- Rationale: Minimizes maintenance overhead while preventing users from following stale steps.
- Alternatives considered:
  - Per-release snapshots under `docs/vX.Y/` (rejected: high upkeep).
  - Only document latest tagged release (rejected: discourages contribution/testing on `main`).

## Decision: Keeping docs synchronized with code

- Decision: User-facing behavior or configuration changes must update docs in the same PR (review/DoD gate).
- Rationale: Avoids drift without introducing automation/hosting.
- Alternatives considered:
  - Scheduled docs sweeps (rejected: drift persists between sweeps).

## Decision: Docs QA gates (link integrity)

- Decision: Add a lightweight repository-local link integrity check (relative Markdown links at minimum). If implemented as a script, it must be:
  - Container-friendly
  - Dependency-light
  - Tested with BATS (TDD)
  - ShellCheck clean
- Rationale: Supports SC-005 (no orphaned/unreachable pages) and reduces broken-link regressions.
- Alternatives considered:
  - `markdown-link-check` (Node) (rejected for now: adds external dependency and potential network/pinning concerns).
  - Full docs site generation (rejected: explicitly out of scope).
