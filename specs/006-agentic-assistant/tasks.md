# Tasks: Agentic Assistant

**Input**: Design documents from `/specs/006-agentic-assistant/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Included — plan.md specifies BATS for CLI testing, bash-based integration tests, and contract tests. Constitution requires Test-First Development (Principle III).

**Organization**: Tasks grouped by user story (10 stories: 3xP1, 4xP2, 3xP3). Each story is independently implementable and testable after Foundational phase completes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Wrapper scripts**: `src/agent/` (agent.sh, lib/*.sh, defaults/)
- **Container config**: `docker/` (Dockerfile.agent, docker-compose.agent.yml, healthcheck.sh)
- **Tests**: `tests/unit/` (BATS), `tests/integration/` (bash), `tests/contract/` (BATS)
- **State directory**: `$AGENT_STATE_DIR` (default: `~/.local/share/agent/`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, tooling, and directory structure

- [x] T001 Create project directory structure per plan.md (`src/agent/`, `src/agent/lib/`, `src/agent/defaults/`, `docker/`, `tests/unit/`, `tests/integration/`, `tests/contract/`)
- [x] T002 [P] Create shellcheck configuration file at `.shellcheckrc` in repository root
- [x] T003 [P] Create BATS test helper with common assertions in `tests/test_helper.bash`
- [x] T004 [P] Create default exclusion patterns file in `src/agent/defaults/agentignore`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core library modules and container infrastructure that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

### Foundational Tests

> **Write these tests FIRST, ensure they FAIL before implementation**

- [x] T005 [P] Unit test for configuration loading in `tests/unit/test_config.bats` (load JSON config, merge global + project, env var defaults, invalid config error handling)
- [x] T006 [P] Unit test for provider detection in `tests/unit/test_provider.bats` (detect installed backends, validate API key presence, selection priority: flag > env > config)
- [x] T007 [P] Unit test for exclusion patterns in `tests/unit/test_exclusions.bats` (load default patterns, parse .agentignore, glob matching, translate to tool-native formats)
- [x] T008 [P] Unit test for action log operations in `tests/unit/test_log.bats` (append JSONL entry, read/filter/tail, credential redaction, JSON and text output)

### Foundational Implementation

- [x] T009 Implement configuration loading and validation in `src/agent/lib/config.sh` (parse `.agent.json`, merge global + project config, validate values, env var defaults for `AGENT_BACKEND`, `AGENT_MODE`, `AGENT_STATE_DIR`)
- [x] T010 [P] Implement provider availability checking in `src/agent/lib/provider.sh` (detect installed backends, validate API keys from env vars, selection logic: `--claude` flag > `AGENT_BACKEND` env > default opencode)
- [x] T011 [P] Implement `.agentignore` parsing and application in `src/agent/lib/exclusions.sh` (load defaults + project patterns, translate to OpenCode watcher config and Claude Code settings, glob matching)
- [x] T012 [P] Implement action log writing and reading in `src/agent/lib/log.sh` (append JSONL entries per ActionLogEntry schema, read/filter/tail, credential filtering, text and JSON output formats)
- [x] T013 Implement base wrapper script skeleton in `src/agent/agent.sh` (argument parsing for all options and subcommands per CLI contract, `--help`/`--version`, source lib modules, exit code constants, stdin support)
- [x] T014 [P] Create agent layer Dockerfile in `docker/Dockerfile.agent` (multi-stage, install OpenCode from pinned version via `OPENCODE_VERSION` build arg with direct binary download from GitHub releases, conditional Claude Code via `INSTALL_CLAUDE_CODE` and `CLAUDE_CODE_VERSION` build args, post-install verify versions match pinned values, non-root `developer` user, `WORKDIR /workspace`, HEALTHCHECK, multi-arch via buildx)
- [x] T015 [P] Create Docker Compose override in `docker/docker-compose.agent.yml` (volume mounts per container contract, env var passthrough for API keys, port 4096 for headless server, resource limits)
- [x] T016 [P] Create container health check script in `docker/healthcheck.sh` (verify `opencode --version` succeeds, optionally verify `claude --version` if installed)
- [x] T017 Verify installed agent binary integrity in `docker/Dockerfile.agent` (RUN step: confirm `opencode --version` outputs pinned `OPENCODE_VERSION` string, confirm `claude --version` matches `CLAUDE_CODE_VERSION` if installed, fail build on mismatch)

**Checkpoint**: Foundation ready — tests exist and fail, library modules pass them, container builds with pinned versions

---

## Phase 3: User Story 1 — Start Autonomous Coding Session (Priority: P1) MVP

**Goal**: Developer starts the agentic assistant in the container, assigns a task, and it works autonomously without GUI dependencies

**Independent Test**: Start agent with a multi-file task, verify it initializes without error, passes task to backend in correct mode, runs headlessly

### Tests for User Story 1

> **Write these tests FIRST, ensure they FAIL before implementation**

- [x] T018 [P] [US1] Contract test for CLI startup flags and exit codes in `tests/contract/test_cli_interface.bats` (verify `--help`, `--version`, missing API key exits 3, missing backend exits 4, valid invocation exits 0)
- [x] T019 [P] [US1] Integration test for container startup in `tests/integration/test_container_startup.sh` (build container, start with API key env vars, verify agent available, verify no X11/GUI deps, verify non-root user)

### Implementation for User Story 1

- [x] T020 [US1] Implement provider validation and backend launch in `src/agent/agent.sh` (validate API key presence, check backend binary exists, construct backend command, launch OpenCode via `opencode run "prompt"` or Claude Code via `claude -p "prompt"`)
- [x] T021 [US1] Implement headless server mode in `src/agent/agent.sh` (`--serve` launches `opencode serve` with `OPENCODE_SERVER_PASSWORD` auth, error if Claude Code backend selected with `--serve`)
- [x] T022 [US1] Implement `agent config --validate` subcommand in `src/agent/agent.sh` (load config, check API keys, check backend availability, report status as text or JSON)
- [x] T023 [US1] Add API key validation integration test in `tests/integration/test_api_key_validation.sh` (missing key shows clear error, multiple providers configured uses correct selection)

**Checkpoint**: Agent starts in container, launches backend tool with task, runs headlessly. MVP functional.

---

## Phase 4: User Story 2 — Checkpoint and Rollback Changes (Priority: P1)

**Goal**: Automatic checkpoints before each agent operation with rollback capability and history viewing

**Independent Test**: Let agent make changes, rollback to specific checkpoint, verify codebase returns to exact state

### Tests for User Story 2

- [x] T024 [P] [US2] Unit test for checkpoint operations in `tests/unit/test_checkpoint.bats` (create with metadata, list with formatting, rollback to stash, retention enforcement, disk space check)
- [x] T025 [P] [US2] Integration test for checkpoint lifecycle in `tests/integration/test_checkpoint_ops.sh` (create > list > rollback > verify files restored, multiple checkpoints ordered correctly, pruning)

### Implementation for User Story 2

- [x] T026 [US2] Implement checkpoint creation and management in `src/agent/lib/checkpoint.sh` (create via `git stash push -m "checkpoint: ..."`, list via `git stash list`, rollback via `git stash apply`, metadata in message: timestamp + operation_type + description, disk space pre-check)
- [x] T027 [US2] Implement checkpoint retention policy in `src/agent/lib/checkpoint.sh` (configurable `max_count` and `max_age_days`, auto-prune on creation, `--prune` manual trigger)
- [x] T028 [US2] Implement `agent checkpoints` subcommand in `src/agent/agent.sh` (list with timestamps and descriptions, `--session ID` filter, formatted output)
- [x] T029 [US2] Implement `agent rollback <CHECKPOINT_ID>` subcommand in `src/agent/agent.sh` (validate exists or exit 6, apply stash, log rollback action, update status)
- [x] T030 [US2] Integrate automatic checkpoint creation into agent task launch in `src/agent/agent.sh` (create checkpoint before passing task to backend, log checkpoint action entry; depends on T020 launch implementation)

**Checkpoint**: Checkpoints created automatically, listed, and rolled back. Retention policy enforced.

---

## Phase 5: User Story 3 — Multi-File Coherent Edits (Priority: P1)

**Goal**: Cross-file changes committed atomically with consistency across all affected files

**Independent Test**: Request cross-file refactor, verify all references updated in single atomic commit

### Tests for User Story 3

- [x] T031 [P] [US3] Integration test for multi-file consistency in `tests/integration/test_multi_file_edits.sh` (agent modifies multiple files, all in single commit, no partial commits, descriptive commit message)

### Implementation for User Story 3

- [x] T032 [US3] Configure OpenCode for atomic commits in `src/agent/lib/config.sh` (set git integration options for grouping changes, configure commit message format)
- [x] T033 [US3] Configure Claude Code for atomic commits in `src/agent/lib/config.sh` (set commit grouping behavior in Claude Code settings)
- [x] T034 [US3] Implement post-operation commit verification in `src/agent/agent.sh` (after backend completes, verify changes committed atomically, log files affected)

**Checkpoint**: Agent produces atomic commits for multi-file operations.

---

## Phase 6: User Story 4 — Safe Shell Command Execution (Priority: P2)

**Goal**: Agent runs shell commands with configurable timeouts and forced approval for dangerous patterns

**Independent Test**: Give agent task requiring tests, verify it runs them and responds to dangerous patterns

### Tests for User Story 4

- [x] T035 [P] [US4] Unit test for dangerous pattern detection in `tests/unit/test_shell_safety.bats` (match `rm -rf`, `git push --force`, `chmod 777`; safe commands pass; custom patterns from config)
- [x] T036 [P] [US4] Integration test for command execution safety in `tests/integration/test_shell_execution.sh` (command with timeout, timeout exceeded terminates, dangerous pattern in auto mode still requires approval)

### Implementation for User Story 4

- [x] T037 [US4] Implement shell safety checks in `src/agent/lib/config.sh` (load `dangerous_patterns` array, pattern matching function, timeout configuration)
- [x] T038 [US4] Implement timeout and dangerous pattern enforcement in `src/agent/agent.sh` (wrap execution with timeout, intercept dangerous patterns, force approval regardless of mode)
- [x] T039 [US4] Configure OpenCode tool permissions for shell in `src/agent/lib/provider.sh` (map approval mode to `bash` tool permissions, apply dangerous pattern overrides)

**Checkpoint**: Shell commands respect timeouts, dangerous patterns always require approval.

---

## Phase 7: User Story 5 — Resume Interrupted Session (Priority: P2)

**Goal**: Sessions persist across container restarts and resume with full context

**Independent Test**: Start session, terminate mid-task, restart, verify context preserved on resume

### Tests for User Story 5

- [x] T040 [P] [US5] Unit test for session metadata CRUD in `tests/unit/test_session.bats` (create JSON, update status, list, load, handle corrupted file)
- [x] T041 [P] [US5] Integration test for session persistence in `tests/integration/test_session_persistence.sh` (start > terminate > restart > resume > verify context)

### Implementation for User Story 5

- [x] T042 [US5] Implement session metadata management in `src/agent/lib/session.sh` (create JSON per schema, status transitions, list by status, corruption detection, store at `$AGENT_STATE_DIR/sessions/{uuid}.json`)
- [x] T043 [US5] Implement `agent sessions` subcommand in `src/agent/agent.sh` (`--status` filter, show id/backend/started_at/status/task_description)
- [x] T044 [US5] Implement `agent --resume` flag in `src/agent/agent.sh` (find recent active/paused session, load metadata, pass `--continue` to Claude Code or resume for OpenCode, exit 5 if none)
- [x] T045 [US5] Implement `agent status` subcommand in `src/agent/agent.sh` (current session: status, backend, task, duration, checkpoint count, token usage)
- [x] T046 [US5] Integrate session lifecycle into agent launch in `src/agent/agent.sh` (create on task start, update on completion/failure, persist on SIGTERM/SIGINT via trap)

**Checkpoint**: Sessions persist to volume, resume after restart with full context.

---

## Phase 8: User Story 7 — Configurable Approval Modes (Priority: P2)

**Goal**: Manual/auto/hybrid modes map correctly to each backend's native permission system

**Independent Test**: Run same task in each mode, verify manual blocks, auto proceeds, hybrid blocks only risky ops

### Tests for User Story 7

- [x] T047 [P] [US7] Unit test for approval mode config in `tests/unit/test_config.bats` (parse from flag/env/config, validate enum, merge precedence: flag > env > project > global)
- [x] T048 [P] [US7] Contract test for approval mode mapping in `tests/contract/test_cli_interface.bats` (verify `--mode manual` generates correct flags, hybrid generates per-tool permissions)

### Implementation for User Story 7

- [x] T049 [US7] Implement approval mode mapping for OpenCode in `src/agent/lib/provider.sh` (manual: `"*": "ask"`, auto: `"*": "allow"`, hybrid: per-tool from config, write before launch)
- [x] T050 [US7] Implement approval mode mapping for Claude Code in `src/agent/lib/provider.sh` (manual: default, auto: `--dangerously-skip-permissions`, hybrid: `.claude/settings.json` policies)
- [x] T051 [US7] Wire approval mode through launch flow in `src/agent/agent.sh` (read from `--mode` / `AGENT_MODE` / config, pass to provider mapping, log in session metadata)

**Checkpoint**: All three approval modes correctly configure backend tools.

---

## Phase 9: User Story 6 — Delegate Sub-Tasks in Parallel (Priority: P2)

**Goal**: Agent spawns sub-agents for parallel work with non-overlapping file scopes and merged results

**Independent Test**: Assign task with parallel components, verify simultaneous execution with coherent merge

### Tests for User Story 6

- [x] T052 [P] [US6] Integration test for sub-agent delegation in `tests/integration/test_sub_agents.sh` (spawn parallel sub-agents, verify non-overlapping scopes, verify merge, verify action log events)

### Implementation for User Story 6

- [x] T053 [US6] Implement sub-agent spawning and coordination in `src/agent/agent.sh` (detect Claude Code for native sub-agent support, spawn parallel instances with file scope, wait, merge results)
- [x] T054 [US6] Add sub-agent action log entries in `src/agent/lib/log.sh` (log `sub_agent_spawn` and `sub_agent_complete` with ID and scope)

**Checkpoint**: Sub-agents spawn in parallel with non-overlapping scopes, results merge.

---

## Phase 10: User Story 8 — Background Task Management (Priority: P3)

**Goal**: Start and manage background processes without blocking primary agent work

**Independent Test**: Start dev server, agent makes changes concurrently, both operate independently

### Tests for User Story 8

- [x] T055 [P] [US8] Integration test for background tasks in `tests/integration/test_background_tasks.sh` (start process, verify running, list all, stop specific, verify stopped)

### Implementation for User Story 8

- [x] T056 [US8] Implement background task tracking in `src/agent/lib/session.sh` (start with nohup, capture PID, track in session, output to `$AGENT_STATE_DIR/bg/{id}.log`, monitor status)
- [x] T057 [US8] Implement `agent bg` subcommand in `src/agent/agent.sh` (list with PID/command/uptime, `--kill ID` terminates, verify stopped)

**Checkpoint**: Background tasks start, list, and stop independently of agent workflow.

---

## Phase 11: User Story 9 — Track Usage and Costs (Priority: P3)

**Goal**: Token counts and estimated costs visible per session

**Independent Test**: Complete a task, verify usage displays accurate tokens and cost

### Tests for User Story 9

- [x] T058 [P] [US9] Unit test for token usage aggregation in `tests/unit/test_usage.bats` (parse counts from tool output, compute costs, aggregate across session)

### Implementation for User Story 9

- [x] T059 [US9] Implement token usage aggregation in `src/agent/lib/usage.sh` (parse OpenCode and Claude Code output for metrics, compute cost from pricing table, update session metadata)
- [x] T060 [US9] Implement `agent usage` subcommand in `src/agent/agent.sh` (display input/output/total tokens, cost USD, model, provider, `--session ID`, `--format json|text`)

**Checkpoint**: Usage metrics tracked and displayed per session.

---

## Phase 12: User Story 10 — Extensibility via Protocol Integration (Priority: P3)

**Goal**: Agent integrates with external tools via MCP for additional capabilities

**Independent Test**: Configure MCP server, verify agent invokes it, verify graceful fallback on failure

### Tests for User Story 10

- [x] T061 [P] [US10] Integration test for MCP integration in `tests/integration/test_mcp_integration.sh` (configure mock MCP server, verify invocation, verify graceful fallback)

### Implementation for User Story 10

- [x] T062 [US10] Implement MCP server configuration in `src/agent/lib/config.sh` (parse MCP definitions from `.agent.json`, translate to OpenCode `mcpServers` format, validate availability)
- [x] T063 [US10] Add MCP configuration support to container in `docker/Dockerfile.agent` (network access for MCP endpoints, document setup)

**Checkpoint**: External tools accessible via MCP with graceful failure handling.

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Quality improvements affecting multiple user stories

- [x] T064 [P] Run shellcheck on all scripts in `src/agent/` and `docker/` and fix warnings
- [x] T065 [P] Add file header comments to all library scripts in `src/agent/lib/` (purpose, version, dependencies)
- [x] T066 Implement credential filtering across all output in `src/agent/lib/log.sh` (API keys never in logs, session metadata, stdout/stderr per FR-013)
- [ ] T067 [P] Validate `docker/Dockerfile.agent` builds on both `linux/amd64` and `linux/arm64`
- [x] T068 [P] Create action log schema validation test in `tests/contract/test_action_log_format.bats` (JSONL matches contract, required fields, valid enums)
- [ ] T069 [P] Run container vulnerability scan on `docker/Dockerfile.agent` output image using `trivy image` or `docker scout cves` and resolve any HIGH/CRITICAL findings
- [ ] T070 Run `quickstart.md` workflows end-to-end and verify all examples function correctly
- [x] T071 Implement provider unavailability pause behavior in `src/agent/agent.sh` (detect errors after retries, pause session, notify with alternatives per FR-020, exit 10)
- [x] T072 [P] Add `--format json` structured output to all subcommands in `src/agent/agent.sh` (errors as JSON on stderr per CLI contract)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Stories (Phases 3-12)**: All depend on Foundational completion
  - P1 stories (US1, US2, US3) can proceed in parallel
  - P2 stories (US4, US5, US6, US7) can proceed in parallel
  - P3 stories (US8, US9, US10) can proceed in parallel
- **Polish (Phase 13)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: Start Session — No dependencies on other stories. **MVP**.
- **US2 (P1)**: Checkpoints — Independent (checkpoint lib is self-contained). Note: T030 depends on T020 (launch must exist before checkpoint integrates into it)
- **US3 (P1)**: Multi-File Edits — Independent (config-driven)
- **US4 (P2)**: Shell Execution — Independent (shell safety is config-driven)
- **US5 (P2)**: Session Resume — Independent (session lib is self-contained)
- **US6 (P2)**: Sub-Tasks — Benefits from US7 (approval modes) but implementable independently
- **US7 (P2)**: Approval Modes — Independent (pure config mapping)
- **US8 (P3)**: Background Tasks — Uses session tracking from `src/agent/lib/session.sh` (built in US5, but session.sh core is in Foundational scope)
- **US9 (P3)**: Usage Tracking — Independent (usage lib is self-contained)
- **US10 (P3)**: Protocol Integration — Independent (MCP is config-driven)

### Within Each User Story

- Tests written and FAIL before implementation
- Library modules before agent.sh integration
- Core implementation before subcommands
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 1**: T002, T003, T004 all in parallel
- **Phase 2 Tests**: T005, T006, T007, T008 all in parallel
- **Phase 2 Impl**: T010, T011, T012, T014, T015, T016 in parallel (T009/T013 sequential first)
- **After Phase 2**: All P1 stories (US1, US2, US3) in parallel
- **After P1**: All P2 stories (US4, US5, US6, US7) in parallel
- **After P2**: All P3 stories (US8, US9, US10) in parallel
- Within each story: Test tasks marked [P] run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch tests in parallel:
Task: "Contract test for CLI startup in tests/contract/test_cli_interface.bats"
Task: "Integration test for container startup in tests/integration/test_container_startup.sh"

# After tests fail (expected), implement sequentially:
Task: "Implement provider validation and backend launch in src/agent/agent.sh"
Task: "Implement headless server mode in src/agent/agent.sh"
Task: "Implement agent config --validate subcommand in src/agent/agent.sh"
Task: "Add API key validation integration test in tests/integration/test_api_key_validation.sh"
```

## Parallel Example: User Story 2

```bash
# Launch tests in parallel:
Task: "Unit test for checkpoint operations in tests/unit/test_checkpoint.bats"
Task: "Integration test for checkpoint lifecycle in tests/integration/test_checkpoint_ops.sh"

# After tests fail, implement library then subcommands:
Task: "Implement checkpoint creation in src/agent/lib/checkpoint.sh"
Task: "Implement retention policy in src/agent/lib/checkpoint.sh"
Task: "Implement agent checkpoints subcommand in src/agent/agent.sh"
Task: "Implement agent rollback subcommand in src/agent/agent.sh"
Task: "Integrate automatic checkpoint into agent launch in src/agent/agent.sh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (Start Autonomous Session)
4. **STOP and VALIDATE**: Build container, start agent with API key, verify task runs headlessly
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready (script parses args, container builds with pinned versions)
2. US1 → Agent starts and runs tasks → **MVP!**
3. US2 → Checkpoints and rollback → Safety net
4. US3 → Atomic commits → Coherent multi-file changes
5. US4 → Shell safety → Timeout and dangerous pattern protection
6. US5 → Session resume → Survive restarts
7. US7 → Approval modes → manual/auto/hybrid control
8. US6 → Sub-agents → Parallel execution
9. US8 → Background tasks → Dev server management
10. US9 → Usage tracking → Cost visibility
11. US10 → MCP integration → Extensibility

### Parallel Team Strategy

With multiple developers after Foundational:

- Developer A: US1 (core launch) + US4 (shell safety) + US8 (background tasks)
- Developer B: US2 (checkpoints) + US5 (sessions) + US9 (usage)
- Developer C: US3 (multi-file) + US7 (approval modes) + US6 (sub-agents) + US10 (MCP)

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story independently completable and testable after Phase 2
- Tests written first and must FAIL before implementing
- Commit after each task or logical group
- All scripts must pass `shellcheck` before merging
- Container builds multi-arch (arm64 + amd64) with pinned versions (no `:latest`)
- Wrapper script sources lib modules — lib/*.sh changes are isolated
- State directory standardized as `$AGENT_STATE_DIR` (env: `AGENT_STATE_DIR`, default: `~/.local/share/agent/`)
