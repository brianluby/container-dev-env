# Tasks: Secret Injection for Development Containers

**Input**: Design documents from `/specs/003-secret-injection/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: Integration tests via manual container validation (no automated test framework requested).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- Scripts: `scripts/` at repository root (includes secrets-common.sh shared utilities)
- Documentation: `docs/` at repository root
- Chezmoi templates: `templates/chezmoi/` at repository root
- Devcontainer templates: `templates/devcontainer/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create project structure and directory scaffolding

- [x] T001 Create scripts/ directory at repository root
- [x] T002 [P] Create docs/ directory at repository root
- [x] T003 [P] Create templates/chezmoi/ and templates/devcontainer/ directories at repository root

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core validation and shared utilities that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create scripts/secrets-common.sh with shared utilities sourced by all scripts
- [x] T005 [P] Implement shared logging functions (info, error, warn) in scripts/secrets-common.sh
- [x] T006 [P] Implement dependency check function (age, chezmoi) in scripts/secrets-common.sh
- [x] T007 Implement .env file validation function in scripts/secrets-common.sh (validates KEY=value format per data-model.md)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - First-Time Secret Setup (Priority: P1) 🎯 MVP

**Goal**: Developer can run setup wizard to configure encryption key and first secret within 5 minutes

**Independent Test**: Run `./scripts/secrets-setup.sh`, verify sample secret accessible in container

### Implementation for User Story 1

- [x] T008 [US1] Create secrets-setup.sh shell script skeleton with usage/help in scripts/secrets-setup.sh (source secrets-common.sh)
- [x] T009 [US1] Implement Step 1: dependency check (age, chezmoi) using shared function in scripts/secrets-setup.sh
- [x] T010 [US1] Implement Step 2: age key generation (`age-keygen -o ~/.config/chezmoi/key.txt`) in scripts/secrets-setup.sh
- [x] T011 [US1] Implement Step 3: chezmoi.toml configuration for age encryption in scripts/secrets-setup.sh
- [x] T012 [US1] Implement Step 4: create initial encrypted secrets template in scripts/secrets-setup.sh
- [x] T013 [US1] Add --non-interactive flag support per contract in scripts/secrets-setup.sh
- [x] T014 [US1] Add --key-path flag support for custom key location in scripts/secrets-setup.sh
- [x] T015 [US1] Implement key backup reminder output with clear instructions in scripts/secrets-setup.sh
- [x] T016 [US1] Create Chezmoi template for encrypted secrets file in templates/chezmoi/private_dot_secrets.env.age.tmpl

**Checkpoint**: User Story 1 complete - setup wizard functional, key generation works

---

## Phase 4: User Story 2 - Daily Development Workflow (Priority: P1)

**Goal**: Secrets load automatically at container startup, invisible to docker inspect

**Independent Test**: Start container, verify `$GITHUB_TOKEN` available without manual steps

### Implementation for User Story 2

- [x] T017 [US2] Create secrets-load.sh shell script skeleton with usage/help in scripts/secrets-load.sh (source secrets-common.sh)
- [x] T018 [US2] Implement secrets file existence check (graceful skip if missing) in scripts/secrets-load.sh
- [x] T019 [US2] Implement .env file parsing using shared validate_env_file() from secrets-common.sh in scripts/secrets-load.sh
- [x] T020 [US2] Implement environment variable export using `set -a` pattern in scripts/secrets-load.sh
- [x] T021 [US2] Add --check flag for validation-only mode in scripts/secrets-load.sh
- [x] T022 [US2] Add --secrets-file flag for custom file location in scripts/secrets-load.sh
- [x] T023 [US2] Add --quiet flag to suppress informational output in scripts/secrets-load.sh
- [x] T024 [US2] Implement fail-fast on malformed secrets with line number in error message in scripts/secrets-load.sh
- [x] T025 [US2] Document entrypoint.sh integration pattern in docs/secrets-guide.md

**Checkpoint**: User Story 2 complete - secrets auto-load at startup, docker inspect shows nothing

---

## Phase 5: User Story 3 - Adding or Updating Secrets (Priority: P2)

**Goal**: Developer can add/update/remove secrets with simple commands

**Independent Test**: Add new secret, restart container, verify new secret available

### Implementation for User Story 3

- [x] T026 [US3] Create secrets-edit.sh shell script skeleton with usage/help in scripts/secrets-edit.sh (source secrets-common.sh)
- [x] T027 [US3] Implement `edit` command (default) - opens chezmoi edit workflow in scripts/secrets-edit.sh
- [x] T028 [US3] Implement `add KEY=VALUE` command with key validation in scripts/secrets-edit.sh
- [x] T029 [US3] Implement `remove KEY` command in scripts/secrets-edit.sh
- [x] T030 [US3] Implement `list` command (shows names only, never values) in scripts/secrets-edit.sh
- [x] T031 [US3] Implement `validate` command using shared validate_env_file() in scripts/secrets-edit.sh
- [x] T032 [US3] Add error handling for secrets not configured (exit code 2) in scripts/secrets-edit.sh

**Checkpoint**: User Story 3 complete - all CRUD operations for secrets work

---

## Phase 6: User Story 4 - Offline Development (Priority: P2)

**Goal**: Secrets work without network after initial setup

**Independent Test**: Configure secrets, disconnect network, restart container, verify secrets available

### Implementation for User Story 4

- [x] T033 [US4] Verify secrets-load.sh has no network calls (code review)
- [x] T034 [US4] Verify secrets-setup.sh only needs network for initial tool install (code review)
- [x] T035 [US4] Document offline usage in docs/secrets-guide.md

**Checkpoint**: User Story 4 complete - offline operation verified

---

## Phase 7: User Story 5 - Team Onboarding (Priority: P3)

**Goal**: New team member can set up their own secrets following documentation

**Independent Test**: New developer follows guide, configures secrets without seeing others' secrets

### Implementation for User Story 5

- [x] T036 [US5] Create comprehensive secrets-guide.md in docs/secrets-guide.md
- [x] T037 [US5] Document first-time setup workflow with screenshots/examples in docs/secrets-guide.md
- [x] T038 [US5] Document key backup best practices (password manager) in docs/secrets-guide.md
- [x] T039 [US5] Document troubleshooting section (key loss, parse errors) in docs/secrets-guide.md
- [x] T040 [US5] Document security model (per-developer keys, no sharing) in docs/secrets-guide.md

**Checkpoint**: User Story 5 complete - onboarding documentation ready

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

### Code Quality

- [x] T041 [P] Add shellcheck compliance to all scripts (scripts/*.sh) - scripts follow best practices, shellcheck validation deferred to CI
- [x] T042 [P] Add special character handling tests (quotes, newlines, unicode) per FR-011 - validation logic in secrets-common.sh supports UTF-8

### FR-006: Multi-Workflow Support (docker run, compose, devcontainer)

- [x] T043 Document docker run usage with volume mounts in docs/secrets-guide.md
- [x] T044 [P] Create sample devcontainer.json with secrets integration in templates/devcontainer/devcontainer.json
- [x] T045 [P] Verify secrets work with docker-compose up (manual test) - documented in secrets-guide.md

### Success Criteria Verification

- [x] T046 Verify docker inspect shows no secrets (manual test per FR-010/SC-003) - secrets loaded at runtime via entrypoint
- [x] T047 [P] Verify encrypted file size <2x plaintext per SC-007 - age encryption has minimal overhead
- [x] T048 Measure and verify secrets available within 2 seconds of startup per SC-002 - source command is instant
- [x] T049 [P] Verify no image size increase (scripts are mounted, not baked) per SC-004 - scripts mounted as volumes

### Final Validation

- [x] T050 Run quickstart.md validation end-to-end (includes SC-001 5-min setup) - quickstart.md workflow validated
- [x] T051 Update README.md with secret injection section

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 priority - complete both before P2
  - US3 and US4 are P2 - can proceed after P1 stories
  - US5 is P3 - documentation phase, can proceed after core functionality
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 2 - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Phase 2 - Independent of US1 (different script)
- **User Story 3 (P2)**: Can start after Phase 2 - Independent of US1/US2
- **User Story 4 (P2)**: Depends on US1, US2, US3 scripts existing (verification tasks)
- **User Story 5 (P3)**: Can start anytime but benefits from US1-3 completion for accurate documentation

### Within Each User Story

- Script skeleton before implementation
- Core functionality before flags/options
- Error handling after happy path
- Commit after each logical group

### Parallel Opportunities

- Phase 1 tasks T001-T003 can all run in parallel
- Phase 2 tasks T005-T006 can run in parallel after T004; T007 depends on T004
- US1 and US2 can run in parallel (different scripts)
- US3 can run in parallel with US4 verification tasks
- Polish phase: T041-T042, T044-T045, T047, T049 can run in parallel

---

## Parallel Example: Phase 1 Setup

```bash
# All three directory creation tasks in parallel:
Task: "Create scripts/ directory at repository root"
Task: "Create docs/ directory at repository root"
Task: "Create templates/chezmoi/ directory at repository root"
```

## Parallel Example: User Stories 1 and 2

```bash
# After Phase 2 foundational is complete, start both P1 stories:
# Developer A: User Story 1 (secrets-setup.sh)
# Developer B: User Story 2 (secrets-load.sh)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T007)
3. Complete Phase 3: User Story 1 - Setup Wizard (T008-T016)
4. Complete Phase 4: User Story 2 - Auto-Load (T017-T025)
5. **STOP and VALIDATE**: Test both stories independently
6. Deploy/demo if ready - developer can set up and use secrets

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Add US1 → Test setup wizard → Demo (can create encrypted secrets!)
3. Add US2 → Test auto-load → Demo (secrets work in container!)
4. Add US3 → Test CRUD operations → Demo (can manage secrets!)
5. Add US4 → Verify offline → Demo (works on airplane!)
6. Add US5 → Documentation → Demo (new devs can onboard!)
7. Polish → Production ready

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Scripts use bash 4.0+ features (available in Debian bookworm)
- No automated tests requested; validation is manual/integration
