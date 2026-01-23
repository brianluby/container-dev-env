# Tasks: Terminal AI Agent

**Input**: Design documents from `/specs/005-terminal-ai-agent/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Integration tests included per user story (constitution requires test-driven verification).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create project file structure and helper scripts

- [x] T001 Create directory structure: `src/docker/`, `src/chezmoi/dot_config/opencode/`, `src/scripts/`, `tests/integration/`, `tests/contract/`
- [x] T002 [P] Create SHA256 verification helper script at `src/scripts/opencode-verify.sh` that validates binary checksum for both amd64 and arm64
- [x] T003 [P] Create test runner script at `tests/run-tests.sh` that executes all integration tests and reports pass/fail

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Install OpenCode binary in the container image — MUST complete before any user story can be verified

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Add OpenCode binary download stage to Dockerfile at `src/docker/Dockerfile` with ARGs for OPENCODE_VERSION, OPENCODE_SHA256_AMD64, OPENCODE_SHA256_ARM64, and TARGETARCH-based download
- [x] T005 Add SHA256 checksum verification step to Dockerfile at `src/docker/Dockerfile` that fails the build on mismatch
- [x] T006 Add binary chmod and PATH setup to Dockerfile at `src/docker/Dockerfile` installing to `/usr/local/bin/opencode`
- [x] T007 Create Chezmoi config template at `src/chezmoi/dot_config/opencode/config.yaml.tmpl` with provider/model fields reading from env vars (`{{ env "OPENCODE_PROVIDER" }}` / `{{ env "OPENCODE_MODEL" }}`), falling back to empty string (agent must fail with exit code 2 and descriptive error when both are empty at startup). Additional settings: auto_commit=true, commit_style=conventional, session.persist=true, session.path=~/.local/share/opencode/sessions/, shell.approval_required=true, timeout=60, retries=1
- [x] T008 [P] Create environment variable contract test at `tests/contract/test_env_vars.sh` verifying at least one API key env var is set and keys are not visible in process args
- [x] T009 [P] Create install verification test at `tests/integration/test_opencode_install.sh` checking binary exists, is executable, returns version, and matches container architecture
- [x] T032 [P] Create timeout configuration test at `tests/integration/test_opencode_timeout.sh` verifying: (1) rendered config contains timeout=60 and retries=1, (2) agent exits with clear error message when pointed at an unreachable provider endpoint (use a non-routable IP like 10.255.255.1 as provider URL)

**Checkpoint**: OpenCode binary installed and verified in container. Integration tests confirm binary is present and architecture-correct.

---

## Phase 3: User Story 1 - Generate Code from Natural Language (Priority: P1) MVP

**Goal**: Developer can start the agent, request code generation, and get syntactically valid code proposed for review

**Independent Test**: Start agent with mock API key, request a simple function, verify output is syntactically valid code

### Integration Test for User Story 1

- [x] T010 [US1] Create startup integration test at `tests/integration/test_opencode_startup.sh` verifying agent is ready to accept input within 3 seconds when API key env var is set, and exits with code 2 and descriptive error when key is missing

### Implementation for User Story 1

- [x] T011 [US1] Verify Dockerfile config enables code generation mode by default (agent.mode=build in config template) at `src/chezmoi/dot_config/opencode/config.yaml.tmpl`
- [x] T012 [US1] Verify Chezmoi template reads OPENCODE_PROVIDER and OPENCODE_MODEL from environment at `src/chezmoi/dot_config/opencode/config.yaml.tmpl`

**Checkpoint**: Agent starts, reads API key from env, accepts prompts. Code generation mode enabled by default.

---

## Phase 4: User Story 2 - Auto-Commit Approved Changes (Priority: P2)

**Goal**: After developer approves code changes, a clean git commit is created with a conventional commit message on the current branch

**Independent Test**: Approve a code change and verify git log contains a new commit with conventional format message

### Integration Test for User Story 2

- [x] T013 [US2] Create git integration test at `tests/integration/test_opencode_git.sh` verifying auto-commit creates commits with conventional format messages and commits are on the currently checked-out branch

### Implementation for User Story 2

- [x] T014 [US2] Verify config template sets agent.auto_commit=true and agent.commit_style=conventional at `src/chezmoi/dot_config/opencode/config.yaml.tmpl`

**Checkpoint**: Approved changes auto-commit with conventional messages on current branch.

---

## Phase 5: User Story 3 - Context-Aware Code Understanding (Priority: P3)

**Goal**: Agent reads and searches local project files to answer questions and generate context-aware code

**Independent Test**: Ask agent about project structure in a multi-file project and verify accurate response referencing actual files

### Integration Test for User Story 3

- [x] T015 [US3] Create context awareness smoke test at `tests/integration/test_opencode_context.sh` verifying agent can read files in the current project directory (create a sample file, start agent, confirm agent output references the file's contents or name)

**Checkpoint**: Agent can read/search project files for context. Validated by smoke test confirming file awareness.

---

## Phase 6: User Story 4 - Multi-Language Code Generation (Priority: P4)

**Goal**: Agent generates syntactically valid code in Python, TypeScript, Rust, and Go

**Independent Test**: Request code generation in each language and verify output is syntactically valid

### Integration Test for User Story 4

- [x] T016 [US4] Create multi-language verification test at `tests/integration/test_opencode_languages.sh` verifying agent accepts prompts targeting Python, TypeScript, Rust, and Go files without configuration errors (create minimal project files in each language, start agent, confirm no language-specific failures in stderr)

**Checkpoint**: Agent handles all 4 languages without errors. Validated by multi-language smoke test.

---

## Phase 7: User Story 5 - Resume Previous Sessions (Priority: P5)

**Goal**: Developer can exit and restart the agent, resuming previous conversation context

**Independent Test**: Start session, exit, restart, verify previous context is available

### Integration Test for User Story 5

- [x] T029 [US5] Create session persistence test at `tests/integration/test_opencode_sessions.sh` verifying: (1) session directory exists at `~/.local/share/opencode/sessions/` with 0700 permissions, (2) after agent invocation a session file is created in that directory, (3) session file has 0600 permissions

### Implementation for User Story 5

- [x] T017 [US5] Verify config template sets session.persist=true and session.path to `~/.local/share/opencode/sessions/` at `src/chezmoi/dot_config/opencode/config.yaml.tmpl`
- [x] T018 [US5] Add session directory creation to Dockerfile at `src/docker/Dockerfile` ensuring `~/.local/share/opencode/sessions/` exists with 0700 permissions

**Checkpoint**: Sessions persist to disk and can be resumed after agent restart within same container.

---

## Phase 8: User Story 6 - Track API Usage and Costs (Priority: P6)

**Goal**: Token usage and approximate cost displayed after each operation

**Independent Test**: Complete a task and verify token/cost information is displayed

### Integration Test for User Story 6

- [x] T030 [US6] Create token display verification test at `tests/integration/test_opencode_tokens.sh` verifying agent output includes token count (grep for "tokens" or equivalent usage indicator in stdout/stderr after a completed operation)

### Implementation for User Story 6

- [x] T019 [US6] No additional configuration needed — OpenCode displays token usage by default. Verify expected output format matches `specs/005-terminal-ai-agent/contracts/cli-interface.md`.

**Checkpoint**: Token usage visible after operations. Validated by smoke test confirming usage output.

---

## Phase 9: User Story 7 - Execute Shell Commands with Approval (Priority: P7)

**Goal**: Agent proposes shell commands and waits for explicit developer approval before execution

**Independent Test**: Request a task requiring a shell command, verify agent asks for approval before executing

### Integration Test for User Story 7

- [x] T031 [US7] Create shell approval test at `tests/integration/test_opencode_shell.sh` verifying: (1) config contains shell.approval_required=true after Chezmoi template rendering, (2) agent does not execute shell commands in non-interactive mode without approval (verify no command output when approval is not provided)

### Implementation for User Story 7

- [x] T020 [US7] Verify config template sets shell.approval_required=true at `src/chezmoi/dot_config/opencode/config.yaml.tmpl`

**Checkpoint**: Shell commands require explicit approval. Safety gate active by default.

---

## Phase 10: File Conflict Detection (From Clarifications)

**Goal**: Agent detects when target files have been modified since last read and warns developer

**Independent Test**: Modify a file externally while agent has proposed changes, verify warning is shown

### Integration Test

- [x] T021 Create file conflict detection test at `tests/integration/test_opencode_conflict.sh` verifying agent warns when a file has been modified between read and proposed write

### Implementation

- [x] T022 Verify OpenCode supports file modification detection natively. If not, document as known limitation and create wrapper approach in `src/scripts/opencode-verify.sh`

**Checkpoint**: File conflicts detected and warned before overwrite.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, security hardening, and final validation

- [x] T023 [P] Update `specs/005-terminal-ai-agent/quickstart.md` with actual OpenCode version number and verified commands
- [x] T024 [P] Verify session history files have 0600 permissions in `tests/integration/test_opencode_install.sh` (extend existing test)
- [x] T025 [P] Verify API keys are not present in agent process arguments in `tests/contract/test_env_vars.sh` (extend existing test)
- [ ] T026 Run full integration test suite via `tests/run-tests.sh` and verify all tests pass
- [ ] T027 Build container on both amd64 and arm64 architectures and verify `opencode --version` succeeds on each
- [ ] T028 Validate quickstart.md end-to-end: follow all steps in a fresh container and verify they work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Stories (Phase 3-9)**: All depend on Foundational phase completion
  - US1-US7 can proceed in parallel after Phase 2 (they configure the same tool differently)
  - In practice, sequential order (P1→P7) is recommended since later stories build on earlier verification
- **File Conflict (Phase 10)**: Depends on Foundational; independent of user stories
- **Polish (Phase 11)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 only — no dependencies on other stories
- **User Story 2 (P2)**: Depends on Phase 2 only — git config is independent of code gen
- **User Story 3 (P3)**: Depends on Phase 2 only — context awareness is built-in
- **User Story 4 (P4)**: Depends on Phase 2 only — multi-language is built-in
- **User Story 5 (P5)**: Depends on Phase 2 only — session config is independent
- **User Story 6 (P6)**: Depends on Phase 2 only — cost display is built-in
- **User Story 7 (P7)**: Depends on Phase 2 only — shell approval is config-based
- **File Conflict (Phase 10)**: Depends on Phase 2 only — detection is tool-level

### Within Each User Story

- Integration test defines expected behavior
- Configuration verified/added to match expected behavior
- Story complete when test passes

### Parallel Opportunities

- T002, T003 can run in parallel (different files, Phase 1)
- T008, T009, T032 can run in parallel (different test files, Phase 2)
- All user story phases (3-9) can theoretically run in parallel after Phase 2
- T023, T024, T025 can run in parallel (different files, Phase 11)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Sequential (Dockerfile must be built in order):
Task T004: "Add binary download stage to src/docker/Dockerfile"
Task T005: "Add SHA256 verification to src/docker/Dockerfile"
Task T006: "Add chmod and PATH to src/docker/Dockerfile"
Task T007: "Create Chezmoi config template"

# Parallel (independent test files):
Task T008: "Create env var contract test in tests/contract/test_env_vars.sh"
Task T009: "Create install verification test in tests/integration/test_opencode_install.sh"
Task T032: "Create timeout configuration test in tests/integration/test_opencode_timeout.sh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (file structure, scripts)
2. Complete Phase 2: Foundational (Dockerfile binary install, config template)
3. Complete Phase 3: User Story 1 (startup test, verify code gen mode)
4. **STOP and VALIDATE**: Build container, run `opencode --version`, verify startup with API key
5. Deploy container image if ready

### Incremental Delivery

1. Setup + Foundational → Binary installed, config delivered
2. US1 (Code Gen) → Agent starts, accepts prompts → **MVP ready**
3. US2 (Auto-Commit) → Git integration verified
4. US3-US4 (Context + Multi-Lang) → Built-in, just verify
5. US5 (Sessions) → Persistence configured
6. US6-US7 (Cost + Shell) → Built-in/configured
7. Phase 10-11 → Conflict detection, polish, security

### Key Insight

Most user stories are satisfied by OpenCode's built-in features. The primary implementation work is:
1. **Dockerfile** (T004-T006): Install the binary with integrity verification
2. **Config template** (T007): Set correct defaults for all behaviors
3. **Integration tests** (T008-T013, T015-T016, T021, T029-T032): Verify each behavior works in container
4. **Polish** (T023-T028): Documentation, security, multi-arch validation

---

## Notes

- This feature installs a pre-built binary — no application code is written
- Most tasks verify configuration rather than implementing logic
- The Chezmoi config template (T007) is the single source of behavioral configuration
- Tests verify the binary + config produce expected behavior in the container
- The Dockerfile changes (T004-T006) are sequential (build order matters)
- Constitution compliance: TDD spirit followed via integration tests verifying behavior before relying on it
