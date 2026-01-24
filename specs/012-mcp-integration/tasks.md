# Tasks: MCP Integration for AI Agent Capabilities

**Input**: Design documents from `/specs/012-mcp-integration/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Tests are included as the project constitution mandates test-first development (Principle III). Foundational script tests appear BEFORE script implementation in Phase 2.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- MCP scripts: `src/mcp/`
- Docker files: `docker/`
- Default configs: `src/mcp/defaults/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [x] T001 Create MCP scripts directory structure: `src/mcp/`, `src/mcp/defaults/`
- [x] T002 [P] Create test directory structure: `tests/unit/`, `tests/integration/`, `tests/contract/` (if not present)
- [x] T003 [P] Verify BATS test framework available in `tests/bats/` (install if missing)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

### Dockerfile & Dependencies

- [x] T004 Add Node.js 22.x LTS installation stage to `docker/Dockerfile` (via NodeSource apt repo)
- [x] T005 Configure NPM_CONFIG_PREFIX for non-root user and add to PATH in `docker/Dockerfile`
- [x] T006 Install `python3-yaml` package in `docker/Dockerfile` for YAML generation (Continue config output)
- [x] T007 Add `npm install -g` for core MCP packages (server-filesystem@2026.1.14, server-memory, server-sequential-thinking, context7-mcp@2.1.0) with pinned versions in `docker/Dockerfile`
- [x] T008 Add `npm install -g` for optional MCP packages (server-github@2026.1.14, playwright/mcp@0.0.28) with pinned versions in `docker/Dockerfile`
- [x] T009 Add `pip install --no-cache-dir mcp-server-git` to `docker/Dockerfile`
- [x] T010 Create complete default MCP source configuration at `src/mcp/defaults/mcp-config.json` with ALL server entries per contracts/mcp-source-config.md (core servers enabled, optional servers disabled, all npx versions pinned)

### Foundational Tests (MUST precede script implementation per Constitution Principle III)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementing scripts**

- [x] T011 [P] Unit test for config parsing and enabled/disabled filtering in `tests/unit/test_config_generation.bats` — verify only `enabled: true` servers appear in output, disabled are excluded
- [x] T012 [P] Unit test for environment variable substitution in `tests/unit/test_env_substitution.bats` — verify `${VAR_NAME}` replaced with actual values, missing vars produce warnings
- [x] T013 [P] Unit test for credential redaction in `tests/unit/test_mcp_security.bats` — verify no credential values appear in script stderr output, only variable names logged
- [x] T014 [P] Unit test for multi-format output in `tests/unit/test_config_generation.bats` — verify Claude Code JSON object, Cline JSON with `disabled`/`autoApprove`, Continue YAML array formats
- [x] T015 [P] Unit test for merge behavior in `tests/unit/test_config_generation.bats` — verify existing `.claude/settings.local.json` keys (e.g., `permissions`) preserved when merging `mcpServers`

### Script Implementation

- [x] T016 Implement `src/mcp/validate-mcp.sh` — check Node.js version, verify server binaries on PATH, validate config JSON, check required env vars, credential-safe logging
- [x] T017 Implement `src/mcp/generate-configs.sh` — parse source config, filter enabled servers, substitute `${VAR_NAME}` env vars via jq, generate all three tool-native formats (Claude Code with merge, Cline, Continue YAML via python3), set 0600 permissions on output, credential-safe logging
- [x] T018 Add MCP initialization hook to `docker/entrypoint.sh` — call validate-mcp.sh then generate-configs.sh after volume validation, before exec
- [x] T019 Copy default config and scripts into container image in `docker/Dockerfile` (COPY src/mcp/ to /home/dev/.mcp/)
- [x] T020 Create `~/.local/share/mcp-memory/` directory in `docker/Dockerfile` for memory volume mount point

**Checkpoint**: Foundation ready — Dockerfile builds with MCP packages, foundational tests pass, entrypoint runs validation and config generation

---

## Phase 3: User Story 1 - AI Agent Accesses Project Files (Priority: P1)

**Goal**: Filesystem MCP server provides secure file access within allowed workspace directories

**Independent Test**: Start container, verify AI tool can read files from /workspace, verify path traversal is blocked

### Tests for User Story 1

- [x] T021 [P] [US1] Integration test for filesystem server availability in `tests/integration/test_mcp_startup.sh` — build container, verify `mcp-server-filesystem` binary exists and is executable
- [x] T022 [P] [US1] Security test for directory allowlist enforcement in `tests/unit/test_security.bats` — verify generated config only includes explicitly allowed directories, no additional paths

### Implementation for User Story 1

- [x] T023 [US1] Verify filesystem server entry in default config (`src/mcp/defaults/mcp-config.json`) has correct `/workspace` arg and `enabled: true`
- [x] T024 [US1] Add filesystem-specific validation in `src/mcp/validate-mcp.sh` — report OK when `mcp-server-filesystem` binary found on PATH
- [x] T025 [US1] Add acceptance test: container starts, filesystem server available, agent can list files in /workspace in `tests/integration/test_mcp_startup.sh`
- [x] T026 [US1] Add acceptance test: file request outside allowed directories returns permission error in `tests/integration/test_mcp_startup.sh`
- [x] T026b [US1] Add security test: symlink inside /workspace pointing to /etc/passwd is not followed by filesystem MCP server (FR-003 symlink escape) in `tests/integration/test_mcp_startup.sh`

**Checkpoint**: Filesystem MCP server is available in container, directory allowlist enforced, path traversal and symlink escape blocked

---

## Phase 4: User Story 2 - AI Agent Retrieves Current Documentation (Priority: P1)

**Goal**: Context7 MCP server provides current library documentation to AI agents

**Independent Test**: Start container with CONTEXT7_API_KEY set, verify Context7 server appears in generated tool configs

### Tests for User Story 2

- [x] T027 [P] [US2] Unit test for Context7 credential warning in `tests/unit/test_env_substitution.bats` — verify warning logged when CONTEXT7_API_KEY unset but server enabled, no failure

### Implementation for User Story 2

- [x] T028 [US2] Verify Context7 entry in default config (`src/mcp/defaults/mcp-config.json`) has `${CONTEXT7_API_KEY}` env reference, pinned npx version, and `enabled: true`
- [x] T029 [US2] Add Context7-specific validation in `src/mcp/validate-mcp.sh` — report WARN if API key missing, OK if set
- [x] T030 [US2] Add acceptance test: container starts without Context7 key, warning shown, other servers still functional in `tests/integration/test_mcp_startup.sh`

**Checkpoint**: Context7 server configured, graceful handling of missing credentials, documentation lookup available when key provided

---

## Phase 5: User Story 3 - Secure Credential Configuration (Priority: P1)

**Goal**: Credentials are injected via environment variables, never stored in config files, never logged

**Independent Test**: Start container with env vars set, verify generated configs contain resolved values, verify no credentials in log output

### Tests for User Story 3

- [x] T031 [P] [US3] Unit test for special character handling in `tests/unit/test_env_substitution.bats` — verify env var values with quotes, newlines, and special chars are correctly JSON-escaped in output
- [x] T032 [P] [US3] Security test for generated file permissions in `tests/unit/test_security.bats` — verify generated config files have 0600 permissions when containing resolved credentials

### Implementation for User Story 3

- [x] T033 [US3] Add special character handling test cases to `src/mcp/generate-configs.sh` edge case coverage — ensure jq JSON escaping handles quotes, newlines, backslashes in env var values
- [x] T034 [US3] Add acceptance test: verify source config uses `${...}` syntax, generated config contains resolved values, logs contain neither in `tests/integration/test_mcp_startup.sh`
- [x] T035 [US3] Add acceptance test: verify generated config files have restrictive permissions (0600) in `tests/integration/test_mcp_startup.sh`

**Checkpoint**: Environment variable substitution works correctly, credentials never exposed in config files or logs, file permissions secured

---

## Phase 6: User Story 4 - AI Agent Uses Memory Across Sessions (Priority: P2)

**Goal**: Memory MCP server persists knowledge graph across container restarts via Docker named volume

**Independent Test**: Start container, store a memory entity, restart container, verify entity is retrievable

### Tests for User Story 4

- [x] T036 [P] [US4] Unit test for memory server config in `tests/unit/test_config_generation.bats` — verify MEMORY_FILE_PATH env var points to `/home/dev/.local/share/mcp-memory/memory.json`
- [x] T037 [P] [US4] Integration test for memory volume in `tests/integration/test_mcp_startup.sh` — verify volume directory exists and is writable by non-root user

### Implementation for User Story 4

- [x] T038 [US4] Verify memory server entry in default config (`src/mcp/defaults/mcp-config.json`) has correct MEMORY_FILE_PATH and `enabled: true`
- [x] T039 [US4] Add `mcp-memory` named volume to `docker/docker-compose.yml` mounted at `/home/dev/.local/share/mcp-memory`
- [x] T040 [US4] Add memory volume validation in `src/mcp/validate-mcp.sh` — check directory writable when memory server enabled
- [x] T041 [US4] Add `/home/dev/.local/share/mcp-memory` to `docker/entrypoint.sh` VOLUME_DIRS array for permission fixing
- [x] T042 [US4] Add acceptance test: write to memory file, restart container with same volume, verify file contents preserved in `tests/integration/test_mcp_startup.sh`

**Checkpoint**: Memory server persists across container restarts, volume permissions correct, graceful failure when storage unavailable

---

## Phase 7: User Story 5 - MCP Configuration Management (Priority: P2)

**Goal**: Developers can enable/disable servers and add custom servers by editing `.mcp/config.json`

**Independent Test**: Toggle a server's enabled flag, regenerate configs, verify the server appears/disappears from tool configs

### Tests for User Story 5

- [x] T043 [P] [US5] Unit test for custom server addition in `tests/unit/test_config_generation.bats` — verify new server entry with custom name generates correctly in all three tool formats
- [x] T044 [P] [US5] Contract test for source config schema validation in `tests/contract/test_config_schema.bats` — verify invalid JSON produces clear error, missing `command` field rejected, invalid server names rejected

### Implementation for User Story 5

- [x] T045 [US5] Add `--source` flag to `src/mcp/generate-configs.sh` for custom config path (default: /workspace/.mcp/config.json)
- [x] T046 [US5] Add fallback logic in `src/mcp/generate-configs.sh` — if workspace config missing, copy default from /home/dev/.mcp/defaults/mcp-config.json to workspace
- [x] T047 [US5] Add JSON schema validation in `src/mcp/validate-mcp.sh` — check required fields, valid server names pattern `^[a-z][a-z0-9-]*$`, valid env var name patterns
- [x] T048 [US5] Add `--dry-run` flag to `src/mcp/generate-configs.sh` — print generated configs to stdout without writing files
- [x] T049 [US5] Add clear error messaging for invalid JSON in `src/mcp/generate-configs.sh` — report parse error with jq error output
- [x] T050 [US5] Add acceptance test: disable a server in config, run generate-configs.sh, verify server absent from all tool configs in `tests/integration/test_mcp_startup.sh`
- [x] T051 [US5] Add acceptance test: add custom server entry to config, run generate-configs.sh, verify it appears in all tool configs in `tests/integration/test_mcp_startup.sh`

**Checkpoint**: Developers can customize MCP server set via config file, invalid configs produce clear errors, changes take effect on regeneration

---

## Phase 8: User Story 6 - Optional Servers Available On-Demand (Priority: P3)

**Goal**: Pre-installed optional servers (GitHub, Git, Playwright) can be enabled via config change without image rebuild

**Independent Test**: Enable GitHub MCP server in config, regenerate, verify it appears in tool configs without requiring downloads

### Tests for User Story 6

- [x] T052 [P] [US6] Integration test for optional server binaries in `tests/integration/test_mcp_startup.sh` — verify `npx @modelcontextprotocol/server-github --help` and `python3 -m mcp_server_git --help` succeed without downloads

### Implementation for User Story 6

- [x] T053 [US6] Verify optional server entries in default config (`src/mcp/defaults/mcp-config.json`) — github, git, playwright all present with `enabled: false` and pinned versions
- [x] T054 [US6] Add Playwright build arg `INSTALL_PLAYWRIGHT_BROWSER` to `docker/Dockerfile` for opt-in Chromium installation
- [x] T055 [US6] Add acceptance test: enable github server in config, regenerate, verify immediate availability (no network downloads triggered) in `tests/integration/test_mcp_startup.sh`

**Checkpoint**: All optional servers pre-installed, enabling requires only config change, no runtime downloads needed

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and gap coverage

### CLI Flags & Usability

- [x] T056 [P] Add `--json` output mode to `src/mcp/validate-mcp.sh` per contracts/config-generation.md
- [x] T057 [P] Add `--quiet` flag to both `src/mcp/validate-mcp.sh` and `src/mcp/generate-configs.sh`
- [x] T058 [P] Add `--help` usage output to both `src/mcp/validate-mcp.sh` and `src/mcp/generate-configs.sh`

### Quality & Compliance

- [x] T059 [P] Add shellcheck linting pass for `src/mcp/generate-configs.sh` and `src/mcp/validate-mcp.sh` — zero warnings required
- [x] T060 Verify Dockerfile builds successfully on both arm64 and amd64 via `docker buildx build --platform linux/arm64,linux/amd64`
- [x] T061 [P] Verify total image size increase is under 150MB budget — run `docker images` comparison before/after MCP layer

### Coverage Gaps (FR-009, SC-004, SC-007)

- [x] T062 [US5] Create user-facing documentation for adding custom MCP servers at `src/mcp/defaults/README.md` — copied into container, covers config format, examples, and troubleshooting (FR-009)
- [x] T063 Add performance validation test in `tests/integration/test_mcp_startup.sh` — measure time from container start to config generation complete, assert under 30 seconds (SC-004)
- [x] T064 Add multi-tool config format validation test in `tests/contract/test_config_schema.bats` — verify generated Claude Code, Cline, and Continue configs are structurally valid for their respective tools (SC-007)

### Final Validation

- [x] T065 Run full quickstart.md validation end-to-end in a clean container — all steps must succeed without errors

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US1, US2, US3 (P1): Can proceed in parallel after Phase 2
  - US4, US5 (P2): Can proceed in parallel after Phase 2, independent of P1 stories
  - US6 (P3): Can proceed after Phase 2, benefits from US5 being complete (for enable/disable testing)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (Filesystem)**: After Phase 2 — no cross-story dependencies
- **US2 (Documentation)**: After Phase 2 — no cross-story dependencies
- **US3 (Credentials)**: After Phase 2 — no cross-story dependencies (core env sub in Phase 2, US3 covers edge cases)
- **US4 (Memory)**: After Phase 2 — no cross-story dependencies
- **US5 (Config Management)**: After Phase 2 — enhances all stories but independently testable
- **US6 (Optional Servers)**: After Phase 2 — benefits from US5 for enable/disable flow

### Within Phase 2 (TDD Compliance)

1. Dockerfile + config creation (T004-T010) — infrastructure, no TDD needed
2. Foundational tests written and verified to FAIL (T011-T015)
3. Script implementation to make tests PASS (T016-T017)
4. Integration into entrypoint (T018-T020)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Verification of default config entries before validation logic
- Validation before acceptance tests

### Parallel Opportunities

- T001, T002, T003 (Setup) can all run in parallel
- T004-T010 (Dockerfile + default config) are sequential (layered build)
- T011-T015 (foundational tests) can ALL run in parallel
- T016-T017 (scripts) are sequential (validate before generate)
- All P1 user stories (US1, US2, US3) can run in parallel after Phase 2
- All P2 user stories (US4, US5) can run in parallel after Phase 2
- Within each story, test tasks marked [P] can run in parallel

---

## Parallel Example: Phase 2 Tests

```bash
# Launch all foundational tests together (they test different concerns):
Task: "Unit test for config parsing and filtering in tests/unit/test_config_generation.bats"
Task: "Unit test for env var substitution in tests/unit/test_env_substitution.bats"
Task: "Unit test for credential redaction in tests/unit/test_security.bats"
Task: "Unit test for multi-format output in tests/unit/test_config_generation.bats"
Task: "Unit test for merge behavior in tests/unit/test_config_generation.bats"
```

## Parallel Example: P1 Stories (US1 + US2 + US3)

```bash
# After Phase 2 completes, launch all three P1 stories simultaneously:
# Agent A: User Story 1 (Filesystem) — T021-T026
# Agent B: User Story 2 (Documentation) — T027-T030
# Agent C: User Story 3 (Credentials) — T031-T035
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (Dockerfile + tests + scripts + entrypoint)
3. Complete Phase 3: User Story 1 (Filesystem access)
4. **STOP and VALIDATE**: Build container, start AI tool, verify file reading works
5. Demo: AI agent can read project files securely

### Incremental Delivery

1. Setup + Foundational → Container builds with MCP packages, config generation works
2. Add US1 (Filesystem) → AI agents can access files (MVP!)
3. Add US2 (Documentation) → AI agents get current docs
4. Add US3 (Credentials) → Edge case hardening for env vars
5. Add US4 (Memory) → Persistent context across sessions
6. Add US5 (Config Management) → Customizable server set with fallbacks
7. Add US6 (Optional Servers) → GitHub, Git, Playwright available
8. Polish → CLI flags, multi-arch verification, size budget, coverage gaps

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (Filesystem) + US4 (Memory)
   - Developer B: US2 (Documentation) + US5 (Config Management)
   - Developer C: US3 (Credentials) + US6 (Optional Servers)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Phase 2 tests MUST fail before script implementation begins (TDD per constitution)
- T010 creates the COMPLETE default config (all servers) — US phases verify/validate entries, not create them
- Core env var substitution and credential redaction are in Phase 2 (T017); US3 covers edge cases only
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
