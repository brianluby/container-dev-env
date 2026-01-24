# Research: Persistent Memory for AI Agent Context

**Branch**: `013-persistent-memory` | **Date**: 2026-01-23

## Decision 1: Tactical Memory Storage Backend

**Decision**: SQLite with sqlite-vec extension

**Rationale**: Provides embedded vector similarity search alongside structured relational storage in a single file. WAL mode handles concurrent writes from multiple AI tools safely. No external service or network required. Pre-built Python wheels available for both arm64 and amd64 on Debian Bookworm.

**Alternatives Considered**:
- Flat files (JSON/JSONL): No built-in vector search; would require separate index
- ChromaDB: Heavier dependency, Python-specific, adds unnecessary abstraction layer
- LanceDB: Rust-based, fewer Python ecosystem integrations, newer/less proven

**Key Technical Details**:
- Install: `pip install sqlite-vec` (pre-built manylinux wheels)
- Integration: Standard `sqlite3` module + `sqlite_vec.load(db)` extension loading
- Vector table: `CREATE VIRTUAL TABLE ... USING vec0(embedding float[384])`
- Query: `SELECT ... WHERE embedding MATCH ? LIMIT k` (KNN search)
- Distance metrics: L2 (Euclidean), Cosine (float32/int8)
- SQLite version requirement: 3.41+ (available in Bookworm)
- Status: v0.1.7-alpha (pre-v1, expect minor API changes)

---

## Decision 2: Embedding Model & Runtime

**Decision**: FastEmbed (Qdrant) with BAAI/bge-small-en-v1.5 (pinned model)

**Rationale**: FastEmbed provides the smallest footprint (60-100MB total including model), fastest inference (5-15ms per query), and pre-quantized models without PyTorch dependency. Uses ONNX Runtime internally. Pre-built wheels for arm64 and amd64.

**Alternatives Considered**:
- sentence-transformers + PyTorch: 350-800MB installed size, PyTorch bloat unacceptable for <2GB image constraint
- ONNX Runtime directly: 100-150MB, more flexible but requires manual model management
- txtai: 400-900MB, overkill (includes full database layer)

**Size Impact on Container Image**:
```
FastEmbed package:          ~30 MB
Pre-quantized model:        ~50 MB
ONNX Runtime (bundled):     ~20 MB
Total embedding layer:     ~100 MB
```

**Performance**:
- Embedding generation: 5-15ms per query (well under 50ms target)
- Model output: 384-dimensional float32 vectors
- Batch embedding supported for bulk capture operations

---

## Decision 3: MCP Server Architecture

**Decision**: Python FastMCP with stdio transport, single-process server

**Rationale**: The official MCP Python SDK provides `FastMCP` class with automatic JSON Schema generation from type hints. Stdio transport is the standard for local tool integration (Claude Code, Cline, Continue all support it). Single-process design keeps startup fast and avoids orchestration complexity.

**Alternatives Considered**:
- HTTP/SSE transport: Adds network layer complexity for no benefit in single-container setup
- Node.js MCP SDK: Would require additional runtime; Python already needed for embeddings
- Go MCP implementation: Fewer SDK options, would split codebase language

**Key Architecture Patterns**:
- Tools defined via `@mcp.tool()` decorator with Python type hints
- Stdout reserved exclusively for JSON-RPC (all logging to stderr)
- Server started by AI tool client (spawns process, connects stdin/stdout)
- Configuration via standard `mcpServers` JSON block in tool configs
- MCP SDK version: `mcp>=1.0.0,<2.0.0` (production-stable)

**Tool Definitions Needed**:
1. `store_memory` - Capture session context with embedding
2. `search_memories` - Semantic search across tactical memory
3. `list_memories` - Browse recent entries
4. `delete_memory` - Remove specific entry
5. `get_memory_stats` - Storage usage and entry count

---

## Decision 4: Strategic Memory File Format

**Decision**: Markdown files organized by category in `.memory/` directory

**Rationale**: Markdown is human-readable, version-controllable, and universally parseable by all AI tools (Claude Code reads CLAUDE.md, Cline reads .clinerules, Continue reads context files). A dedicated `.memory/` directory scopes strategic context without conflicting with existing AI tool conventions (AGENTS.md, CLAUDE.md are static instructions; `.memory/` is dynamic project state).

**Category Structure**:
```
.memory/
├── goals.md           # Project objectives and success criteria
├── architecture.md    # System design decisions and patterns
├── patterns.md        # Coding conventions and style preferences
├── technology.md      # Stack choices, versions, dependencies
├── status.md          # Current work state and recent progress
└── .memoryrc          # Configuration (retention, exclusions)
```

**Relationship to Feature 010 (Project Context Files)**:
- AGENTS.md / CLAUDE.md: Static AI behavioral instructions (from 010)
- `.memory/`: Dynamic project knowledge that evolves with the project (this feature)
- No overlap; complementary roles

---

## Decision 5: Project Isolation Mechanism

**Decision**: Hash-based project scoping using workspace path

**Rationale**: Each project workspace gets its own SQLite database file, named by a deterministic hash of the canonical workspace path. This prevents cross-project contamination while allowing multiple projects to share the same Docker volume for tactical memory storage.

**Implementation**:
```
~/.local/share/ai-memory/
├── projects/
│   ├── <hash-of-workspace-path-A>/memory.db
│   └── <hash-of-workspace-path-B>/memory.db
└── config.yaml  # Global defaults
```

**Hash Function**: SHA-256 truncated to 16 hex chars (collision-resistant, filesystem-safe)

---

## Decision 6: Retention & Pruning Strategy

**Decision**: Dual-threshold pruning (time + size), oldest-first eviction

**Rationale**: Time-based retention (30 days default) handles normal aging. Size cap (500MB) prevents unbounded growth during intensive usage periods. Oldest entries pruned first as they're least likely to be relevant. Pruning runs as part of MCP server startup and periodically during operation.

**Implementation**:
- Pruning check on server startup (within 2s budget)
- Background pruning every 6 hours during active sessions
- Entries sorted by timestamp; oldest removed until both thresholds satisfied
- Pruning is logged (structured JSON to stderr) for observability

---

## Unresolved (Deferred to Implementation)

- MCP server health check mechanism: Standard approach (TCP port or file-based) TBD in implementation
- Strategic memory size warning threshold: Suggested 500KB warning, 1MB hard limit from spec
