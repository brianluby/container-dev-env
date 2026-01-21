# Tasks: Container Base Image

**Input**: Design documents from `/specs/001-container-base-image/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included - acceptance tests defined in test-contract.md

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, etc.)
- Exact file paths included in descriptions

## Path Conventions

```text
Dockerfile                    # Main container definition
.dockerignore                 # Build context exclusions
scripts/
├── health-check.sh          # Container health check
└── test-container.sh        # Acceptance test runner
.github/
└── workflows/
    └── container-build.yml  # CI workflow
```

---

## Phase 1: Setup (Project Infrastructure)

**Purpose**: Initialize project structure and configuration files

- [X] T001 Create .dockerignore with standard exclusions in .dockerignore
- [X] T002 [P] Create scripts/ directory structure
- [X] T003 [P] Create .github/workflows/ directory structure

**Checkpoint**: Project structure ready for Dockerfile development

---

## Phase 2: Foundational (Base Dockerfile Skeleton)

**Purpose**: Create minimal Dockerfile that can build - BLOCKS all user stories

**⚠️ CRITICAL**: No user story work can begin until base Dockerfile exists

- [X] T004 Create Dockerfile with Debian Bookworm-slim base image (pinned date tag) in Dockerfile
- [X] T005 Add ARG declarations for USERNAME, USER_UID, USER_GID in Dockerfile
- [X] T006 Configure UTF-8 locale (LANG=en_US.UTF-8) in Dockerfile
- [X] T007 Set WORKDIR and basic ENV variables in Dockerfile

**Checkpoint**: Minimal Dockerfile builds successfully with `docker build .`

---

## Phase 3: User Story 1 - Build and Run Development Container (Priority: P1) 🎯 MVP

**Goal**: Buildable container with non-root user `dev` and working bash shell

**Independent Test**: `docker build . && docker run --rm IMG whoami` returns `dev`

### Implementation for User Story 1

- [X] T008 [US1] Create non-root user `dev` with UID/GID 1000 in Dockerfile
- [X] T009 [US1] Create home directory /home/dev with correct permissions in Dockerfile
- [X] T010 [US1] Set USER directive to switch to non-root user in Dockerfile
- [X] T011 [US1] Configure bash as default shell in Dockerfile
- [X] T012 [US1] Add .bashrc with colored prompt (PS1) in Dockerfile
- [X] T013 [US1] Configure HISTSIZE=1000 and HISTFILESIZE=2000 in Dockerfile
- [X] T014 [US1] Add ll and la aliases to .bashrc in Dockerfile
- [X] T015 [US1] Set proper PATH including /usr/local/bin in Dockerfile

**Checkpoint**: Container builds, runs as `dev` user with configured bash shell

---

## Phase 4: User Story 2 - Use Common Development Tools (Priority: P1)

**Goal**: All core dev tools (git, curl, wget, jq, make, build-essential) available

**Independent Test**: `docker run --rm IMG git --version && curl --version && jq --version`

### Implementation for User Story 2

- [X] T016 [US2] Add apt-get update layer in Dockerfile
- [X] T017 [US2] Install git via apt-get in Dockerfile
- [X] T018 [US2] Install curl and wget via apt-get in Dockerfile
- [X] T019 [US2] Install jq via apt-get in Dockerfile
- [X] T020 [US2] Install make via apt-get in Dockerfile
- [X] T021 [US2] Install build-essential via apt-get in Dockerfile
- [X] T022 [US2] Clean apt cache to reduce image size in Dockerfile

**Checkpoint**: All core tools respond to --version commands

---

## Phase 5: User Story 3 - Develop with Python and Node.js (Priority: P2)

**Goal**: Python 3.14+ with pip/uv and Node.js LTS 22.x with npm available

**Independent Test**: `docker run --rm IMG python3 --version && node --version`

### Implementation for User Story 3

- [X] T023 [US3] Add multi-stage FROM for Python 3.14-slim-bookworm in Dockerfile
- [X] T024 [US3] COPY Python binaries from python stage to final image in Dockerfile
- [X] T025 [US3] Verify pip is available and working in Dockerfile
- [X] T026 [US3] Install uv package manager via pip in Dockerfile
- [X] T027 [US3] Add NodeSource repository GPG key in Dockerfile
- [X] T028 [US3] Add NodeSource apt repository for Node 22.x in Dockerfile
- [X] T029 [US3] Install nodejs package via apt-get in Dockerfile
- [X] T030 [US3] Verify npm is available in Dockerfile

### Native Extension Validation for User Story 3

- [X] T030a [US3] Verify numpy installs successfully (tests Python native extensions) via docker run pip install
- [X] T030b [US3] Verify typescript installs successfully (tests Node native extensions) via docker run npm install -g

**Checkpoint**: Python 3.14+ and Node 22.x both respond to version commands; native extension packages install without errors

---

## Phase 6: User Story 4 - Build on Multiple Architectures (Priority: P2)

**Goal**: Container builds and runs on both arm64 and amd64

**Independent Test**: `docker buildx build --platform linux/amd64,linux/arm64 .`

### Implementation for User Story 4

- [X] T031 [US4] Verify Dockerfile uses multi-arch compatible base image in Dockerfile
- [X] T032 [US4] Add TARGETARCH ARG for architecture-aware builds in Dockerfile
- [X] T033 [US4] Create GitHub Actions workflow for multi-arch builds in .github/workflows/container-build.yml
- [X] T034 [US4] Configure docker/setup-buildx-action in CI workflow in .github/workflows/container-build.yml
- [X] T035 [US4] Configure docker/build-push-action with platform matrix in .github/workflows/container-build.yml
- [X] T036 [US4] Add weekly schedule trigger for security rebuilds in .github/workflows/container-build.yml

**Checkpoint**: CI builds both arm64 and amd64 images successfully

---

## Phase 7: User Story 5 - Perform Privileged Operations (Priority: P3)

**Goal**: Non-root user can use sudo for administrative tasks

**Independent Test**: `docker run --rm IMG sudo whoami` returns `root`

### Implementation for User Story 5

- [X] T037 [US5] Install sudo package via apt-get in Dockerfile
- [X] T038 [US5] Add dev user to sudoers with NOPASSWD in Dockerfile
- [X] T039 [US5] Verify sudo works without password prompt in Dockerfile

**Checkpoint**: `sudo whoami` returns root, `sudo apt-get update` succeeds

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Health checks, tests, documentation, and final validation

### Health Check

- [X] T040 [P] Create health-check.sh script in scripts/health-check.sh
- [X] T041 Add HEALTHCHECK instruction to Dockerfile in Dockerfile

### Acceptance Tests

- [X] T042 [P] Create test-container.sh acceptance test runner in scripts/test-container.sh
- [X] T043 [P] Add test job to CI workflow in .github/workflows/container-build.yml

### Validation

- [x] T044 Run full acceptance test suite with scripts/test-container.sh
- [x] T045 Verify image size is under 2GB
- [x] T046 Verify build time is under 5 minutes on CI
- [x] T047 Run quickstart.md validation steps

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational - Core container functionality
- **US2 (Phase 4)**: Depends on US1 - Adds tools to working container
- **US3 (Phase 5)**: Depends on US2 - Adds runtimes on top of tools
- **US4 (Phase 6)**: Can start after Foundational - Parallel with US1-3
- **US5 (Phase 7)**: Depends on US1 - Adds sudo to user configuration
- **Polish (Phase 8)**: Depends on all user stories

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational)
    ↓
    ├── Phase 3 (US1: Container/User) ──┐
    │       ↓                           │
    │   Phase 4 (US2: Tools)            │
    │       ↓                           │
    │   Phase 5 (US3: Runtimes)         │
    │       ↓                           │
    │   Phase 7 (US5: Sudo)             │
    │                                   │
    └── Phase 6 (US4: Multi-arch) ──────┘
                    ↓
            Phase 8 (Polish)
```

### Parallel Opportunities

- T001, T002, T003 can run in parallel (different directories)
- T040, T042, T043 can run in parallel (different files)
- US4 (Multi-arch) can be developed in parallel with US1-3 (mostly CI config)

---

## Parallel Example: Setup Phase

```bash
# Launch all setup tasks together:
Task: "Create .dockerignore with standard exclusions in .dockerignore"
Task: "Create scripts/ directory structure"
Task: "Create .github/workflows/ directory structure"
```

## Parallel Example: Polish Phase

```bash
# Launch all test/doc tasks together:
Task: "Create health-check.sh script in scripts/health-check.sh"
Task: "Create test-container.sh acceptance test runner in scripts/test-container.sh"
Task: "Add test job to CI workflow in .github/workflows/container-build.yml"
```

---

## Implementation Strategy

### MVP First (User Stories 1-2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (container builds, runs as dev)
4. Complete Phase 4: User Story 2 (core tools available)
5. **STOP and VALIDATE**: Run basic acceptance tests
6. Container is usable for basic development

### Full Implementation

1. MVP above, then:
2. Add User Story 3 (Python + Node.js)
3. Add User Story 4 (multi-arch CI)
4. Add User Story 5 (sudo)
5. Complete Phase 8 (Polish)
6. Full test suite passes

### Incremental Delivery

| Checkpoint | User Stories Complete | Value Delivered |
|------------|----------------------|-----------------|
| MVP | US1 + US2 | Usable dev container with tools |
| +Runtimes | +US3 | Python/Node development ready |
| +Multi-arch | +US4 | Works on all developer machines |
| +Sudo | +US5 | Full administrative flexibility |
| Complete | All + Polish | Production-ready base image |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Dockerfile tasks are sequential within a story (layer order matters)
- CI tasks (US4) can be developed in parallel with Dockerfile tasks
- Commit after each story completion for clean history
- Run test-container.sh after each story to validate
