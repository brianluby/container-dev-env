---
description: "Documentation inventory + migration decisions for 018-docs-overhaul"
---

# Documentation Audit (018-docs-overhaul)

This audit captures:

- A point-in-time inventory of documentation sources (to find duplicates and drift).
- A keep/move/deprecate plan applied during the docs overhaul.
- A baseline troubleshooting scenario list used to measure SC-008.

This file is intentionally verbose; it is the working ledger for this docs migration.

## Inventory + Actions

Legend:

- `keep`: keep in place; ensure reachable from navigation or explicitly scoped as non-user-facing
- `move`: move to the new docs tree; old location becomes a pointer/deprecation stub when practical
- `merge`: content is merged into a new canonical page; old page becomes a pointer/deprecation stub
- `deprecate`: keep as a pointer-only legacy page (no new content)
- `archive`: keep for history but exclude from primary navigation (reviews/snapshots)

| Source | Type | Notes | Action | Canonical destination |
|---|---|---|---|---|
| `README.md` | entry point | currently partial + duplicated steps | move | `README.md` (rewrite as single entry point) |
| `docs/getting-started.md` | onboarding | legacy getting started | merge | `docs/getting-started/index.md` (plus pointer from legacy file) |
| `docs/pre-existing-failures.md` | troubleshooting | known test failures; not user onboarding | move | `docs/reference/known-issues.md` (or link from troubleshooting) |
| `docs/advanced-guide.md` | mixed | overlaps features/contributing/reference | merge | category indexes + feature guides; keep pointer at legacy path |
| `docs/secrets-guide.md` | feature guide | secrets workflow | merge | `docs/features/secrets-management.md` (pointer from legacy file) |
| `docs/quickstarts/README.md` | index | legacy index for quickstarts | deprecate | `docs/features/index.md` |
| `docs/quickstarts/008-containerized-ide.md` | quickstart | feature guide seed | move | `docs/features/containerized-ide.md` (stub legacy file) |
| `docs/quickstarts/009-ai-ide-extensions.md` | quickstart | feature guide seed | move | `docs/features/ide-extensions.md` (stub legacy file) |
| `docs/quickstarts/012-mcp-integration.md` | quickstart | feature guide seed | move | `docs/features/mcp.md` (stub legacy file) |
| `docs/quickstarts/013-persistent-memory.md` | quickstart | feature guide seed | move | `docs/features/persistent-memory.md` (stub legacy file) |
| `docs/quickstarts/015-voice-input.md` | quickstart | feature guide seed | move | `docs/features/voice-input.md` (stub legacy file) |
| `docs/quickstarts/016-mobile-access.md` | quickstart | feature guide seed | move | `docs/features/mobile-access.md` (stub legacy file) |
| `docs/operations/deployment.md` | operations | currently not template-aligned | move | `docs/operations/deployment.md` (refactor in place) |
| `docs/architecture/overview.md` | architecture | needs diagram + ADR links | keep | `docs/architecture/overview.md` (refactor in place) |
| `docs/decisions/*` | ADRs | stable; referenced by architecture docs | keep | `docs/decisions/` |
| `docs/domain/glossary.md` | glossary | legacy location | move | `docs/glossary.md` (pointer from legacy file) |
| `docs/security-guidance.md` | security reference | user-facing reference | move | `docs/reference/security-guidance.md` (pointer from legacy file) |
| `docs/security/authentication.md` | security reference | user-facing reference | move | `docs/reference/security/authentication.md` (pointer from legacy file) |
| `docs/tool-compatibility.md` | reference | agent/tool compatibility notes | move | `docs/reference/tool-compatibility.md` (pointer from legacy file) |
| `docs/spec-driven-development-pipeline.md` | contributing | core contributor workflow | move | `docs/contributing/spec-driven-development.md` (pointer from legacy file) |
| `docs/test-matrix.md` | contributing/testing | consolidate | merge | `docs/contributing/testing.md` (pointer from legacy file) |
| `docs/volume-architecture.md` | architecture/reference | belongs in ops/architecture | move | `docs/architecture/volume-architecture.md` (pointer from legacy file) |
| `docs/api/principles.md` | reference | repo conventions | move | `docs/reference/api-principles.md` (pointer from legacy file) |
| `docs/*review*.md` | snapshot | review artifacts; not user-facing | archive | keep in place; link only from backlog appendix |

## Baseline Troubleshooting Scenarios (SC-008)

This list is the baseline set of troubleshooting scenarios this docs overhaul aims to cover (target: >= 90% have documented resolution steps).

| ID | Scenario | Where documented (target) |
|---|---|---|
| TS-001 | Docker is not installed / not running | `docs/getting-started/troubleshooting.md` |
| TS-002 | Docker Compose v2 missing (`docker compose` not found) | `docs/getting-started/troubleshooting.md` |
| TS-003 | Build fails due to transient network / rate limiting | `docs/getting-started/troubleshooting.md` |
| TS-004 | `docker compose up` starts then exits immediately | `docs/getting-started/troubleshooting.md` |
| TS-005 | `docker compose exec` fails because container not healthy | `docs/getting-started/troubleshooting.md` |
| TS-006 | Permission issues between host and container (UID/GID mismatch) | `docs/getting-started/troubleshooting.md` |
| TS-007 | macOS file sharing / performance issues with bind mounts | `docs/getting-started/troubleshooting.md` |
| TS-008 | WSL2 path / mount issues on Windows | `docs/getting-started/troubleshooting.md` |
| TS-009 | Line endings (`CRLF`) break shell scripts | `docs/getting-started/troubleshooting.md` |
| TS-010 | Named volume disk usage too large | `docs/operations/volume-cleanup.md` |
| TS-011 | Secrets not loading in container | `docs/features/secrets-management.md` + `docs/operations/secret-rotation.md` |
| TS-012 | OpenCode/Claude Code not found / not configured | `docs/features/ai-assistants.md` |
| TS-013 | MCP config generation/validation fails | `docs/features/mcp.md` |
| TS-014 | Voice input not capturing audio | `docs/features/voice-input.md` |
| TS-015 | Mobile notifications not arriving | `docs/features/mobile-access.md` |
| TS-016 | Container rebuild doesn't pick up changes | `docs/operations/container-rebuild.md` |
