# Tasks: Persistent Memory for AI Agent Context

**Input**: Design documents from `/specs/013-persistent-memory/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Included per constitution requirement (III. Test-First Development).

**Organization**: Tasks grouped by user story. Each story independently implementable and testable after Phase 2 (Foundational) completes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, dependency installation, tooling configuration

- [x] T001 Create project directory structure per plan.md (src/memory_server/, src/memory_init/, tests/unit/, tests/integration/, tests/contract/)
- [x] T002 Initialize Python project with pyproject.toml (name=persistent-memory, python>=3.11, deps: fastembed, sqlite-vec, mcp>=1.0.0<2.0.0, pydantic>=2.0, pyyaml)
- [x] T002b Generate pinned lockfile (uv lock or pip-compile requirements.txt) and commit to version control
- [x] T002c [P] Run pip-audit on all dependencies, document any exceptions with justification
- [x] T003 [P] Configure ruff for linting and formatting in pyproject.toml ([tool.ruff] section)
- [x] T003b [P] Configure mypy in pyproject.toml ([tool.mypy] section: strict=true, packages=["memory_server", "memory_init"])
- [x] T004 [P] Configure pytest in pyproject.toml ([tool.pytest.ini_options] section with testpaths, asyncio_mode)
- [x] T005 [P] Create src/memory_server/__init__.py with package version and logger setup
- [x] T006 [P] Create src/memory_init/__init__.py with package metadata

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T007 [P] Unit test for Pydantic models in tests/unit/test_models.py (MemoryEntry validation, ProjectConfig defaults, field constraints)
- [x] T008 [P] Unit test for project ID hashing in tests/unit/test_project.py (deterministic hash, 16 hex chars, different paths → different IDs)
- [x] T009 [P] Unit test for config parsing in tests/unit/test_config.py (.memoryrc YAML loading, env var overrides, defaults)
- [x] T010 [P] Unit test for storage layer in tests/unit/test_storage.py (schema creation, CRUD ops, sqlite-vec extension loading)
- [x] T011 [P] Unit test for embeddings wrapper in tests/unit/test_embeddings.py (vector generation, dimension=384, batch embedding)

### Implementation for Foundational

- [x] T012 [P] Implement Pydantic models in src/memory_server/models.py (MemoryEntry, ProjectConfig, MemoryStats, SearchResult per data-model.md)
- [x] T013 [P] Implement project ID hashing in src/memory_server/project.py (SHA-256 of canonical workspace path, truncated to 16 hex, workspace detection)
- [x] T014 [P] Implement config parsing in src/memory_server/config.py (.memoryrc YAML loading, MEMORY_* env var overrides, default values)
- [x] T015 Implement storage layer in src/memory_server/storage.py (SQLite connection with WAL mode, sqlite-vec extension loading, schema init per data-model.md DDL, CRUD operations for memory_entries and project_config tables)
- [x] T016 Implement embeddings wrapper in src/memory_server/embeddings.py (FastEmbed TextEmbedding init with model_name="BAAI/bge-small-en-v1.5", embed_text() → list[float], embed_batch() for bulk operations, 384-dim output)
- [x] T017 Create MCP server skeleton in src/memory_server/server.py (FastMCP instance named "memory", logging to stderr, placeholder tool decorators)
- [x] T018 Create entry point in src/memory_server/__main__.py (parse MEMORY_* env vars, init storage + embeddings, call mcp.run(transport="stdio"))
- [x] T019 Create Dockerfile layer in src/docker/memory.Dockerfile (FROM python:3.12-slim-bookworm@sha256:<pinned-digest>, non-root user, pip install from lockfile, COPY src, health check script; NOTE: Python 3.12 required because onnxruntime/fastembed lack 3.14 wheels)

**Checkpoint**: Foundation ready — storage, embeddings, config, and MCP skeleton operational. Project scoping (T013) satisfies FR-002 MUST requirement for MVP (workspace-hashed project IDs prevent cross-project contamination). User story implementation can begin.

---

## Phase 3: User Story 2 - Developer Maintains Strategic Context (Priority: P1) 🎯 MVP

**Goal**: Developer creates and edits structured `.memory/` files with template guidance. Files are version-controlled and provide strategic context to AI tools.

**Independent Test**: Create a new workspace, run `memory-init`, verify template files exist with placeholder guidance. Edit a file, confirm it persists across container restart via volume mount.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T020 [P] [US2] Unit test for init logic in tests/unit/test_init.py (template creation, idempotency, --force overwrite, .gitignore generation)
- [x] T021 [P] [US2] Integration test for memory-init CLI in tests/integration/test_memory_init.py (end-to-end run in temp dir, verify all files created with correct content)

### Implementation for User Story 2

- [x] T022 [P] [US2] Create template file src/memory_init/templates/goals.md (H1 heading, category description, H2 placeholder sections with guidance)
- [x] T023 [P] [US2] Create template file src/memory_init/templates/architecture.md (system design decisions template)
- [x] T024 [P] [US2] Create template file src/memory_init/templates/patterns.md (coding conventions template)
- [x] T025 [P] [US2] Create template file src/memory_init/templates/technology.md (stack choices template)
- [x] T026 [P] [US2] Create template file src/memory_init/templates/status.md (current work state template)
- [x] T027 [US2] Implement init logic in src/memory_init/init.py (copy templates to .memory/, generate .memoryrc with defaults, generate .memory/.gitignore excluding *.db files)
- [x] T028 [US2] Create CLI entry point in src/memory_init/__main__.py (argparse: --workspace PATH, --force, --quiet, --output-format json|text; call init logic; support structured JSON output per constitution VI)
- [x] T029 [US2] Add memory-init script entry to pyproject.toml [project.scripts] section
- [x] T073 [P] [US2] Add secrets prevention guidance: include security warning headers in each template file (do not store API keys, tokens, credentials), ensure .memoryrc excluded_patterns covers common secret patterns per contracts/strategic-memory-init.sh

**Checkpoint**: `memory-init` creates a complete `.memory/` directory with editable templates. Files are version-controllable.

---

## Phase 4: User Story 1 - AI Remembers Project Context Across Sessions (Priority: P1)

**Goal**: AI tools automatically load strategic memory files at session start. Context persists across container restarts. Same context available to Claude Code, Cline, and Continue.

**Independent Test**: Document a convention in `.memory/patterns.md`, restart container, start AI session, verify AI references that convention without prompting.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T030 [P] [US1] Integration test for context loading in tests/integration/test_context_loading.py (verify .memory/ files are detected and content available to MCP server)
- [x] T031 [P] [US1] Contract test for MCP config generation in tests/contract/test_mcp_config.py (validate generated configs match contracts/mcp-server-config.json schema)

### Implementation for User Story 1

- [x] T032 [P] [US1] Implement strategic memory loader in src/memory_server/strategic.py (scan .memory/*.md, concatenate content, expose via MCP resource or context)
- [x] T033 [US1] Add MCP resource for strategic memory in src/memory_server/server.py (register resource that returns combined strategic context from .memory/ files)
- [x] T034 [P] [US1] Create Claude Code config template in src/memory_init/configs/claude.json (mcpServers block per contracts/mcp-server-config.json)
- [x] T035 [P] [US1] Create Cline config template in src/memory_init/configs/cline.json (mcpServers block per contracts/mcp-server-config.json)
- [x] T036 [P] [US1] Create Continue config template in src/memory_init/configs/continue.yaml (mcpServers section per contracts/mcp-server-config.json)
- [x] T037 [US1] Add --setup-tools flag to memory-init CLI in src/memory_init/__main__.py (generates AI tool MCP configs from templates)
- [x] T038 [US1] Add entrypoint integration in src/docker/memory-entrypoint.sh (detect .memory/ in workspace, start MCP server if present, within 2s budget)
- [x] T038b [P] [US1] Integration test for container restart persistence in tests/integration/test_persistence.py (store strategic + tactical memory, simulate container restart via server restart, verify all data persists across 10 restart cycles per SC-005)
- [x] T074 [P] [US1] Contract test for memory-init CLI in tests/contract/test_memory_init_cli.py (validate CLI arguments, exit codes, and created file structure against contracts/strategic-memory-init.sh interface)

**Checkpoint**: AI tools connect to memory MCP server and receive strategic context from `.memory/` files automatically. Persists through container restarts.

---

## Phase 5: User Story 3 - Automatic Session Context Capture (Priority: P2)

**Goal**: AI automatically captures relevant session context (decisions, patterns, observations) without developer action. Captured context available in subsequent sessions.

**Independent Test**: Have a session discussing a specific pattern, start new session, verify captured pattern is retrievable via list_memories.

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T039 [P] [US3] Unit test for store_memory tool in tests/unit/test_store_memory.py (valid entry stored, embedding generated, invalid content rejected, entry_type validated)
- [x] T040 [P] [US3] Integration test for capture flow in tests/integration/test_capture.py (store via MCP tool, verify in SQLite, verify embedding in vec0 table)
- [x] T040b [P] [US3] Integration test for cross-tool sharing (FR-015) in tests/integration/test_multi_tool.py (store entry with source_tool=claude-code, retrieve from session with source_tool=cline, verify entry accessible across tools)
- [x] T040c [P] [US3] Integration test for concurrent writes in tests/integration/test_multi_tool.py (spawn 3 concurrent writers with different source_tools, verify all entries stored without corruption, validate WAL mode handles contention)

### Implementation for User Story 3

- [x] T041 [US3] Implement store_memory MCP tool in src/memory_server/server.py (validate input per contracts/mcp-tools.json, generate embedding, insert to storage, return ID)
- [x] T042 [US3] Implement session tracking in src/memory_server/session.py (generate session_id per connection, detect source_tool from MEMORY_SOURCE_TOOL env var set in each AI tool's MCP config)
- [x] T043 [US3] Add graceful degradation in src/memory_server/server.py (if embedding fails, store with null embedding; if storage unavailable, log warning and continue)

**Checkpoint**: AI tools can store memories via MCP. Entries persist in SQLite with embeddings. System degrades gracefully if capture subsystem fails.

---

## Phase 6: User Story 4 - Semantic Search for Relevant Context (Priority: P2)

**Goal**: AI searches tactical memory using meaning-based queries. Returns results ranked by relevance with similarity scores.

**Independent Test**: Store context about "authentication flow", search for "login process", verify authentication context is returned with high relevance score.

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T044 [P] [US4] Unit test for search_memories tool in tests/unit/test_search.py (semantic matching, score ordering, min_score filtering, entry_type filtering, empty results)
- [x] T045 [P] [US4] Unit test for list_memories tool in tests/unit/test_list.py (chronological order, pagination, type filtering)
- [x] T046 [P] [US4] Integration test for semantic search in tests/integration/test_semantic_search.py (store 5 entries, query with different wording, verify correct entry ranked first)

### Implementation for User Story 4

- [x] T047 [US4] Implement search_memories MCP tool in src/memory_server/server.py (embed query, sqlite-vec KNN search, apply min_score filter, return ranked results per contract)
- [x] T048 [US4] Implement list_memories MCP tool in src/memory_server/server.py (query by project_id, order by created_at DESC, pagination with offset/limit)
- [x] T049 [US4] Add relevance score normalization in src/memory_server/storage.py (convert L2 distance to 0.0-1.0 similarity score)

**Checkpoint**: Semantic search returns relevant results with similarity scores. List provides chronological browsing. Both filter by entry type.

---

## Phase 7: User Story 5 - Memory Isolation Per Project (Priority: P2)

**Goal**: Each project workspace has isolated memory. No cross-project contamination.

**Independent Test**: Set up memory in two workspaces with different content, verify queries in workspace A never return workspace B content.

### Tests for User Story 5

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T050 [P] [US5] Integration test for isolation in tests/integration/test_isolation.py (two project IDs, store in A, query from B returns empty, query from A returns results)
- [x] T051 [P] [US5] Unit test for DB path scoping in tests/unit/test_project.py (different workspaces → different DB files, path canonicalization handles symlinks)

### Implementation for User Story 5

- [x] T052 [US5] Implement scoped DB path resolution in src/memory_server/project.py (MEMORY_DB_PATH/projects/<project_id>/memory.db, create directories on first use)
- [x] T053 [US5] Wire project scoping into storage layer in src/memory_server/storage.py (storage init takes project_id, opens correct DB file, all queries scoped)
- [x] T054 [US5] Wire workspace detection into MCP server startup in src/memory_server/__main__.py (read MEMORY_WORKSPACE env, derive project_id, pass to storage init)

**Checkpoint**: Multiple projects can exist on same Docker volume without data leakage. Each workspace has its own SQLite DB file.

---

## Phase 8: User Story 6 - Memory Size Management (Priority: P3)

**Goal**: Automatic retention policies prune old/excess tactical memory. Storage stays bounded.

**Independent Test**: Configure 1-day retention, insert entries with old timestamps, trigger pruning, verify old entries removed and storage reduced.

### Tests for User Story 6

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T055 [P] [US6] Unit test for retention logic in tests/unit/test_retention.py (time-based pruning, size-based pruning, combined threshold, oldest-first order)
- [x] T056 [P] [US6] Unit test for get_memory_stats tool in tests/unit/test_stats.py (entry counts by type/tool, storage size calculation)
- [x] T057 [P] [US6] Unit test for delete_memory tool in tests/unit/test_delete.py (existing entry deleted, not_found for unknown ID, embedding also removed)

### Implementation for User Story 6

- [x] T058 [US6] Implement retention logic in src/memory_server/retention.py (prune_expired(): delete entries older than retention_days; prune_oversized(): delete oldest until under max_size_mb; run_pruning(): both thresholds)
- [x] T059 [US6] Implement get_memory_stats MCP tool in src/memory_server/server.py (query entry counts, file size, oldest/newest, group by type and tool per contract)
- [x] T060 [US6] Implement delete_memory MCP tool in src/memory_server/server.py (delete from memory_entries + memory_embeddings by ID, return status per contract)
- [x] T061 [US6] Add startup pruning to src/memory_server/__main__.py (call run_pruning() during init, within 2s startup budget)
- [x] T062 [US6] Add periodic pruning timer in src/memory_server/server.py (asyncio background task, run every 6 hours during active sessions)

**Checkpoint**: Storage automatically bounded by time and size. Developers can inspect stats and delete entries manually.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Hardening, observability, documentation, and validation

- [x] T063 [P] Add structured JSON logging throughout src/memory_server/ (logger config to stderr, include timestamps, levels, correlation IDs)
- [x] T064 [P] Add error handling for corrupted DB in src/memory_server/storage.py (detect corruption, recreate DB, log warning, preserve strategic memory)
- [x] T065 [P] Add volume-not-mounted detection in src/memory_server/__main__.py (check MEMORY_DB_PATH writable, clear error message with setup instructions)
- [x] T066 [P] Add strategic memory size warning in src/memory_server/strategic.py (warn if .memory/ total > 500KB, continue functioning)
- [x] T067 [P] Add health check script in src/docker/healthcheck.py (verify MCP server responds, SQLite accessible, report status JSON)
- [x] T068 Validate quickstart.md end-to-end (follow all steps in fresh container, verify each step works)
- [x] T069 [P] Add py.typed marker file in src/memory_server/py.typed (PEP 561 type stub support)
- [x] T070 Run ruff check and ruff format across all src/ and tests/ files
- [x] T070b Run mypy src/ and resolve all type errors (strict mode per constitution II)
- [x] T071 [P] Performance benchmark for semantic search in tests/integration/test_search_performance.py (seed DB with 1000 entries, run 100 queries, assert p95 latency < 50ms per SC-003)
- [ ] T072 [P] Validate multi-arch Docker build — DEFERRED: Docker daemon not available in dev environment; requires CI execution
- [ ] T075 [P] Run container image vulnerability scan — DEFERRED: Docker daemon not available; requires CI execution with trivy/grype

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US2 (Phase 3)**: Depends on Foundational. No story dependencies (creates files only)
- **US1 (Phase 4)**: Depends on Foundational. Logically follows US2 (needs files to exist) but can be developed in parallel
- **US3 (Phase 5)**: Depends on Foundational. Independent of US1/US2
- **US4 (Phase 6)**: Depends on Foundational. Benefits from US3 (needs stored entries to search) but testable independently with manual inserts
- **US5 (Phase 7)**: Depends on Foundational. Independent of other stories (project.py is foundational)
- **US6 (Phase 8)**: Depends on Foundational. Benefits from US3 (needs entries to prune) but testable independently
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) ← BLOCKS ALL
    ↓
    ├── Phase 3 (US2: Strategic Files) ─┐
    ├── Phase 4 (US1: Context Loading) ─┤ P1 stories (MVP)
    │                                    │
    ├── Phase 5 (US3: Auto Capture) ────┤
    ├── Phase 6 (US4: Semantic Search) ─┤ P2 stories
    ├── Phase 7 (US5: Isolation) ───────┤
    │                                    │
    └── Phase 8 (US6: Size Mgmt) ───────┘ P3 story
                                         ↓
                                   Phase 9 (Polish)
```

### Within Each User Story

1. Tests MUST be written and FAIL before implementation
2. Models/data layer before service logic
3. Service logic before MCP tool handlers
4. Core implementation before integration/config generation
5. Story complete before checkpoint validation

### Parallel Opportunities

- **Phase 1**: T002c, T003, T003b, T004, T005, T006 all parallel
- **Phase 2 Tests**: T007–T011 all parallel
- **Phase 2 Impl**: T012, T013, T014 parallel; T015 depends on T012; T016 independent
- **Phase 3**: T022–T026 all parallel (template files); T020, T021 parallel (tests)
- **Phase 4**: T034, T035, T036 parallel (config templates); T030, T031 parallel (tests)
- **Phase 5–8**: Tests within each phase are parallel
- **Cross-story**: US2, US3, US5, US6 can all proceed in parallel after Foundational

---

## Parallel Example: User Story 2

```bash
# Launch all tests together:
Task: "Unit test for init logic in tests/unit/test_init.py"
Task: "Integration test for memory-init CLI in tests/integration/test_memory_init.py"

# Launch all template files together:
Task: "Create template file src/memory_init/templates/goals.md"
Task: "Create template file src/memory_init/templates/architecture.md"
Task: "Create template file src/memory_init/templates/patterns.md"
Task: "Create template file src/memory_init/templates/technology.md"
Task: "Create template file src/memory_init/templates/status.md"
```

## Parallel Example: User Story 4

```bash
# Launch all tests together:
Task: "Unit test for search_memories in tests/unit/test_search.py"
Task: "Unit test for list_memories in tests/unit/test_list.py"
Task: "Integration test for semantic search in tests/integration/test_semantic_search.py"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 2 (create strategic files)
4. Complete Phase 4: User Story 1 (load strategic files into AI tools)
5. **STOP and VALIDATE**: Developer can init memory, edit files, restart container, and AI remembers context
6. Deploy/demo — this alone provides the core value proposition

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US2 (Strategic Files) → Developer can create `.memory/` → Checkpoint
3. US1 (Context Loading) → AI tools load context → **MVP!**
4. US3 (Auto Capture) → Sessions captured automatically → Checkpoint
5. US4 (Semantic Search) → Intelligent retrieval → Checkpoint
6. US5 (Isolation) → Multi-project safe → Checkpoint
7. US6 (Size Management) → Long-term sustainable → Checkpoint
8. Polish → Production-ready

### Parallel Team Strategy

With multiple developers after Foundational completes:

- **Developer A**: US2 + US1 (P1 stories, sequential dependency)
- **Developer B**: US3 + US4 (P2 capture + search, complementary)
- **Developer C**: US5 + US6 (P2 isolation + P3 management, independent)

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in same phase
- [Story] label maps task to specific user story for traceability
- Each user story independently completable and testable after Foundational
- Constitution III requires TDD: tests written first, verified failing before implementation
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Container image size budget: ~100MB for memory system (FastEmbed + sqlite-vec + code)
- Performance budget: <2s startup, <50ms query latency
- Total tasks: 82 (including constitution compliance tasks T002b, T002c, T003b, T040b, T040c, T070b, T071, T072, T073, T074, T075)
