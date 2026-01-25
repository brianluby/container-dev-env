# Project Structure

This page describes the high-level repository layout so contributors can quickly find the right place to change.

Applies to: `main`

## Prerequisites

- `docs/contributing/index.md`

## Top-level layout

- `docker/`: Dockerfiles, Compose files, container entrypoints
- `scripts/`: host-facing helper scripts
- `src/`: implementation source (agent wrapper, templates, MCP tooling, etc.)
- `templates/`: Chezmoi templates and config templates
- `specs/`: per-feature specs, plans, tasks, and research
- `tests/`: BATS tests and integration/contract checks
- `docs/`: documentation tree (this overhaul)

## Related

- `docs/contributing/testing.md`
- `docs/architecture/overview.md`

## Next steps

- Start a change with the workflow: `docs/contributing/workflow.md`
