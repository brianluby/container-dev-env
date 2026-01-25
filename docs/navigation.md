# Documentation Navigation

This page is a human-maintained map of the documentation tree.
Use it when you do not know where to start, or when you want to quickly locate the right doc by task/role.

## Prerequisites

- None

## Quick reference

| If you need... | Read |
|---|---|
| New user onboarding | [Getting Started](getting-started/index.md) |
| Troubleshoot setup issues | [Troubleshooting](getting-started/troubleshooting.md) |
| Enable a feature | [Features](features/index.md) |
| Operational runbooks | [Operations](operations/index.md) |
| Contributing workflow + tests | [Contributing](contributing/index.md) |
| System overview and diagrams | [Architecture](architecture/index.md) |
| Configuration reference | [Configuration](reference/configuration.md) |
| Domain terminology | [Glossary](glossary.md) |
| Architecture decisions | [Decisions](decisions/) |

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

- [Getting Started](getting-started/index.md)
- [Features](features/index.md)
- [Operations](operations/index.md)
- [Architecture](architecture/index.md)
- [Contributing](contributing/index.md)
- [Reference](reference/index.md)
- [Glossary](glossary.md)
- [Decisions (ADRs)](decisions/)

## Related

- [README](../README.md)
- [Page Template](_page-template.md)

## Next steps

- If you are new here: [Getting Started](getting-started/index.md)
