# Technical Specification Document: 012-persistent-memory

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/012-persistent-memory/` and `prds/012-prd-persistent-memory.md`

## 1. Executive Summary

This document specifies the **Hybrid Memory Architecture**: combining explicit "Memory Bank" markdown files (Strategic) with an MCP-based Vector Database (Tactical). This ensures both human-readability and high-speed semantic retrieval.

## 2. Technical Specifications

### 2.1 Storage Components
*   **Strategic (Git-Tracked)**: `.memory-bank/*.md`.
*   **Tactical (Git-Ignored)**: `.mcp-memory/memory.db` (SQLite + Vector).

### 2.2 Integration
*   **Strategic**: Accessed via Filesystem MCP or direct file read by Agent.
*   **Tactical**: Accessed via `mcp-memory-service`.

## 3. Data Models

### 3.1 Memory Bank Schema
*   `activeContext.md`: Current task, recent changes.
*   `systemPatterns.md`: Established architecture patterns.
*   `progress.md`: Completed items, known issues.

### 3.2 Vector Schema (Conceptual)
*   **Entry**: `{ content: string, embedding: float[], timestamp: int, type: "observation|fact" }`

## 4. API Contracts & Interfaces

### 4.1 Context Injection
*   **Trigger**: Agent startup.
*   **Action**:
    1.  Read `activeContext.md`.
    2.  Query Vector DB for "current task" keywords.
    3.  Inject combined context into System Prompt.

## 5. Architectural Improvements

### 5.1 Sync Mechanism
**Problem**: `.memory-bank` can get stale.
**Solution**: Define an "Update Protocol" in the System Prompt.
*   "Before finishing a task, you MUST update `activeContext.md` and `progress.md`."

## 6. Testing Strategy
*   **Persistence**: Create a memory entry, restart container, verify retrieval.
*   **Search**: Query Vector DB with a synonym (semantic search) and verify correct hit.
