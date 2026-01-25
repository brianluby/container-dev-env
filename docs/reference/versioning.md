# Documentation Versioning Policy

This repository's documentation describes the behavior of the current `main` branch.

## Prerequisites

- None

## Policy

- Canonical docs target: `main`
- Changes to user-facing behavior or configuration must update docs in the same PR
- When behavior differs across versions, pages add an explicit note:
  - Applies to: `main` (or a tag/branch)
  - Tested with: a commit SHA or image tag (when relevant)

## Why this approach

Static Markdown docs are easiest to maintain when there is one source of truth.
Per-release snapshots are out of scope for this repository.

## Related

- `docs/contributing/workflow.md`

## Next steps

- `docs/reference/search.md`
