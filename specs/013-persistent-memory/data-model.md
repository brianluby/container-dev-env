# Data Model: Persistent Memory for AI Agent Context

**Branch**: `013-persistent-memory` | **Date**: 2026-01-23

## Entities

### MemoryEntry (Tactical Memory)

The core unit of automatically captured session context.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | TEXT (UUID) | PRIMARY KEY | Unique entry identifier |
| project_id | TEXT | NOT NULL, INDEX | Hash of workspace path (16 hex chars) |
| content | TEXT | NOT NULL | Captured context text |
| embedding | FLOAT[384] | NOT NULL | Vector embedding for semantic search |
| source_tool | TEXT | NOT NULL | AI tool that captured this (claude-code, cline, continue) |
| session_id | TEXT | NOT NULL | Session identifier for grouping |
| entry_type | TEXT | NOT NULL | Category: decision, pattern, observation, error |
| tags | TEXT | NULLABLE | JSON array of user-defined tags |
| created_at | TEXT (ISO8601) | NOT NULL, INDEX | Capture timestamp |
| accessed_at | TEXT (ISO8601) | NULLABLE | Last retrieval timestamp |

**Validation Rules**:
- `content` must be non-empty and ≤ 10,000 characters
- `source_tool` must be one of: `claude-code`, `cline`, `continue`, `opencode`, `unknown`
- `entry_type` must be one of: `decision`, `pattern`, `observation`, `error`, `context`
- `project_id` must be exactly 16 hex characters
- `created_at` must be valid ISO 8601 timestamp

**Indexes**:
- `idx_project_created` on (project_id, created_at DESC) — for retention queries
- `idx_project_type` on (project_id, entry_type) — for filtered searches
- Vector index via `vec0` virtual table on embedding column

---

### ProjectConfig (Per-Project Settings)

Configuration for a specific project's memory behavior.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| project_id | TEXT | PRIMARY KEY | Hash of workspace path |
| workspace_path | TEXT | NOT NULL, UNIQUE | Canonical workspace path |
| retention_days | INTEGER | NOT NULL, DEFAULT 30 | Time-based retention threshold |
| max_size_mb | INTEGER | NOT NULL, DEFAULT 500 | Size-based retention threshold |
| created_at | TEXT (ISO8601) | NOT NULL | First initialization |
| last_pruned_at | TEXT (ISO8601) | NULLABLE | Last pruning operation |

**Validation Rules**:
- `retention_days` must be between 1 and 365
- `max_size_mb` must be between 50 and 2000
- `workspace_path` must be an absolute path

---

### StrategicMemoryFile (Logical, not stored in DB)

Human-maintained markdown files in the workspace. Not stored in SQLite — exists on filesystem.

| Field | Type | Location | Description |
|-------|------|----------|-------------|
| category | Enum | Directory name | goals, architecture, patterns, technology, status |
| content | Markdown | `.memory/<category>.md` | Human-written project context |
| last_modified | Timestamp | Filesystem | Last edit time |

**Categories**:
- `goals.md` — Project objectives, success criteria, milestones
- `architecture.md` — System design decisions, component relationships
- `patterns.md` — Coding conventions, naming rules, style preferences
- `technology.md` — Stack choices, versions, key dependencies
- `status.md` — Current sprint/work state, recent progress, blockers

---

### SearchResult (Computed, not stored)

A single result item returned by semantic search, derived from MemoryEntry with an added relevance score.

| Field | Type | Description |
|-------|------|-------------|
| id | TEXT (UUID) | Entry identifier |
| content | TEXT | Memory content text |
| entry_type | TEXT | Category (decision, pattern, observation, error, context) |
| score | FLOAT | Similarity score (0.0–1.0, normalized from L2 distance) |
| source_tool | TEXT | AI tool that captured this entry |
| created_at | TEXT (ISO8601) | Original capture timestamp |
| tags | TEXT (JSON array) | User-defined tags (nullable) |

**Source**: Defined by `mcp-tools.json` search_memories outputSchema. Implemented as a Pydantic model in `src/memory_server/models.py`.

---

### MemoryStats (Computed, not stored)

Runtime statistics for the memory system, computed on demand.

| Field | Type | Description |
|-------|------|-------------|
| project_id | TEXT | Project identifier |
| total_entries | INTEGER | Count of memory entries |
| storage_size_bytes | INTEGER | SQLite file size |
| oldest_entry | TEXT (ISO8601) | Timestamp of oldest entry |
| newest_entry | TEXT (ISO8601) | Timestamp of newest entry |
| entries_by_type | JSON | Count per entry_type |
| entries_by_tool | JSON | Count per source_tool |

---

## Relationships

```
ProjectConfig 1──∞ MemoryEntry
  (project_id)      (project_id)

StrategicMemoryFile ∞──1 Workspace
  (.memory/*.md)         (workspace_path)
```

- One ProjectConfig per workspace, many MemoryEntries per project
- Strategic memory files live in the workspace filesystem, independent of SQLite
- No foreign key enforcement between SQLite and filesystem (graceful if either missing)

---

## State Transitions

### MemoryEntry Lifecycle

```
Created → Active → Stale → Pruned
```

| State | Condition | Behavior |
|-------|-----------|----------|
| Created | Just captured | Entry stored with embedding |
| Active | age < retention_days AND total_size < max_size_mb | Available for search |
| Stale | age ≥ retention_days OR total_size ≥ max_size_mb | Candidate for pruning |
| Pruned | Removed by retention policy | Deleted from DB (irreversible) |

**Transitions**:
- Created → Active: Immediate (on successful INSERT)
- Active → Stale: Triggered by time passage or size threshold breach
- Stale → Pruned: Triggered by pruning operation (startup or periodic)

### ProjectConfig Lifecycle

```
Uninitialized → Initialized → Configured
```

| State | Condition | Behavior |
|-------|-----------|----------|
| Uninitialized | No config row exists | Use global defaults |
| Initialized | Config row created with defaults | Default retention applies |
| Configured | Developer customized settings | Custom retention applies |

---

## SQLite Schema

```sql
-- Core memory entries table
CREATE TABLE IF NOT EXISTS memory_entries (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    content TEXT NOT NULL CHECK(length(content) > 0 AND length(content) <= 10000),
    source_tool TEXT NOT NULL CHECK(source_tool IN ('claude-code', 'cline', 'continue', 'opencode', 'unknown')),
    session_id TEXT NOT NULL,
    entry_type TEXT NOT NULL CHECK(entry_type IN ('decision', 'pattern', 'observation', 'error', 'context')),
    tags TEXT,
    created_at TEXT NOT NULL,
    accessed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_project_created ON memory_entries(project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_project_type ON memory_entries(project_id, entry_type);

-- Vector embeddings (sqlite-vec virtual table)
CREATE VIRTUAL TABLE IF NOT EXISTS memory_embeddings USING vec0(
    id TEXT PRIMARY KEY,
    embedding float[384]
);

-- Project configuration
CREATE TABLE IF NOT EXISTS project_config (
    project_id TEXT PRIMARY KEY,
    workspace_path TEXT NOT NULL UNIQUE,
    retention_days INTEGER NOT NULL DEFAULT 30,
    max_size_mb INTEGER NOT NULL DEFAULT 500,
    created_at TEXT NOT NULL,
    last_pruned_at TEXT
);

-- Schema version tracking
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
);
```

---

## Data Volume Estimates

| Metric | Estimate | Basis |
|--------|----------|-------|
| Entries per session | 5-20 | Typical coding session decisions/patterns |
| Sessions per day | 2-5 | Active developer usage |
| Entry size (avg) | 500 bytes content + 1536 bytes embedding | Text + float32[384] |
| Daily growth | ~50 KB content + ~150 KB embeddings | 50 entries × 4 KB each |
| 30-day accumulation | ~6 MB | Before pruning kicks in |
| Peak realistic usage | 50-100 MB | Heavy usage over 30 days |
| 500MB cap scenario | ~250K entries | Unlikely to reach organically |
