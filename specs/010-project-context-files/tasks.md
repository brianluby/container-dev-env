# Tasks: Project Context Files

**Input**: Design documents from `/specs/010-project-context-files/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Included (TDD per constitution principle III — BATS tests for bootstrap script, validation tests for templates).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- Templates in `src/templates/`
- Scripts in `src/scripts/`
- Tests in `tests/unit/` and `tests/integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [x] T001 Create project directory structure: `src/templates/`, `src/scripts/`, `tests/unit/`, `tests/integration/`
- [x] T002 [P] Add `.gitignore` entry for `AGENTS.local.md` in repository root `.gitignore`
- [x] T003 [P] Install BATS testing framework (add to dev dependencies or document installation)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core templates that all user stories depend on — the comprehensive and minimal AGENTS.md templates must exist before the bootstrap script or nested/supplement files can be created.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create comprehensive AGENTS.md template with all 9 sections (Overview, Technology Stack, Coding Standards, Architecture, Common Patterns, Testing Requirements, Git Workflow, Security Considerations, AI Agent Instructions) including placeholder text and security warnings in `src/templates/AGENTS.md.full`
- [x] T005 [P] Create minimal AGENTS.md template with 4 essential sections (Overview, Technology Stack, Key Conventions, AI Instructions) including placeholder text in `src/templates/AGENTS.md.minimal`

**Checkpoint**: Foundation ready — template files exist for user story implementation

---

## Phase 3: User Story 1 - Root-Level Project Context (Priority: P1) 🎯 MVP

**Goal**: A developer can create an AGENTS.md at their project root that AI tools automatically read and follow.

**Independent Test**: Create the comprehensive template as a real AGENTS.md, start a Claude Code session, verify it references the documented conventions.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T006 [P] [US1] Write BATS test validating comprehensive template is valid Markdown, under 10KB, UTF-8, LF line endings in `tests/unit/test_templates.bats`
- [x] T007 [P] [US1] Write BATS test validating comprehensive template contains all 9 required section headings in `tests/unit/test_templates.bats`
- [x] T008 [P] [US1] Write BATS test validating template contains security warning HTML comments in `tests/unit/test_templates.bats`

### Implementation for User Story 1

- [x] T009 [US1] Verify `src/templates/AGENTS.md.full` passes all template validation tests (T006, T007, T008)
- [x] T010 [US1] Validate comprehensive template file size is under 10,240 bytes
- [x] T011 [US1] Create example AGENTS.md for container-dev-env project itself in repository root `AGENTS.md` (using the comprehensive template filled with real project data)

**Checkpoint**: At this point, a root-level AGENTS.md exists and is validated — AI tools can read it.

---

## Phase 4: User Story 2 - Cross-Tool Compatibility (Priority: P1)

**Goal**: The same AGENTS.md file works across Claude Code, Cline, Continue, and other AI tools without modification.

**Independent Test**: Create one AGENTS.md and verify at least 3 AI tools read it without errors.

### Tests for User Story 2

- [x] T012 [P] [US2] Write BATS test validating minimal template is valid Markdown, under 10KB, UTF-8, LF in `tests/unit/test_templates.bats`
- [x] T013 [P] [US2] Write BATS test validating CLAUDE.md template does not duplicate AGENTS.md section headings in `tests/unit/test_templates.bats`

### Implementation for User Story 2

- [x] T014 [US2] Create CLAUDE.md supplement template with Claude-specific sections (Behavior Preferences, Tool Usage, Response Style) in `src/templates/CLAUDE.md.template`
- [x] T015 [US2] Verify `src/templates/AGENTS.md.minimal` passes validation tests (T012)
- [x] T016 [US2] Create tool compatibility documentation listing per-tool discovery behavior in `docs/tool-compatibility.md`
- [x] T017 [US2] Create manual test matrix checklist for verifying context file recognition across tools (Claude Code, Cline, Continue, Roo-Code, OpenCode) in `docs/test-matrix.md`

**Checkpoint**: Templates validated for cross-tool format compliance; compatibility documented.

---

## Phase 5: User Story 3 - Directory-Specific Context (Priority: P2)

**Goal**: Developers can create nested AGENTS.md files in subdirectories for module-specific context that supplements root context.

**Independent Test**: Create root AGENTS.md saying "use camelCase" and src/api/AGENTS.md saying "use snake_case", verify AI follows snake_case when in src/api/.

### Tests for User Story 3

- [x] T018 [P] [US3] Write BATS test validating nested template is valid Markdown, under 10KB, UTF-8, LF in `tests/unit/test_templates.bats`
- [x] T019 [P] [US3] Write BATS test validating nested template contains Module Purpose section heading in `tests/unit/test_templates.bats`

### Implementation for User Story 3

- [x] T020 [US3] Create nested directory AGENTS.md template with 4 sections (Module Purpose, Local Conventions, Key Patterns, Testing) in `src/templates/nested-AGENTS.md`
- [x] T021 [US3] Verify nested template passes validation tests (T018, T019)
- [x] T022 [US3] Document context composition rules (root + nested merging, precedence) in `docs/composition-rules.md`

**Checkpoint**: Nested context support is complete and documented.

---

## Phase 6: User Story 4 - Quick Project Setup with Templates (Priority: P2)

**Goal**: A bootstrap script generates context files from templates, enabling <5min setup for minimal or <30min for comprehensive.

**Independent Test**: Run `init-context.sh --minimal` in an empty directory, verify AGENTS.md is created with correct structure.

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T023 [P] [US4] Write BATS test: `init-context.sh --minimal` creates AGENTS.md with 4 sections in `tests/unit/test_init_context.bats`
- [x] T024 [P] [US4] Write BATS test: `init-context.sh --full` creates AGENTS.md with 9 sections in `tests/unit/test_init_context.bats`
- [x] T025 [P] [US4] Write BATS test: `init-context.sh` without flags shows interactive prompt in `tests/unit/test_init_context.bats`
- [x] T026 [P] [US4] Write BATS test: script exits 1 if AGENTS.md already exists (no --force) in `tests/unit/test_init_context.bats`
- [x] T027 [P] [US4] Write BATS test: `--force` overwrites existing file in `tests/unit/test_init_context.bats`
- [x] T028 [P] [US4] Write BATS test: `--output path/file.md` writes to specified path in `tests/unit/test_init_context.bats`
- [x] T029 [P] [US4] Write BATS test: `--help` outputs usage information in `tests/unit/test_init_context.bats`
- [x] T030 [P] [US4] Write BATS test: invalid arguments exit with code 2 in `tests/unit/test_init_context.bats`

### Implementation for User Story 4

- [x] T031 [US4] Implement `init-context.sh` bootstrap script with argument parsing (--full, --minimal, --output, --force, --help) in `src/scripts/init-context.sh`
- [x] T032 [US4] Implement file existence check and --force override logic in `src/scripts/init-context.sh`
- [x] T033 [US4] Implement template selection and file writing (reads from src/templates/) in `src/scripts/init-context.sh`
- [x] T034 [US4] Implement interactive mode (prompt user for template choice when no flags provided) in `src/scripts/init-context.sh`
- [x] T035 [US4] Add ShellCheck compliance to `src/scripts/init-context.sh` (zero warnings)
- [x] T036 [US4] Verify all BATS tests pass (T023–T030)

**Checkpoint**: Bootstrap script fully functional and tested.

---

## Phase 7: User Story 5 - Security-Safe Context (Priority: P2)

**Goal**: Templates and guidance ensure context files never contain secrets, credentials, or internal infrastructure details.

**Independent Test**: Review all templates for security warnings; verify no placeholder text suggests including secrets.

### Tests for User Story 5

- [x] T037 [P] [US5] Write BATS test validating all templates contain security warning comments in `tests/integration/test_security.bats`
- [x] T038 [P] [US5] Write BATS test validating no template placeholder text suggests including secrets/keys/passwords in `tests/integration/test_security.bats`

### Implementation for User Story 5

- [x] T039 [US5] Verify comprehensive template security section includes HTML comment warning in `src/templates/AGENTS.md.full`
- [x] T040 [US5] Add `AGENTS.local.md` to `.gitignore` entry documentation and verify it exists in repository `.gitignore`
- [x] T041 [US5] Document pre-commit hook recommendation (detect-secrets/gitleaks) for scanning context files in `docs/security-guidance.md`
- [x] T042 [US5] Verify all templates pass security tests (T037, T038)

**Checkpoint**: Security guardrails validated across all templates.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final documentation, validation, and cleanup

- [x] T043 [P] Run ShellCheck on all shell scripts in `src/scripts/`
- [x] T044 [P] Validate all template files are under 10KB size limit
- [x] T045 [P] Validate all template files use UTF-8 encoding and LF line endings
- [x] T046 Update quickstart guide with final script paths and usage examples in `specs/010-project-context-files/quickstart.md`
- [x] T047 Run full BATS test suite and verify all tests pass
- [x] T048 Run manual test matrix: verify AGENTS.md recognition in Claude Code (at minimum)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 (needs comprehensive template)
- **User Story 2 (Phase 4)**: Depends on Phase 2 (needs both templates)
- **User Story 3 (Phase 5)**: Depends on Phase 2 (needs template conventions established)
- **User Story 4 (Phase 6)**: Depends on Phase 2 AND Phase 3 (script reads templates that must exist)
- **User Story 5 (Phase 7)**: Depends on Phase 2 (needs templates to validate)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 2 — no dependencies on other stories
- **User Story 2 (P1)**: Can start after Phase 2 — independent of US1
- **User Story 3 (P2)**: Can start after Phase 2 — independent of US1/US2
- **User Story 4 (P2)**: Depends on US1 completion (script needs templates validated)
- **User Story 5 (P2)**: Can start after Phase 2 — independent of US1/US2/US3

### Within Each User Story

- Tests MUST be written and FAIL before implementation begins
- Template creation before validation
- Script logic before integration tests
- Story complete before moving to next priority

### Parallel Opportunities

- T002, T003 can run in parallel with T001 (Setup phase)
- T004, T005 can run in parallel (Foundational phase — different template files)
- T006, T007, T008 can run in parallel (US1 tests — same file but different test functions)
- T012, T013 can run in parallel (US2 tests)
- T018, T019 can run in parallel (US3 tests)
- T023–T030 can ALL run in parallel (US4 tests — all in same file, different functions)
- T037, T038 can run in parallel (US5 tests)
- US1, US2, US3, US5 can all run in parallel after Phase 2 (different deliverables)
- T043, T044, T045 can run in parallel (Polish — different validation checks)

---

## Parallel Example: User Story 4 (Bootstrap Script)

```bash
# Launch all tests for User Story 4 together:
Task: "Write BATS test: init-context.sh --minimal creates AGENTS.md in tests/unit/test_init_context.bats"
Task: "Write BATS test: init-context.sh --full creates AGENTS.md in tests/unit/test_init_context.bats"
Task: "Write BATS test: script exits 1 if AGENTS.md exists in tests/unit/test_init_context.bats"
Task: "Write BATS test: --force overwrites existing file in tests/unit/test_init_context.bats"
Task: "Write BATS test: --output writes to specified path in tests/unit/test_init_context.bats"
Task: "Write BATS test: --help outputs usage in tests/unit/test_init_context.bats"
Task: "Write BATS test: invalid args exit 2 in tests/unit/test_init_context.bats"

# Then sequentially implement the script:
Task: "Implement init-context.sh argument parsing in src/scripts/init-context.sh"
Task: "Implement file existence check in src/scripts/init-context.sh"
Task: "Implement template writing in src/scripts/init-context.sh"
Task: "Implement interactive mode in src/scripts/init-context.sh"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (comprehensive + minimal templates)
3. Complete Phase 3: User Story 1 (root-level context validated)
4. Complete Phase 4: User Story 2 (cross-tool supplement + docs)
5. **STOP and VALIDATE**: Test AGENTS.md recognition across at least 3 tools
6. Deploy/demo if ready — developers can manually copy templates

### Incremental Delivery

1. Complete Setup + Foundational → Templates exist
2. Add User Story 1 → Root AGENTS.md validated → Usable immediately (MVP!)
3. Add User Story 2 → Cross-tool docs + CLAUDE.md supplement → Multi-tool ready
4. Add User Story 3 → Nested context support → Large project ready
5. Add User Story 4 → Bootstrap script → Automated setup
6. Add User Story 5 → Security validation → Public repo safe
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (root context + example)
   - Developer B: User Story 2 (supplements + compatibility docs)
   - Developer C: User Story 3 (nested templates)
3. After US1 complete: Developer D starts User Story 4 (bootstrap script)
4. Independent: Developer E works on User Story 5 (security validation)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Verify tests fail before implementing (TDD per constitution principle III)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Template files are the core deliverable — the script is a convenience wrapper
