# Documentation Navigation

This page is a human-maintained map of the documentation tree.
Use it when you do not know where to start, or when you want to quickly locate the right doc by task/role.

## Prerequisites

- None

## Quick reference

| If you need... | Read |
|---|---|
| New user onboarding | `docs/getting-started/index.md` |
| Troubleshoot setup issues | `docs/getting-started/troubleshooting.md` |
| Enable a feature | `docs/features/index.md` |
| Operational runbooks | `docs/operations/index.md` |
| Contributing workflow + tests | `docs/contributing/index.md` |
| System overview and diagrams | `docs/architecture/index.md` |
| Configuration reference | `docs/reference/configuration.md` |
| Domain terminology | `docs/glossary.md` |
| Architecture decisions | `docs/decisions/` |

## How to use this map

1. Identify the category relevant to your current task
2. Read the referenced document for context
3. For architecture decisions, check `decisions/` for relevant ADRs before proposing new approaches
4. Cross-references between documents use relative Markdown links

## Document conventions

- Each document is self-contained and under 500 lines
- Mermaid diagrams show system relationships (flowcharts and sequence diagrams)
- ADRs are numbered sequentially: `NNN-kebab-case-title.md`
- ADR statuses: Proposed → Accepted → Deprecated/Superseded
- Diagrams include prose descriptions for context
- All documents are plain Markdown — no special tooling required

## Decision record discovery

When implementing a feature, check if relevant decisions exist:

1. Scan `decisions/` filenames for keywords related to your task
2. Read any matching ADRs for context, especially the "Alternatives Considered" section
3. If your implementation conflicts with an accepted ADR, discuss with the team before proceeding
4. If no relevant ADR exists for a significant choice, consider creating one

## Docs tree (top level)

- Getting started: `docs/getting-started/index.md`
- Features: `docs/features/index.md`
- Operations: `docs/operations/index.md`
- Architecture: `docs/architecture/index.md`
- Contributing: `docs/contributing/index.md`
- Reference: `docs/reference/index.md`
- Glossary: `docs/glossary.md`
- Decisions (ADRs): `docs/decisions/`

## Related

- `README.md`
- `docs/_page-template.md`

## Next steps

- If you are new here: `docs/getting-started/index.md`
