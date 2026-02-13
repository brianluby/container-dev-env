# Tasks: Pin Base Images to Immutable Digests

**Input**: Design documents from `specs/001-pin-image-digests/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/digest-pinning.openapi.yaml`, `quickstart.md`

**Tests**: Test-first tasks are included to satisfy constitution requirements.

**Organization**: Tasks are grouped by user story so each story remains independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable task (different files, no dependency on incomplete tasks)
- **[Story]**: Story mapping label (`[US1]`, `[US2]`, `[US3]`) for story-phase tasks only
- Every task includes an explicit file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize files and scaffolding used by all stories.

- [X] T001 Create `## Digest Implementation Notes` section in `docs/operations/deployment.md` with scope, validation gates, and evidence requirements
- [X] T002 [P] Create helper script scaffold in `scripts/validate-base-image-digests.sh`
- [X] T003 [P] Add test harness scaffold for digest validator in `tests/unit/test_validate_base_image_digests.bats`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build shared validation gates that block all story work.

**⚠️ CRITICAL**: User story tasks must not start until this phase is complete.

- [X] T004 Implement digest parsing and platform coverage checks in `scripts/validate-base-image-digests.sh`
- [X] T005 [P] Add failing-first unit tests for coverage/format validation in `tests/unit/test_validate_base_image_digests.bats`
- [X] T006 Implement validator pass-path and fail-path behavior in `scripts/validate-base-image-digests.sh`
- [X] T007 [P] Add CI wiring for digest validator in `.github/workflows/container-build.yml`
- [X] T008 Add local verifier usage and expected output in `docs/contributing/testing.md`
- [X] T009 Add hard failure policy for unsupported architectures in `docs/operations/deployment.md`

**Checkpoint**: Shared digest validation works locally and in CI.

---

## Phase 3: User Story 1 - Deterministic Container Builds (Priority: P1) 🎯 MVP

**Goal**: Pin external base image references in all in-scope Dockerfiles and prove deterministic behavior.

**Independent Test**: Execute local + CI verification after pinning and verify two-time rebuild consistency evidence.

### Tests for User Story 1

- [X] T010 [P] [US1] Add failing-first integration test for pinned `FROM` coverage in `tests/integration/test_digest_pinning_scope.sh`
- [X] T011 [P] [US1] Add failing-first reproducibility test for repeated builds in `tests/integration/test_digest_reproducibility.sh`

### Implementation for User Story 1

- [X] T012 [US1] Pin external base image references in `Dockerfile`
- [X] T013 [P] [US1] Pin external base image references in `docker/Dockerfile`
- [X] T014 [P] [US1] Pin external base image references in `docker/Dockerfile.ide`
- [X] T015 [P] [US1] Pin external base image references in `docker/memory.Dockerfile`
- [X] T016 [US1] Update reproducibility verification steps in `specs/001-pin-image-digests/quickstart.md`
- [X] T017 [US1] Record two-run reproducibility evidence requirements in `docs/operations/deployment.md`
- [X] T018 [US1] Ensure CI gate validates pinned references and platform coverage in `.github/workflows/container-build.yml`

**Checkpoint**: US1 complete with deterministic pinning and reproducibility evidence.

---

## Phase 4: User Story 2 - Clear Scope and Auditability (Priority: P2)

**Goal**: Make scope, exclusions, and reviewer validation transparent.

**Independent Test**: A reviewer can verify in-scope files, exclusions, and coverage outputs directly from docs and script output.

### Tests for User Story 2

- [X] T019 [P] [US2] Add failing-first output format test for scope report in `tests/unit/test_validate_base_image_digests.bats`

### Implementation for User Story 2

- [X] T020 [US2] Add in-scope Dockerfile inventory in `docs/architecture/overview.md`
- [X] T021 [P] [US2] Add out-of-scope exclusions in `docs/operations/deployment.md`
- [X] T022 [US2] Implement machine-readable scope/coverage output in `scripts/validate-base-image-digests.sh`
- [X] T023 [US2] Add reviewer checklist for digest coverage in `docs/contributing/workflow.md`

**Checkpoint**: US2 complete with auditable scope and review guidance.

---

## Phase 5: User Story 3 - Sustainable Digest Refresh Process (Priority: P3)

**Goal**: Define repeatable refresh workflow with measurable completion criteria.

**Independent Test**: A maintainer completes one refresh cycle, including timing evidence under 30 minutes.

### Tests for User Story 3

- [X] T024 [P] [US3] Add failing-first refresh workflow validation test in `tests/integration/test_digest_refresh_workflow.sh`

### Implementation for User Story 3

- [X] T025 [US3] Document step-by-step digest refresh procedure in `docs/operations/deployment.md`
- [X] T026 [P] [US3] Add timed refresh run instructions and evidence template in `specs/001-pin-image-digests/quickstart.md`
- [X] T027 [P] [US3] Add PR evidence requirements for old/new digests and gate outputs in `.github/pull_request_template.md`
- [X] T028 [US3] Document refresh rollback and failure handling in `docs/operations/troubleshooting.md`
- [X] T029 [US3] Add explicit under-30-minute validation step in `docs/operations/deployment.md`

**Checkpoint**: US3 complete with repeatable and time-bounded refresh guidance.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency and end-to-end validation across stories.

- [X] T030 [P] Normalize `tag@digest` terminology in `docs/architecture/overview.md`
- [X] T031 Run full quickstart validation and update drift in `specs/001-pin-image-digests/quickstart.md`
- [X] T032 [P] Summarize final verification evidence in `specs/001-pin-image-digests/plan.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks all story phases
- **Phase 3 (US1)**: Depends on Phase 2; defines MVP
- **Phase 4 (US2)**: Depends on Phase 2; can run parallel with US1 if staffed
- **Phase 5 (US3)**: Depends on Phase 2; can run parallel with US1/US2 if staffed
- **Phase 6 (Polish)**: Depends on completion of selected stories

### User Story Dependencies

- **US1**: Independent after foundational gates
- **US2**: Independent after foundational gates; uses validator outputs
- **US3**: Independent after foundational gates; uses validation gates and docs

### Dependency Graph

`Setup -> Foundational -> (US1 || US2 || US3) -> Polish`

---

## Parallel Execution Examples

### User Story 1

```bash
Task T013 in docker/Dockerfile
Task T014 in docker/Dockerfile.ide
Task T015 in docker/memory.Dockerfile
```

### User Story 2

```bash
Task T021 in docs/operations/deployment.md
Task T022 in scripts/validate-base-image-digests.sh
```

### User Story 3

```bash
Task T026 in specs/001-pin-image-digests/quickstart.md
Task T027 in .github/pull_request_template.md
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1 and Phase 2
2. Complete Phase 3 (US1)
3. Validate local + CI + reproducibility evidence
4. Stop for MVP review

### Incremental Delivery

1. Deliver US1 deterministic pinning
2. Deliver US2 auditability
3. Deliver US3 refresh sustainability and timing validation
4. Execute Phase 6 polish

### Parallel Team Strategy

1. Team completes foundational tasks first
2. Then parallelize by story owners:
   - Engineer A: US1
   - Engineer B: US2
   - Engineer C: US3

---

## Notes

- `[P]` tasks are selected to minimize file conflicts.
- Test tasks are intentionally placed before implementation tasks inside each story phase.
- Each story includes independent test criteria aligned to `spec.md` success criteria.
