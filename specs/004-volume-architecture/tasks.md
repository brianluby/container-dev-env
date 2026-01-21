# Tasks: Volume Architecture for Development Containers

**Input**: Design documents from `/specs/004-volume-architecture/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Integration tests included per Constitution principle III (Test-First Development)

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Infrastructure/container configuration project:
- `docker/` - Dockerfile, docker-compose.yml, entrypoint.sh
- `scripts/` - Utility scripts
- `tests/integration/` - Integration test scripts
- `docs/` - User-facing documentation

---

## Phase 1: Setup (Project Structure)

**Purpose**: Create project structure and initialize configuration files

- [x] T001 Create docker/ directory structure at docker/
- [x] T002 [P] Create scripts/ directory at scripts/
- [x] T003 [P] Create tests/integration/ directory at tests/integration/
- [x] T004 [P] Create docs/ directory at docs/

**Checkpoint**: Directory structure ready for implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create base Dockerfile with non-root user (dev:1000) in docker/Dockerfile
- [x] T006 Create base docker-compose.yml with service definition in docker/docker-compose.yml
- [x] T007 Create entrypoint.sh skeleton with logging framework in docker/entrypoint.sh
- [x] T008 Add environment variable handling (LOCAL_UID, LOCAL_GID) in docker/entrypoint.sh
- [x] T009 Implement cross-platform stat compatibility (Linux/macOS) in docker/entrypoint.sh
- [x] T010 Add signal handling (SIGTERM, SIGINT) with exec in docker/entrypoint.sh

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Source Code Editing from Host (Priority: P1) 🎯 MVP

**Goal**: Enable bidirectional file sync between host IDE and container within 1 second

**Independent Test**: Edit file on host → verify in container within 1s → edit in container → verify on host

### Tests for User Story 1

- [x] T011 [P] [US1] Create bind mount sync test in tests/integration/test-bind-mount.sh
- [x] T012 [P] [US1] Create host→container sync verification in tests/integration/test-bind-mount.sh
- [x] T013 [P] [US1] Create container→host sync verification in tests/integration/test-bind-mount.sh
- [x] T014 [P] [US1] Create file permission verification test in tests/integration/test-bind-mount.sh

### Implementation for User Story 1

- [x] T015 [US1] Add workspace bind mount configuration in docker/docker-compose.yml
- [x] T016 [US1] Configure :cached consistency flag for bind mount in docker/docker-compose.yml
- [x] T017 [US1] Add workspace validation (fail-fast if missing) in docker/entrypoint.sh
- [x] T018 [US1] Add workspace writability check in docker/entrypoint.sh
- [x] T019 [US1] Log workspace mount status at startup in docker/entrypoint.sh

**Checkpoint**: User Story 1 complete - host↔container file sync working with <1s latency

---

## Phase 4: User Story 2 - Persistent Development Environment (Priority: P1)

**Goal**: Shell history, dotfiles, and local tools persist across container restarts

**Independent Test**: Customize shell → restart container → verify customizations remain

### Tests for User Story 2

- [x] T020 [P] [US2] Create named volume persistence test in tests/integration/test-named-volumes.sh
- [x] T021 [P] [US2] Create shell history persistence test in tests/integration/test-named-volumes.sh
- [x] T022 [P] [US2] Create dotfile persistence test in tests/integration/test-named-volumes.sh
- [x] T023 [P] [US2] Create local tool persistence test in tests/integration/test-named-volumes.sh

### Implementation for User Story 2

- [x] T024 [US2] Add home-data named volume definition in docker/docker-compose.yml
- [x] T025 [US2] Configure home volume mount to /home/dev in docker/docker-compose.yml
- [x] T026 [US2] Add volume labels (com.devenv.type, persistence) in docker/docker-compose.yml
- [x] T027 [US2] Implement home directory permission fix in docker/entrypoint.sh
- [x] T028 [US2] Add volume recovery (create if missing with warning) in docker/entrypoint.sh
- [x] T029 [US2] Log home volume status at startup in docker/entrypoint.sh

**Checkpoint**: User Story 2 complete - development environment persists across restarts

---

## Phase 5: User Story 3 - Fast Dependency Installation (Priority: P1)

**Goal**: npm install with 50+ packages completes in under 10 seconds

**Independent Test**: Time npm install with 50+ packages → verify <10s completion

### Tests for User Story 3

- [x] T030 [P] [US3] Create npm install performance test in tests/integration/test-performance.sh
- [x] T031 [P] [US3] Create pip install cache test in tests/integration/test-performance.sh
- [x] T032 [P] [US3] Create cargo cache test in tests/integration/test-performance.sh
- [x] T033 [P] [US3] Create cache reuse verification test in tests/integration/test-performance.sh

### Implementation for User Story 3

- [x] T034 [P] [US3] Add npm-cache named volume definition in docker/docker-compose.yml
- [x] T035 [P] [US3] Add pip-cache named volume definition in docker/docker-compose.yml
- [x] T036 [P] [US3] Add cargo-registry named volume definition in docker/docker-compose.yml
- [x] T037 [P] [US3] Add node-modules named volume definition in docker/docker-compose.yml
- [x] T038 [P] [US3] Add cargo-target named volume definition in docker/docker-compose.yml
- [x] T039 [US3] Mount npm-cache to /home/dev/.npm in docker/docker-compose.yml
- [x] T040 [US3] Mount pip-cache to /home/dev/.cache/pip in docker/docker-compose.yml
- [x] T041 [US3] Mount cargo-registry to /home/dev/.cargo/registry in docker/docker-compose.yml
- [x] T042 [US3] Mount node-modules to /workspace/node_modules in docker/docker-compose.yml
- [x] T043 [US3] Mount cargo-target to /workspace/target in docker/docker-compose.yml
- [x] T044 [US3] Add cache volume permission fixes in docker/entrypoint.sh
- [x] T045 [US3] Set package manager environment variables (npm_config_cache, PIP_CACHE_DIR, CARGO_HOME) in docker/docker-compose.yml

**Checkpoint**: User Story 3 complete - dependency installation 10x faster than bind mounts

---

## Phase 6: User Story 4 - Clean Temporary Storage (Priority: P2)

**Goal**: /tmp is automatically cleaned on container restart

**Independent Test**: Create files in /tmp → restart container → verify /tmp is empty

### Tests for User Story 4

- [x] T046 [P] [US4] Create tmpfs mount test in tests/integration/test-tmpfs.sh
- [x] T047 [P] [US4] Create tmpfs cleanup verification test in tests/integration/test-tmpfs.sh
- [x] T048 [P] [US4] Create tmpfs size limit test in tests/integration/test-tmpfs.sh

### Implementation for User Story 4

- [x] T049 [US4] Add tmpfs mount for /tmp with size=512M in docker/docker-compose.yml
- [x] T050 [US4] Configure tmpfs mode=1777 for world-writable /tmp in docker/docker-compose.yml
- [x] T051 [US4] Log tmpfs status at startup in docker/entrypoint.sh

**Checkpoint**: User Story 4 complete - temporary files auto-cleared on restart

---

## Phase 7: User Story 5 - Safe Pruning and Recovery (Priority: P2)

**Goal**: Source code survives docker system prune; named volumes require explicit deletion

**Independent Test**: Run docker system prune → verify source code intact

### Tests for User Story 5

- [x] T052 [P] [US5] Create prune safety test in tests/integration/test-prune-safety.sh
- [x] T053 [P] [US5] Create bind mount survival test in tests/integration/test-prune-safety.sh
- [x] T054 [P] [US5] Create named volume explicit deletion test in tests/integration/test-prune-safety.sh

### Implementation for User Story 5

- [x] T055 [US5] Add explicit names to all volumes (devenv-*) in docker/docker-compose.yml
- [x] T056 [US5] Add safe-to-prune labels to cache volumes in docker/docker-compose.yml
- [x] T057 [US5] Add safe-to-prune=false label to home volume in docker/docker-compose.yml
- [x] T058 [US5] Create volume-health.sh diagnostic script in scripts/volume-health.sh

**Checkpoint**: User Story 5 complete - data safe from accidental deletion

---

## Phase 8: User Story 6 - New Developer Onboarding (Priority: P3)

**Goal**: New developers understand persistence model within 5 minutes

**Independent Test**: New user reads documentation → correctly predicts 5 persistence scenarios

### Tests for User Story 6

- [x] T059 [US6] Create documentation completeness checklist in tests/integration/test-docs.sh

### Implementation for User Story 6

- [x] T060 [P] [US6] Create volume-architecture.md overview in docs/volume-architecture.md
- [x] T061 [P] [US6] Add persistence model table in docs/volume-architecture.md
- [x] T062 [P] [US6] Add common scenarios FAQ in docs/volume-architecture.md
- [x] T063 [US6] Add inline comments to docker-compose.yml explaining each volume
- [x] T064 [US6] Add troubleshooting section in docs/volume-architecture.md

**Checkpoint**: User Story 6 complete - documentation enables quick onboarding

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T065 [P] Create .devcontainer/devcontainer.json for VS Code integration
- [ ] T066 [P] Add shellcheck validation for all bash scripts (requires shellcheck installation)
- [x] T067 Code review: verify all entrypoint contract requirements met
- [ ] T068 Performance validation: verify <3s startup time (SC-003)
- [ ] T069 [P] Add CI workflow for integration tests in .github/workflows/
- [ ] T070 Run full test suite and fix any failures
- [x] T071 Update quickstart.md with final paths and commands

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational completion
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

```
Phase 2: Foundational (T005-T010)
           │
           ▼
    ┌──────┼──────┬──────┬──────┬──────┐
    ▼      ▼      ▼      ▼      ▼      ▼
  US1    US2    US3    US4    US5    US6
 (P1)   (P1)   (P1)   (P2)   (P2)   (P3)
    │      │      │      │      │      │
    └──────┴──────┴──────┴──────┴──────┘
                   │
                   ▼
              Phase 9: Polish
```

- **US1**: No dependencies on other stories - can start first
- **US2**: Can run parallel with US1 (different volume configuration)
- **US3**: Can run parallel with US1/US2 (different volume configuration)
- **US4**: Can run parallel (tmpfs independent of named volumes)
- **US5**: Should follow US2/US3 (tests volume naming/labels)
- **US6**: Should follow all others (documents final architecture)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Configuration before validation
- Core implementation before logging
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 (all parallel)**:
```bash
# Can run simultaneously:
T001, T002, T003, T004
```

**Phase 2 (some parallel)**:
```bash
# Sequential: T005 → T006 → T007 → T008 → T009 → T010
# (entrypoint builds on docker-compose which builds on Dockerfile)
```

**User Story Tests (parallel within story)**:
```bash
# US1 tests: T011, T012, T013, T014 (all parallel)
# US2 tests: T020, T021, T022, T023 (all parallel)
# US3 tests: T030, T031, T032, T033 (all parallel)
```

**User Story Implementations (parallel across stories after foundation)**:
```bash
# Can run simultaneously after Phase 2:
# - US1 implementation (T015-T019)
# - US2 implementation (T024-T029)
# - US3 volume definitions (T034-T038)
```

---

## Parallel Example: User Story 3 Cache Volumes

```bash
# Launch all volume definitions in parallel (different sections of same file):
# T034: Add npm-cache named volume
# T035: Add pip-cache named volume
# T036: Add cargo-registry named volume
# T037: Add node-modules named volume
# T038: Add cargo-target named volume

# Then mount configurations (sequential - depends on definitions):
# T039 → T040 → T041 → T042 → T043 → T044
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (4 tasks)
2. Complete Phase 2: Foundational (6 tasks)
3. Complete Phase 3: User Story 1 (9 tasks)
4. **STOP and VALIDATE**: Test host↔container file sync
5. Total: 19 tasks for functional MVP

### Incremental Delivery

1. **MVP**: Setup + Foundation + US1 → Host file editing works
2. **Add US2**: Home persistence → Development state persists
3. **Add US3**: Cache volumes → 10x faster npm install
4. **Add US4**: tmpfs → Clean temporary storage
5. **Add US5**: Prune safety → Data protection
6. **Add US6**: Documentation → Onboarding ready
7. **Polish**: VS Code integration, CI, final validation

### Task Counts by Phase

| Phase | Story | Tasks | Cumulative |
|-------|-------|-------|------------|
| 1 | Setup | 4 | 4 |
| 2 | Foundational | 6 | 10 |
| 3 | US1 (P1) | 9 | 19 |
| 4 | US2 (P1) | 10 | 29 |
| 5 | US3 (P1) | 16 | 45 |
| 6 | US4 (P2) | 6 | 51 |
| 7 | US5 (P2) | 7 | 58 |
| 8 | US6 (P3) | 6 | 64 |
| 9 | Polish | 7 | 71 |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Infrastructure project: docker-compose.yml is central configuration file
