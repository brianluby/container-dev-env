# Technical Specification Document: 010-project-context-files

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/010-project-context-files/` and `prds/010-prd-project-context-files.md`

## 1. Executive Summary

This document defines the standard for `AGENTS.md`, serving as the "Router" for AI context. It establishes the file structure and the logic for how agents should parse and prioritize this information.

## 2. Technical Specifications

### 2.1 File Standards
*   **Filename**: `AGENTS.md` (root level).
*   **Format**: Markdown (CommonMark).
*   **Max Size**: Recommended < 10KB (to fit in context windows).

### 2.2 Context Hierarchy logic
Agents should read context in this order of precedence:
1.  User Prompt
2.  `activeContext.md` (Memory Bank - PRD 012)
3.  `AGENTS.md` (Static Router - PRD 010)
4.  `docs/*.md` (Detailed Knowledge - PRD 013)

## 3. Data Models

### 3.1 AGENTS.md Schema (Conceptual)
Although Markdown, the content implies a schema:
*   `# Project Identity`: Name, Goal.
*   `# Tech Stack`: Languages, Frameworks.
*   `# Architectural Constraints`: "Do not use X", "Always use Y".
*   `# Documentation Index`: Links to `docs/`.

## 4. API Contracts & Interfaces

### 4.1 Linter Rules (`.markdownlint.json`)
Custom rules to enforce `AGENTS.md` structure:
*   **MD001**: Header levels increment by one.
*   **Custom**: Must contain "Tech Stack" section.

## 5. Architectural Improvements

### 5.1 Context Injection Hook
**Problem**: Agents don't read `AGENTS.md` by default unless asked.
**Solution**: Create a `prompt-wrapper.sh` for CLI agents (PRD 005) that prepends `AGENTS.md` content to the session start.
```bash
SYSTEM_PROMPT="$(cat AGENTS.md) $(cat system_prompt.txt)"
```

## 6. Testing Strategy
*   **Validation**: Run `markdownlint AGENTS.md` in CI.
*   **Parsing**: Verify a simple regex script can extract the "Tech Stack" list.
