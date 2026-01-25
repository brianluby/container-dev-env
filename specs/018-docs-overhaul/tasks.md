---

description: "Task list for 018-docs-overhaul"
---

# Tasks: Documentation Overhaul

**Input**: Design documents from `specs/018-docs-overhaul/`
**Prerequisites**: `specs/018-docs-overhaul/plan.md`, `specs/018-docs-overhaul/spec.md`, `specs/018-docs-overhaul/research.md`, `specs/018-docs-overhaul/data-model.md`, `specs/018-docs-overhaul/contracts/`, `specs/018-docs-overhaul/quickstart.md`

**Tests**: Not explicitly requested for this docs-only feature. If any helper scripts are introduced (e.g., docs link checking), add BATS tests first, run ShellCheck, and wire checks into CI (constitution).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format

`- [ ] T### [P] [US#] Description with file path`

---

## Phase 1: Setup (Shared Documentation Infrastructure)

**Purpose**: Establish the target documentation structure and shared templates

- [x] T001 Inventory existing documentation sources and duplicates; capture the troubleshooting baseline list for SC-008 in `specs/018-docs-overhaul/doc-audit.md`
- [x] T002 Decide keep/move/delete/deprecate actions for each item in `specs/018-docs-overhaul/doc-audit.md`
- [x] T003 Apply doc audit actions across `docs/**` and `README.md` (remove/move/deprecate outdated/duplicate content; add pointer notes where needed)
- [x] T004 Create target docs directories `docs/getting-started/`, `docs/features/`, `docs/operations/`, `docs/architecture/`, `docs/contributing/`, `docs/reference/`
- [x] T005 [P] Create category index stubs `docs/getting-started/index.md`, `docs/features/index.md`, `docs/operations/index.md`, `docs/architecture/index.md`, `docs/contributing/index.md`, `docs/reference/index.md`
- [x] T006 [P] Add a reusable page template `docs/_page-template.md` aligned with `specs/018-docs-overhaul/contracts/page-template.md`
- [x] T007 [P] Create docs navigation map stub `docs/navigation.md` updated for the new category index paths
- [x] T008 [P] Create canonical glossary at `docs/glossary.md` by migrating content from `docs/domain/glossary.md` and leave a pointer note in `docs/domain/glossary.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared conventions and entry point wiring that all user stories depend on

**CRITICAL**: No user story work should begin until the docs entry point + navigation conventions are in place

- [x] T009 Update `README.md` to be the single docs entry point (orientation + links to each `docs/*/index.md`)
- [x] T010 [P] Add docs "search" guidance page `docs/reference/search.md` documenting navigation-first usage + GitHub/IDE search expectations
- [x] T011 [P] Add docs versioning policy page `docs/reference/versioning.md` (docs target `main`; per-page "Applies to" / "Tested with" notes when needed)
- [x] T012 [P] Update docs composition guidance in `docs/composition-rules.md` to require Prerequisites/Related/Next steps sections for user-facing docs pages (exclude `docs/_page-template.md` and pointer-only legacy files)
- [x] T013 Update `docs/navigation.md` quick reference links to point at the new category index pages and canonical glossary `docs/glossary.md`

**Checkpoint**: Foundation ready - user story implementation can proceed in parallel

---

## Phase 3: User Story 1 - New User Onboarding (Priority: P1) MVP

**Goal**: A new user can understand the project and reach a working dev container using documentation alone

**Independent Test**: Follow `README.md` -> `docs/getting-started/index.md` from a fresh clone to a working container shell; resolve a simulated setup issue via `docs/getting-started/troubleshooting.md`

- [x] T014 [US1] Move and refactor onboarding guide from `docs/getting-started.md` into `docs/getting-started/index.md` (update internal links)
- [x] T015 [P] [US1] Add prerequisites + verification checklist to `docs/getting-started/index.md` (health check + compose commands)
- [x] T016 [P] [US1] Create troubleshooting guide `docs/getting-started/troubleshooting.md` based on `docs/pre-existing-failures.md` with clear fixes
- [x] T017 [P] [US1] Add host OS variance notes (macOS/Linux/Windows/WSL2) to `docs/getting-started/index.md` (what changes + where to look)
- [x] T018 [P] [US1] Add host OS variance troubleshooting sections to `docs/getting-started/troubleshooting.md` (Docker Desktop vs Engine, file sharing, WSL2, line endings)
- [x] T019 [US1] Update `README.md` quick start section to match `docs/getting-started/index.md` steps exactly
- [x] T020 [P] [US1] Ensure `docs/navigation.md` onboarding pointer targets `docs/getting-started/index.md` (not `docs/getting-started.md`)

**Checkpoint**: US1 complete - a new user can onboard end-to-end from docs only

---

## Phase 4: User Story 2 - Feature Discovery and Usage (Priority: P2)

**Goal**: Users can enable any major feature via self-contained guides + find configuration reference

**Independent Test**: Pick any feature guide linked from `docs/features/index.md` and complete prerequisites/setup/config/verification without reading unrelated pages

- [x] T021 [US2] Populate `docs/features/index.md` with a feature catalog that links to each standalone guide
- [x] T022 [P] [US2] Create AI assistants guide `docs/features/ai-assistants.md` (OpenCode, Claude Code): value, prerequisites, setup, configuration, verification
- [x] T023 [P] [US2] Create secrets management guide `docs/features/secrets-management.md` from `docs/secrets-guide.md` (template sections + verification)
- [x] T024 [P] [US2] Create MCP integration guide `docs/features/mcp.md` using `docs/quickstarts/012-mcp-integration.md` and `src/mcp/defaults/README.md`
- [x] T025 [P] [US2] Create voice input guide `docs/features/voice-input.md` from `docs/quickstarts/015-voice-input.md`
- [x] T026 [P] [US2] Create mobile access guide `docs/features/mobile-access.md` from `docs/quickstarts/016-mobile-access.md`
- [x] T027 [P] [US2] Create IDE extensions guide `docs/features/ide-extensions.md` from `docs/quickstarts/009-ai-ide-extensions.md`
- [x] T028 [P] [US2] Create containerized IDE guide `docs/features/containerized-ide.md` from `docs/quickstarts/008-containerized-ide.md`
- [x] T029 [P] [US2] Create persistent memory guide `docs/features/persistent-memory.md` from `docs/quickstarts/013-persistent-memory.md`
- [x] T030 [P] [US2] Create dotfiles/Chezmoi guide `docs/features/dotfiles.md` (what it is, setup, customization, pitfalls)
- [x] T031 [US2] Create configuration reference `docs/reference/configuration.md` following `specs/018-docs-overhaul/contracts/config-reference-contract.md`
- [x] T032 [US2] Deprecate quickstarts index by updating `docs/quickstarts/README.md` to point to `docs/features/index.md`
- [x] T033 [P] [US2] Convert `docs/quickstarts/008-containerized-ide.md` into a pointer/deprecation stub to `docs/features/containerized-ide.md`
- [x] T034 [P] [US2] Convert `docs/quickstarts/009-ai-ide-extensions.md` into a pointer/deprecation stub to `docs/features/ide-extensions.md`
- [x] T035 [P] [US2] Convert `docs/quickstarts/012-mcp-integration.md` into a pointer/deprecation stub to `docs/features/mcp.md`
- [x] T036 [P] [US2] Convert `docs/quickstarts/013-persistent-memory.md` into a pointer/deprecation stub to `docs/features/persistent-memory.md`
- [x] T037 [P] [US2] Convert `docs/quickstarts/015-voice-input.md` into a pointer/deprecation stub to `docs/features/voice-input.md`
- [x] T038 [P] [US2] Convert `docs/quickstarts/016-mobile-access.md` into a pointer/deprecation stub to `docs/features/mobile-access.md`

**Checkpoint**: US2 complete - any feature is discoverable + guide is self-contained

---

## Phase 5: User Story 3 - Contributor Onboarding (Priority: P3)

**Goal**: A new contributor can understand structure, workflow, and run tests locally

**Independent Test**: Follow `docs/contributing/index.md` to set up dev env, make a small change, run the same checks CI would run

- [x] T039 [US3] Populate contributor entry point `docs/contributing/index.md` (how to start contributing + links to workflow/testing)
- [x] T040 [P] [US3] Document spec-driven workflow in `docs/contributing/workflow.md` referencing `docs/spec-driven-development-pipeline.md` and include a PR checklist with the FR-013 rule (docs updated in the same PR)
- [x] T041 [P] [US3] Create testing guide `docs/contributing/testing.md` consolidating `docs/test-matrix.md` and meeting FR-008
- [x] T042 [P] [US3] Document repository layout in `docs/contributing/project-structure.md` (where `docker/`, `scripts/`, `src/`, `specs/`, `tests/` live)
- [x] T043 [P] [US3] Update `docs/navigation.md` contributor pointer to `docs/contributing/index.md`

**Checkpoint**: US3 complete - new contributor can follow docs to contribute

---

## Phase 6: User Story 4 - Operational Reference (Priority: P3)

**Goal**: Users can troubleshoot and run routine maintenance via runbooks with verification steps

**Independent Test**: Simulate an operational task (volume cleanup, secret rotation, container rebuild) and follow a runbook to completion including verification

- [x] T044 [US4] Populate operations index `docs/operations/index.md` with runbook catalog + troubleshooting entry points
- [x] T045 [P] [US4] Create volume cleanup runbook `docs/operations/volume-cleanup.md` with verification steps
- [x] T046 [P] [US4] Create secret rotation runbook `docs/operations/secret-rotation.md` with verification steps
- [x] T047 [P] [US4] Create container rebuild runbook `docs/operations/container-rebuild.md` with verification steps
- [x] T048 [P] [US4] Refactor `docs/operations/deployment.md` to match the page template (prereqs/related/next + applicability notes if needed)
- [x] T049 [US4] Add an operations troubleshooting page `docs/operations/troubleshooting.md` seeded from `docs/pre-existing-failures.md` and link it from `docs/getting-started/troubleshooting.md`

**Checkpoint**: US4 complete - operational tasks are documented as runbooks

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Reachability, consistency, and quality gates across the docs set

- [x] T050 [P] Normalize glossary references across docs by updating links to `docs/glossary.md` (fix references from `docs/domain/glossary.md`)
- [x] T051 [P] Add "Applies to" / "Tested with" notes where needed in `docs/getting-started/index.md` and `docs/features/*.md`
- [x] T052 [P] Refactor architecture landing page `docs/architecture/index.md` to link to `docs/architecture/overview.md` and key ADRs in `docs/decisions/`
- [x] T053 [P] Verify/update `docs/architecture/overview.md` to include a component diagram, key data flows, and links to relevant ADRs in `docs/decisions/` (FR-006)
- [x] T054 [P] Update `docs/navigation.md` to reflect final paths for onboarding/features/contributing/operations/architecture/reference
- [x] T055 [P] Retrofit Prerequisites/Related/Next steps sections across user-facing docs pages under `docs/` (exclude `docs/_page-template.md`, `docs/navigation.md`, `docs/quickstarts/**`, and pointer-only legacy files)
- [x] T056 [P] Add failing-first BATS tests `tests/unit/test_check_doc_links.bats` for `scripts/check-doc-links.sh` (pass on valid links; fail on broken links) covering `README.md` and `docs/`
- [x] T057 Implement `scripts/check-doc-links.sh` (validate links in `README.md` and `docs/`) and run ShellCheck on `scripts/check-doc-links.sh`
- [x] T058 Update `.github/workflows/worktree-tests.yml` to trigger on docs changes, run ShellCheck on `scripts/`, run unit BATS tests including `tests/unit/test_check_doc_links.bats`, and run `scripts/check-doc-links.sh` as a docs link integrity gate
- [x] T059 Run link validation via `scripts/check-doc-links.sh` and fix any broken links in `README.md` and under `docs/`
- [x] T060 Run the manual validation checklist in `specs/018-docs-overhaul/quickstart.md` and record any gaps as follow-up tasks in `docs/consolidated-improvement-backlog.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 (Setup) -> Phase 2 (Foundational) -> User Stories (Phases 3-6) -> Phase 7 (Polish)

### User Story Dependencies

- US1 is the MVP and should be completed first after Foundational.
- US2/US3/US4 can proceed in parallel after Foundational, but should not break US1 navigation/entry point.

### Parallel Opportunities

- In Phase 1, tasks T005-T008 can be done in parallel ([P]).
- In Phase 2, tasks T010-T012 can be done in parallel ([P]).
- In US2, tasks T022-T030 and T033-T038 are parallelizable across different files ([P]).
- In US3 and US4, most page creations are parallelizable ([P]).

---

## Parallel Example: User Story 2

```text
Task: "Create secrets management guide docs/features/secrets-management.md"
Task: "Create MCP integration guide docs/features/mcp.md"
Task: "Create voice input guide docs/features/voice-input.md"
Task: "Create mobile access guide docs/features/mobile-access.md"
Task: "Create IDE extensions guide docs/features/ide-extensions.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2 (structure + entry point + conventions)
2. Complete Phase 3 (US1)
3. Validate US1 using `specs/018-docs-overhaul/spec.md` acceptance scenarios

### Incremental Delivery

1. Land US1 as a complete onboarding path
2. Add US2 feature guides incrementally (one guide at a time)
3. Add US3 contributor docs
4. Add US4 runbooks
5. Finish with Phase 7 consistency + link checking
