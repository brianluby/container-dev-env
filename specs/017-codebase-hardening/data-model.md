# Data Model: Codebase Hardening

**Feature**: 017-codebase-hardening | **Date**: 2026-01-24

---

## Entities

### 1. Secret Entry

A key-value pair loaded from a secrets file at shell startup.

| Field | Type | Validation | Notes |
|-------|------|-----------|-------|
| key | string | `^[A-Z_][A-Z0-9_]*$` | FR-006 |
| value | string | No `$()`, `${}`, backticks | FR-014; bare `$` allowed |
| source_file | path | Must pass permission check | FR-005 |
| line_number | integer | >= 1 | For warning messages |

**Constraints**:
- Key uniqueness: last-writer-wins within a single file (standard dotenv behavior)
- Value delimiter: first `=` only; subsequent `=` characters are part of value (FR-017)
- Rejected patterns: `$()`, `${...}`, backtick pairs in value (FR-014)
- File permissions: must NOT be group-writable or world-readable (FR-005)

**Lifecycle**: Loaded at shell startup → exported to environment → available for session duration

---

### 2. Session Record (JSON)

Tracks a single agent invocation from start to completion.

| Field | Type | Validation | Notes |
|-------|------|-----------|-------|
| id | UUID | Standard UUID format | Generated at creation |
| backend | enum | `opencode` \| `claude` | Selected backend |
| started_at | ISO 8601 | UTC timestamp | Creation time |
| ended_at | ISO 8601 \| null | UTC timestamp | Set on completion/failure |
| status | enum | `active` \| `paused` \| `completed` \| `failed` | State machine |
| task_description | string | **JSON-escaped** (FR-002) | User-provided, untrusted |
| approval_mode | enum | `manual` \| `auto` \| `hybrid` | Execution mode |
| workspace | path | **JSON-escaped** | Current directory at start |
| checkpoints | array | JSON array | Checkpoint refs |
| token_usage | object | Numeric fields | Cost tracking |
| action_log_path | path | **JSON-escaped** | Log file location |

**Construction**: All string fields MUST be passed through `jq --arg` for safe JSON escaping (FR-002).

**State transitions**:
```
active → paused (signal received)
active → completed (exit 0)
active → failed (non-zero exit)
paused → active (resume)
```

---

### 3. Action Log Entry (JSONL)

A single line in the session's JSONL action log file.

| Field | Type | Validation | Notes |
|-------|------|-----------|-------|
| timestamp | ISO 8601 | UTC | Entry creation time |
| action | enum | See valid actions list | Log entry type |
| target | string | **JSON-escaped**, credentials redacted | What was acted upon |
| details | string | **JSON-escaped**, credentials redacted | Description |
| result | string \| null | **JSON-escaped** | Outcome |
| checkpoint_id | string \| null | **JSON-escaped** | Associated checkpoint |

**Construction**: All user-facing string fields MUST use `jq --arg` (FR-002). Credential redaction happens before JSON construction.

---

### 4. Checksum Manifest Entry

A line in the centralized `checksums.sha256` file.

| Field | Type | Format | Notes |
|-------|------|--------|-------|
| hash | hex string | 64 characters (SHA256) | Lowercase hex |
| filename | string | Architecture-qualified | e.g., `opencode-linux-amd64` |

**File format**: `<sha256hash>  <filename>` (two-space separator, per `sha256sum` convention)

**Covered binaries**:
- OpenCode (per TARGETARCH: amd64, arm64)
- Chezmoi (per TARGETARCH)
- age (per TARGETARCH)
- VSIX extensions (architecture-independent)

---

### 5. Agent Command (Array)

The runtime representation of the backend command to execute.

| Element | Type | Source | Notes |
|---------|------|--------|-------|
| [0] | string | Backend binary | `opencode` or `claude` |
| [1..n-1] | string | Fixed flags | Backend-specific CLI flags |
| [n] | string | User input | **Never interpreted** (FR-001) |

**Construction**: Bash array (`cmd=(...)`) with task description as a single quoted element. Execution via `"${cmd[@]}"` or `exec "${cmd[@]}"`.

---

### 6. Diagnostic Message

Standardized error/warning output per FR-016.

| Field | Type | Format | Notes |
|-------|------|--------|-------|
| level | enum | `ERROR` \| `WARN` | Severity |
| component | string | Lowercase identifier | e.g., `secrets`, `agent`, `build` |
| message | string | Human-readable | Description of the issue |

**Output format**: `[<LEVEL>] <component>: <message>` → stderr
**Exit behavior**: `[ERROR]` messages typically accompany non-zero exit; `[WARN]` messages allow continued execution.

---

## Relationships

```text
Secret Entry ──loaded-by──▶ secrets-load.sh
Session Record ──contains──▶ Action Log Entry (1:many via action_log_path)
Session Record ──references──▶ Agent Command (task_description field)
Checksum Manifest ──verified-by──▶ Dockerfile RUN commands
Agent Command ──constructed-by──▶ provider.sh:build_backend_command()
Diagnostic Message ──emitted-by──▶ all scripts (stderr)
```
