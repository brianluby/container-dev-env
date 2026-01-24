# Project Knowledge Navigation Guide

> This guide helps AI coding agents find relevant project documentation.
> Read the section matching your current task before generating code.

## Quick Reference

| If you need...                    | Read                                      |
|-----------------------------------|-------------------------------------------|
| Past architectural decisions      | `decisions/` directory (NNN-title.md)     |
| System structure & components     | `architecture/overview.md`                |
| API design principles             | `api/principles.md`                       |
| Domain terminology                | `domain/glossary.md`                      |
| Deployment & operations           | `operations/deployment.md`                |
| Security patterns                 | `security/authentication.md`              |

## How to Use This Guide

1. Identify the category relevant to your current task
2. Read the referenced document for context
3. For architecture decisions, check `decisions/` for relevant ADRs before proposing new approaches
4. Cross-references between documents use relative Markdown links

## Document Conventions

- Each document is self-contained and under 500 lines
- Mermaid diagrams show system relationships (flowcharts and sequence diagrams)
- ADRs are numbered sequentially: `NNN-kebab-case-title.md`
- ADR statuses: Proposed → Accepted → Deprecated/Superseded
- Diagrams include prose descriptions for context
- All documents are plain Markdown — no special tooling required

## Decision Record Discovery

When implementing a feature, check if relevant decisions exist:

1. Scan `decisions/` filenames for keywords related to your task
2. Read any matching ADRs for context, especially the "Alternatives Considered" section
3. If your implementation conflicts with an accepted ADR, discuss with the team before proceeding
4. If no relevant ADR exists for a significant choice, consider creating one

## Category Descriptions

### Architecture (`architecture/`)
System structure, component relationships, and design patterns. Read before proposing structural changes or adding new components.

### Decisions (`decisions/`)
Architecture Decision Records (ADRs) documenting past choices with context, alternatives, and consequences. Read before re-proposing previously rejected approaches.

### API (`api/`)
Interface design principles, endpoint conventions, and error response formats. Read before creating or modifying API endpoints.

### Domain (`domain/`)
Project-specific terminology and business concepts. Read to use correct terminology in generated code and documentation.

### Operations (`operations/`)
Deployment procedures, container build workflows, and operational runbooks. Read before modifying build or deployment processes.

### Security (`security/`)
Authentication patterns, secret handling practices, and threat considerations. Read before implementing security-sensitive features.
