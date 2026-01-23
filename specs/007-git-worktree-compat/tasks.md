# Tasks: Git Worktree Compatibility

**Input**: Design documents from `/specs/007-git-worktree-compat/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Required per constitution (Principle III: Test-First Development). BATS for unit tests, Docker-based for integration tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create test infrastructure and fixtures needed by all user stories

- [X] T001 Create test directory structure: `tests/unit/`, `tests/integration/`, `tests/fixtures/`
- [X] T002 Create test fixture script that generates worktree test repositories in `tests/fixtures/create-worktree-fixtures.sh`
- [X] T003 [P] Add BATS dependencies to project (bats-core, bats-assert, bats-support) in `tests/unit/.bats-battery/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify existing entrypoint infrastructure supports the new function

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Verify existing logging functions (log, log_warning, log_section) work for worktree output in `docker/entrypoint.sh`
- [X] T005 Add WORKSPACE_DIR environment variable support (default: `/workspace`) to the configuration section of `docker/entrypoint.sh`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Container Worktree Mount Validation (Priority: P1) 🎯 MVP

**Goal**: Detect git worktrees at container startup and warn if metadata is inaccessible

**Independent Test**: Mount a worktree directory into the container, verify warning appears when parent repository is not accessible. Mount with parent accessible, verify no warning and git works.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T006 [P] [US1] BATS test: no .git in workspace → no output, exit 0 (WT-U001) in `tests/unit/test_worktree_validation.bats`
- [X] T007 [P] [US1] BATS test: standard .git directory → no worktree warning, exit 0 (WT-U002) in `tests/unit/test_worktree_validation.bats`
- [X] T008 [P] [US1] BATS test: worktree with accessible metadata → informational log, exit 0 (WT-U003) in `tests/unit/test_worktree_validation.bats`
- [X] T009 [P] [US1] BATS test: worktree with inaccessible metadata → warning on stderr, exit 0 (WT-U004) in `tests/unit/test_worktree_validation.bats`
- [X] T010 [P] [US1] BATS test: empty .git file → warning about corrupt file, exit 0 (WT-U005) in `tests/unit/test_worktree_validation.bats`
- [X] T011 [P] [US1] BATS test: .git file without gitdir prefix → warning, exit 0 (WT-U006) in `tests/unit/test_worktree_validation.bats`
- [X] T012 [P] [US1] BATS test: relative gitdir path → resolves correctly (WT-U007) in `tests/unit/test_worktree_validation.bats`
- [X] T013 [P] [US1] BATS test: WORKSPACE_DIR override → uses custom path (WT-U008) in `tests/unit/test_worktree_validation.bats`
- [X] T014 [P] [US1] BATS test: permission denied on .git file → warning, exit 0 (WT-U009) in `tests/unit/test_worktree_validation.bats`

### Implementation for User Story 1

- [X] T015 [US1] Implement `validate_worktree()` function: detect .git file vs directory in `docker/entrypoint.sh`
- [X] T016 [US1] Implement gitdir pointer parsing: extract path from `gitdir:` line in `docker/entrypoint.sh`
- [X] T017 [US1] Implement relative path resolution for gitdir pointers in `docker/entrypoint.sh`
- [X] T018 [US1] Implement metadata accessibility check with `test -d` in `docker/entrypoint.sh`
- [X] T019 [US1] Implement multi-line stderr warning with actionable fix command in `docker/entrypoint.sh`
- [X] T020 [US1] Implement error handling for corrupt/empty .git files in `docker/entrypoint.sh`
- [X] T021 [US1] Integrate `validate_worktree()` call into `main()` after `validate_workspace` in `docker/entrypoint.sh`
- [X] T022 [US1] Verify all BATS unit tests pass (T006-T014) by running `bats tests/unit/test_worktree_validation.bats`

**Checkpoint**: User Story 1 is fully functional. Container detects worktrees, validates metadata, warns on stderr if inaccessible, continues startup regardless.

---

## Phase 4: User Story 2 - AI Agent Worktree Operations (Priority: P2)

**Goal**: Verify AI agents (Claude Code, Aider) work correctly in properly mounted worktrees

**Independent Test**: Run git operations (status, commit, branch detection) via the AI agent in a worktree environment. Verify commits land on the correct branch.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T023 [P] [US2] Integration test: git status works in worktree (WT-I005) in `tests/integration/test_worktree_container.sh`
- [X] T024 [P] [US2] Integration test: commit on correct branch (WT-I006) in `tests/integration/test_worktree_container.sh`
- [X] T025 [P] [US2] Integration test: detached HEAD reported correctly (WT-I007) in `tests/integration/test_worktree_container.sh`
- [X] T026 [P] [US2] BATS test: detached HEAD in worktree → no warning (WT-U010) in `tests/unit/test_worktree_validation.bats`

### Implementation for User Story 2

- [X] T027 [US2] Integration test: standard repo mount produces no worktree warning (WT-I001) in `tests/integration/test_worktree_container.sh`
- [X] T028 [US2] Integration test: worktree with parent accessible works correctly (WT-I002) in `tests/integration/test_worktree_container.sh`
- [X] T029 [US2] Integration test: worktree without parent shows warning but container starts (WT-I003) in `tests/integration/test_worktree_container.sh`
- [X] T030 [US2] Integration test: non-git directory produces no warnings (WT-I004) in `tests/integration/test_worktree_container.sh`
- [X] T031 [US2] Integration test: custom WORKSPACE_DIR works (WT-I008) in `tests/integration/test_worktree_container.sh`
- [X] T032 [US2] Integration test: warning includes actionable fix command (WT-I010) in `tests/integration/test_worktree_container.sh`
- [X] T033 [US2] Verify all integration tests pass by running `bash tests/integration/test_worktree_container.sh`

**Checkpoint**: User Stories 1 AND 2 both work. AI agents operate correctly in worktrees with proper mounts.

---

## Phase 5: User Story 3 - Cross-Worktree Awareness (Priority: P3)

**Goal**: Enable visibility into active worktrees from within any worktree

**Independent Test**: List active worktrees from within a worktree and verify the list matches actual state.

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T034 [P] [US3] Integration test: `git worktree list` shows all worktrees (WT-I009) in `tests/integration/test_worktree_container.sh`

### Implementation for User Story 3

- [X] T035 [US3] Add optional worktree list logging to `log_volume_status()` when in a valid worktree in `docker/entrypoint.sh`
- [X] T036 [US3] Verify `git worktree list` output includes branch names and paths in `tests/integration/test_worktree_container.sh`

**Checkpoint**: All user stories are independently functional. Developers can see active worktrees during startup.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates, regression tests, and CI integration

- [X] T037 [P] Regression test: workspace validation still exits 1 if /workspace missing (WT-R001) in `tests/integration/test_worktree_container.sh`
- [X] T038 [P] Regression test: permission fix still runs on named volumes (WT-R002) in `tests/integration/test_worktree_container.sh`
- [X] T039 [P] Regression test: signal handling preserved (WT-R003) in `tests/integration/test_worktree_container.sh`
- [X] T040 [P] Regression test: volume status logging preserved (WT-R004) in `tests/integration/test_worktree_container.sh`
- [X] T041 [P] Regression test: default shell exec preserved (WT-R005) in `tests/integration/test_worktree_container.sh`
- [X] T042 Run shellcheck on `docker/entrypoint.sh` and fix any warnings
- [X] T043 [P] Create test runner script `scripts/test-worktree.sh` combining BATS and integration tests
- [X] T044 [P] Create CI workflow `.github/workflows/worktree-tests.yml` for automated testing
- [X] T045 Run quickstart.md validation: verify all documented commands work as described

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase
- **User Story 2 (Phase 4)**: Depends on User Story 1 (integration tests need the validate_worktree function)
- **User Story 3 (Phase 5)**: Depends on User Story 1 (logging addition requires base function)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - MVP, independently testable
- **User Story 2 (P2)**: Depends on US1 implementation (tests validate the function behavior in Docker) - independently testable
- **User Story 3 (P3)**: Depends on US1 (adds logging to existing worktree detection flow) - independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation tasks are sequential (detect → parse → resolve → validate → warn → integrate)
- Verify step at end confirms all tests pass

### Parallel Opportunities

- T006-T014 (all US1 BATS tests) can be written in parallel — same file but independent test cases
- T023-T026 (US2 tests) can be written in parallel
- T037-T041 (regression tests) can be written in parallel
- T043-T044 (CI artifacts) can be written in parallel
- US2 and US3 implementation cannot run in parallel (both modify entrypoint, US2 validates US1)

---

## Parallel Example: User Story 1

```bash
# Launch all BATS tests for User Story 1 together:
Task: "BATS test: no .git in workspace" in tests/unit/test_worktree_validation.bats
Task: "BATS test: standard .git directory" in tests/unit/test_worktree_validation.bats
Task: "BATS test: worktree with accessible metadata" in tests/unit/test_worktree_validation.bats
Task: "BATS test: worktree with inaccessible metadata" in tests/unit/test_worktree_validation.bats
Task: "BATS test: empty .git file" in tests/unit/test_worktree_validation.bats
Task: "BATS test: .git file without gitdir prefix" in tests/unit/test_worktree_validation.bats
# (All independent test cases in same file — no conflicts)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (fixtures + BATS)
2. Complete Phase 2: Foundational (WORKSPACE_DIR env var)
3. Complete Phase 3: User Story 1 (TDD cycle: tests → implementation)
4. **STOP and VALIDATE**: Run `bats tests/unit/test_worktree_validation.bats` — all pass
5. Container now detects worktrees and warns on broken mounts

### Incremental Delivery

1. Complete Setup + Foundational → Infrastructure ready
2. Add User Story 1 → Test with BATS → Deploy (MVP!)
3. Add User Story 2 → Integration tests with Docker → Validates agents work
4. Add User Story 3 → Worktree list in startup log → Full feature complete
5. Polish → Regression tests, CI, shellcheck → Production ready

### Single Developer Strategy

Work sequentially through phases. Each phase builds on the previous:
1. Phase 1-2: ~30 min (create dirs, fixtures, env var)
2. Phase 3: ~1-2 hrs (9 tests + 7 implementation tasks + verify)
3. Phase 4: ~1 hr (integration tests in Docker)
4. Phase 5: ~30 min (one function addition + test)
5. Phase 6: ~1 hr (regression, CI, shellcheck)

---

## Notes

- [P] tasks = different files or independent test cases, no dependencies
- [Story] label maps task to specific user story for traceability
- TDD is mandatory (constitution Principle III) — tests MUST fail before implementation
- All stderr output uses existing `log_warning`/`log` patterns from entrypoint.sh
- Non-blocking: `validate_worktree()` always returns 0 regardless of detection result
- Commit after each task or logical group (e.g., all BATS tests, then implementation)
