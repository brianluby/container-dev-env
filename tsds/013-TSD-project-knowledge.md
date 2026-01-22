# Technical Specification Document: 013-project-knowledge

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/013-project-knowledge/` and `prds/013-prd-project-knowledge.md`

## 1. Executive Summary

This document specifies the structure for static project knowledge (`docs/`). It formalizes Architecture Decision Records (ADRs) and diagrams as the primary source of truth for "Static" context, referenced by `AGENTS.md`.

## 2. Technical Specifications

### 2.1 Directory Structure
*   `docs/architecture/decisions/`: ADRs (001-xxxx.md).
*   `docs/diagrams/`: Mermaid charts.
*   `docs/api/`: OpenAPI specs or Markdown docs.

### 2.2 Tools
*   **Diagramming**: Mermaid.js (native support in GitHub & VS Code).
*   **Linting**: `markdownlint` configured to check links between docs.

## 3. Data Models

### 3.1 ADR Template
```markdown
# [ID] [Title]
## Status: [Proposed|Accepted|Deprecated]
## Context
...
## Decision
...
## Consequences
...
```

## 4. API Contracts & Interfaces

### 4.1 Indexing
*   **Contract**: The `AGENTS.md` file MUST contain relative links to key documents in `docs/` so agents can crawl them.

## 5. Architectural Improvements

### 5.1 Automated Diagram Generation
**Optimization**: Use a tool like `mmd-cli` to generate PNGs from Mermaid files during CI, ensuring non-technical stakeholders can view them without a renderer.

## 6. Testing Strategy
*   **Link Check**: Run a broken link checker (e.g., `lychee`) on `docs/` to ensure no orphaned documents.
*   **Format Check**: Verify ADRs follow the template structure.
