# Data Model: Agentic Assistant

**Feature Branch**: `006-agentic-assistant`
**Date**: 2026-01-22
**Derived from**: spec.md Key Entities + research.md

## Entities

### Session

A long-running interaction between developer and the agentic assistant.

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| id | string (UUID) | Unique session identifier | Generated on creation |
| backend | enum (opencode, claude) | Which agent tool is active | Selection logic at start |
| started_at | timestamp (ISO 8601) | When the session began | System clock |
| ended_at | timestamp (ISO 8601, nullable) | When the session ended | Set on completion/interrupt |
| status | enum (active, paused, completed, failed) | Current session state | Updated by wrapper |
| task_description | string | The developer's original task description | User input |
| approval_mode | enum (manual, auto, hybrid) | Configured approval level | User config or flag |
| checkpoints | Checkpoint[] | Ordered list of checkpoints | Created during operation |
| action_log_path | string (filepath) | Path to the JSONL action log | `$AGENT_STATE_DIR/logs/{id}.jsonl` |
| token_usage | TokenUsage | Cumulative token metrics | Aggregated from tool output |

**State transitions**:
```
[created] → active → paused → active → completed
                  → failed
                  → completed
```

**Identity**: Sessions are identified by UUID. A session belongs to one project workspace.

---

### Checkpoint

A saved state of the codebase enabling rollback.

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| id | string | Git stash reference or commit SHA | Git operation |
| session_id | string (UUID) | Parent session | Foreign key |
| created_at | timestamp (ISO 8601) | When checkpoint was created | System clock |
| description | string | What was about to be attempted | Agent context |
| operation_type | enum (file_edit, command_exec, multi_file, sub_agent) | Category of operation | Wrapper classification |
| status | enum (passed, failed, rolled_back) | Outcome after checkpoint | Updated post-operation |
| files_affected | string[] | List of files modified since previous checkpoint | Git diff |

**Lifecycle**:
```
[created] → passed (operation succeeded, checkpoint retained)
         → failed (operation failed, available for rollback)
         → rolled_back (developer restored this checkpoint)
```

**Retention**: Subject to configurable policy (keep last N or last N days). Default: 50 checkpoints.

---

### Task

A developer-assigned unit of work.

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| id | string (UUID) | Unique task identifier | Generated |
| session_id | string (UUID) | Parent session | Foreign key |
| description | string | What to accomplish | User input |
| status | enum (pending, in_progress, completed, failed) | Current state | Updated by agent |
| sub_tasks | SubTask[] | Delegated parallel portions | Created by agent if parallelizable |
| files_modified | string[] | All files changed by this task | Tracked by wrapper |

---

### SubAgent

A delegated worker for parallel task portions.

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| id | string (UUID) | Unique sub-agent identifier | Generated |
| parent_task_id | string (UUID) | Parent task | Foreign key |
| description | string | Sub-task assignment | Agent decomposition |
| status | enum (pending, running, completed, failed) | Current state | Updated by agent |
| files_scope | string[] | Files this sub-agent may modify | Assigned by parent |
| result | string (nullable) | Summary of what was accomplished | Set on completion |

**Constraint**: Two sub-agents MUST NOT have overlapping `files_scope` entries.

---

### BackgroundTask

A long-running process independent of agent workflow.

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| id | string (UUID) | Unique identifier | Generated |
| session_id | string (UUID) | Parent session | Foreign key |
| command | string | Shell command being run | User/agent specified |
| pid | integer | Process ID | OS |
| status | enum (running, stopped, failed) | Current state | Process monitoring |
| started_at | timestamp | When process started | System clock |
| output_path | string (filepath) | Path to captured stdout/stderr | Log file |

---

### ActionLogEntry

A single recorded action in the session action log (JSONL format).

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| timestamp | timestamp (ISO 8601) | When the action occurred | System clock |
| action | enum (file_edit, file_create, file_delete, command_exec, checkpoint, rollback, decision, error, sub_agent_spawn, sub_agent_complete) | Action category | Wrapper classification |
| target | string | File path, command, or entity affected | Agent operation |
| details | string | Human-readable description | Agent context |
| result | enum (success, failure, pending, nullable) | Outcome if applicable | Post-action |
| checkpoint_id | string (nullable) | Associated checkpoint if any | Cross-reference |

---

### TokenUsage

Cumulative token metrics for a session.

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| input_tokens | integer | Total input/prompt tokens | LLM API response |
| output_tokens | integer | Total output/completion tokens | LLM API response |
| total_tokens | integer | Sum of input + output | Computed |
| estimated_cost_usd | float | Estimated cost in USD | Computed from model pricing |
| model | string | Primary model used | Agent config |
| provider | string | LLM provider | Agent config |

---

### ApprovalMode

Configuration for human oversight level.

| Value | OpenCode Mapping | Claude Code Mapping | Behavior |
|-------|-----------------|--------------------:|----------|
| manual | `"*": "ask"` | default (prompts for each) | Every action requires approval |
| auto | `"*": "allow"` | `--dangerously-skip-permissions` | Agent proceeds without asking |
| hybrid | per-tool permissions | settings-based policies | Only risky operations need approval |

---

### ExclusionPattern

File/directory patterns the agent must not access.

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| pattern | string (glob) | File pattern to exclude | `.agentignore` file |
| scope | enum (read, send, all) | What's restricted | Configuration |

**Default patterns**:
- `.env` / `.env.*` — environment files with secrets
- `*.pem` / `*.key` — cryptographic material
- `credentials/` / `secrets/` — secret directories
- `*.sqlite` / `*.db` — local databases (may contain sensitive data)

---

## Relationships

```
Session 1──* Checkpoint
Session 1──* Task
Session 1──* BackgroundTask
Session 1──1 TokenUsage
Session 1──1 ActionLog (file of ActionLogEntry[])
Task 1──* SubAgent
```

## Storage Locations

| Entity | Storage Format | Location |
|--------|---------------|----------|
| Session metadata | JSON | `$AGENT_STATE_DIR/sessions/{id}.json` |
| Checkpoint | Git stash/ref | `.git/refs/stash` (in project) |
| Action Log | JSONL | `$AGENT_STATE_DIR/logs/{session-id}.jsonl` |
| Background Task output | Text | `$AGENT_STATE_DIR/bg/{id}.log` |
| Token Usage | Embedded in Session | Same as session metadata |
| Exclusion Patterns | Text (glob per line) | `$PROJECT/.agentignore` |
| OpenCode native state | SQLite/JSON | `~/.local/share/opencode/` |
| Claude Code native state | JSONL | `~/.claude/projects/` |
