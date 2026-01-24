# Implementation Plan: Persistent Memory for AI Agent Context

**Branch**: `013-persistent-memory` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-persistent-memory/spec.md`

## Summary

Implement a hybrid persistent memory system for AI coding agents that combines human-maintained strategic context files (`.memory/*.md`) with automatically captured tactical memory (SQLite + sqlite-vec via MCP server). Strategic memory provides stable project knowledge through version-controlled markdown files. Tactical memory uses a Python MCP server with FastEmbed for offline semantic search, persisted on Docker volumes across container restarts.

## Technical Context

**Language/Version**: Python 3.11+ minimum; uses Python from base image (3.14+ per 001-container-base-image)
**Primary Dependencies**: FastEmbed (embeddings), sqlite-vec (vector search), mcp SDK 1.x (server framework), pydantic (models)
**Storage**: SQLite with sqlite-vec extension (tactical), Markdown files (strategic)
**Testing**: pytest with integration tests against SQLite and MCP protocol
**Target Platform**: Linux container (Debian Bookworm-slim, arm64 + amd64)
**Project Type**: Single project (MCP server + CLI tool)
**Performance Goals**: <50ms semantic query latency (p95), <2s container startup overhead
**Constraints**: 500MB tactical storage cap, offline-capable, no internet required, <2GB image size contribution
**Scale/Scope**: Single developer per container, 1 project per workspace, ~50 entries/day typical

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First | PASS | All components run inside container. SQLite + FastEmbed bundled. No host deps. ~100MB image contribution (under 2GB budget). |
| II. Multi-Language Standards | PASS | Python 3.11+ with ruff (lint/format), pytest (test), type hints mandatory. |
| III. Test-First Development | PASS | TDD for MCP server, storage layer, retention logic, CLI. |
| IV. Security-First | PASS | Secrets excluded via templates + .memoryrc patterns. No encryption needed (local-only). Non-root container user. |
| V. Reproducibility & Portability | PASS | Version-pinned deps. FastEmbed + sqlite-vec have pre-built arm64/amd64 wheels. Deterministic builds. |
| VI. Observability & Debuggability | PASS | Structured JSON logging to stderr. Health check endpoint. Memory stats tool. |
| VII. Simplicity & Pragmatism | PASS | Single SQLite file, standard markdown, no microservices. Minimal deps (FastEmbed avoids PyTorch bloat). |

**Re-check after Phase 1**: All gates still PASS. No violations introduced by design artifacts.

## Project Structure

### Documentation (this feature)

```text
specs/013-persistent-memory/
├── plan.md              # This file
├── research.md          # Phase 0: technology decisions
├── data-model.md        # Phase 1: entity schemas
├── quickstart.md        # Phase 1: developer setup guide
├── contracts/           # Phase 1: API contracts
│   ├── mcp-tools.json           # MCP tool definitions
│   ├── mcp-server-config.json   # AI tool configuration
│   └── strategic-memory-init.sh # CLI contract
└── tasks.md             # Phase 2: implementation tasks
```

### Source Code (repository root)

```text
src/
├── memory_server/
│   ├── __init__.py
│   ├── __main__.py          # Entry point: mcp.run(transport="stdio")
│   ├── server.py            # FastMCP instance + tool handlers
│   ├── strategic.py         # Strategic memory file loader (.memory/*.md)
│   ├── storage.py           # SQLite + sqlite-vec operations
│   ├── embeddings.py        # FastEmbed wrapper
│   ├── models.py            # Pydantic models (MemoryEntry, ProjectConfig)
│   ├── retention.py         # Pruning logic (time + size thresholds)
│   ├── session.py           # Session ID generation, source tool detection
│   ├── project.py           # Project ID hashing, workspace detection
│   └── config.py            # .memoryrc parsing, env var loading
├── memory_init/
│   ├── __init__.py
│   ├── __main__.py          # CLI entry point
│   ├── templates/           # Strategic memory file templates
│   │   ├── goals.md
│   │   ├── architecture.md
│   │   ├── patterns.md
│   │   ├── technology.md
│   │   └── status.md
│   ├── configs/             # AI tool MCP configuration templates
│   │   ├── claude.json
│   │   ├── cline.json
│   │   └── continue.yaml
│   └── init.py              # Initialization logic
└── docker/
    ├── memory.Dockerfile        # Container layer for memory system
    └── memory-entrypoint.sh     # Container entrypoint (detect .memory/, start MCP server)

tests/
├── unit/
│   ├── test_storage.py      # SQLite operations
│   ├── test_embeddings.py   # FastEmbed integration
│   ├── test_retention.py    # Pruning logic
│   ├── test_project.py      # Project ID hashing
│   └── test_config.py       # Config parsing
├── integration/
│   ├── test_mcp_server.py   # MCP protocol end-to-end
│   ├── test_persistence.py  # Container restart scenarios
│   └── test_multi_tool.py   # Concurrent access from multiple AI tools
└── contract/
    └── test_mcp_tools.py    # Tool schema validation against contracts
```

**Structure Decision**: Single project layout. The memory system is a self-contained Python package (`memory_server`) with a companion CLI (`memory_init`). Both are installed in the container image. No frontend/backend split needed — this is a pure backend service exposed via MCP stdio transport.

## Complexity Tracking

> No constitution violations. No complexity justifications needed.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |
