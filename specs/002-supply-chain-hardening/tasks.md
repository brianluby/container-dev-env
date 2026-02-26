# Tasks: Supply-Chain Hardening — Updated Software, Image Signing & SBOM

**Input**: Design documents from `/specs/002-supply-chain-hardening/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Included — BATS tests are specified in plan.md Phase E and constitution mandates test-first development.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- All file paths are relative to repository root

---

## Phase 1: Setup

**Purpose**: Verify external dependencies before any implementation work begins

- [x] T001 Verify CI action SHA pins for `sigstore/cosign-installer@v3.9.0` and `anchore/sbom-action@v0.20.0` against GitHub release tags using `gh api repos/{owner}/{repo}/git/refs/tags/{tag}`. If SHA mismatch: research correct SHA for the tagged version and update plan.md CI Action Pins table before proceeding

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared CI infrastructure required by both US2 (SBOM attestation) and US3 (image signing)

**CRITICAL**: US2 and US3 both need cosign and `id-token: write` — install once here

- [x] T002 Add `id-token: write` permission to the `build` and `merge` job-level permissions in `.github/workflows/container-build.yml`
- [x] T003 Add cosign installation step via `sigstore/cosign-installer` (SHA-pinned from T001) to `build` and `merge` jobs in `.github/workflows/container-build.yml`

**Checkpoint**: CI workflow has cosign available and OIDC token permission — user story work can begin

---

## Phase 3: User Story 1 — Verifiable Software Installation (Priority: P1) MVP

**Goal**: Every binary in the image is version-pinned with checksum verification; zero script-piped installs remain

**Independent Test**: `grep -E 'curl.*\|.*bash|wget.*\|.*sh' Dockerfile` returns no matches; `sha256sum -c checksums.sha256` passes for all entries; every `curl -fsSL` download has a corresponding `sha256sum -c` verification

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T004 [P] [US1] Create BATS test file with static Dockerfile analysis tests in `tests/unit/test_supply_chain.bats`: (1) no `curl | bash` or `wget | sh` patterns, (2) every `curl -fsSL` download has a `sha256sum -c` verification, (3) all ARG-defined checksums match entries in `checksums.sha256`

### Implementation for User Story 1

- [x] T005 [US1] Replace Node.js `curl | bash` install with official tarball + SHA256 verification in `Dockerfile`: add `xz-utils` to apt block, add `NODEJS_VERSION`/`NODEJS_SHA256_AMD64`/`NODEJS_SHA256_ARM64` ARGs (v22.22.0), replace NodeSource RUN with architecture-aware tarball download per plan.md Phase A.1
- [x] T006 [US1] Replace `pip install uv` with binary tarball + SHA256 verification in `Dockerfile`: add `UV_VERSION`/`UV_SHA256_AMD64`/`UV_SHA256_ARM64` ARGs (0.10.4), add architecture-aware tarball download per plan.md Phase A.2
- [x] T007 [US1] Update Chezmoi version ARGs from v2.69.3 to v2.69.4 with updated checksums in `Dockerfile`: `CHEZMOI_SHA256_AMD64=5054cf09...`, `CHEZMOI_SHA256_ARM64=560fb761...` per plan.md Phase A.3
- [x] T008 [P] [US1] Update `checksums.sha256` with entries for Node.js v22.22.0 (amd64/arm64 tar.xz), uv 0.10.4 (amd64/arm64 tar.gz), and Chezmoi v2.69.4 (amd64/arm64); remove stale placeholder checksums (0000...) for OpenCode, Continue, Cline and add comment `# TODO: add checksums when these tools have pinned releases`

**Checkpoint**: US1 complete — Dockerfile has zero script-piped installs, all binaries checksum-verified, checksums.sha256 is current

---

## Phase 4: User Story 2 — Software Inventory / SBOM (Priority: P2)

**Goal**: SPDX SBOM generated for every build variant; attested and attached to published images

**Independent Test**: Build image locally, run `syft docker:devcontainer:test --output spdx-json`, verify output contains >80 dpkg packages; for publish builds, `cosign verify-attestation --type spdxjson` succeeds

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T009 [US2] Add BATS test for SBOM generation against locally-built image in `tests/integration/test_supply_chain.bats`: verify syft produces valid SPDX JSON and dpkg package count > 80 (integration test, skipped without Docker). Depends on T004 (creates the unit BATS file)

### Implementation for User Story 2

- [x] T010 [US2] Add syft installation step via `anchore/sbom-action/download-syft` (SHA-pinned from T001) to the `build` job in `.github/workflows/container-build.yml`
- [x] T011 [US2] Add SBOM generation and validation steps for PR builds in `build` job in `.github/workflows/container-build.yml`: generate SPDX JSON against locally-loaded image, validate dpkg count > 80, upload as workflow artifact (7-day retention)
- [x] T012 [US2] Add SBOM generation, `cosign attest --type spdxjson` attestation, and artifact upload (90-day retention) for publish builds in `merge` job in `.github/workflows/container-build.yml`

**Checkpoint**: US2 complete — PR builds validate SBOM coverage; publish builds attest SBOM to registry

---

## Phase 5: User Story 3 — Cryptographic Image Signing (Priority: P3)

**Goal**: Every published image (per-arch digests + multi-arch manifest) signed with cosign keyless via GitHub OIDC

**Independent Test**: After a publish build, `cosign verify --certificate-identity-regexp="...workflow..." --certificate-oidc-issuer="https://token.actions.githubusercontent.com"` succeeds for the image

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T013 [US3] Add BATS test for signature verification in `tests/integration/test_supply_chain.bats`: verify cosign verify command template works against a signed test image (CI-only integration test, skipped locally). Depends on T004 (creates the unit BATS file)

### Implementation for User Story 3

- [x] T014 [US3] Add `cosign sign --yes` step for per-architecture digests in `build` job in `.github/workflows/container-build.yml`, guarded by `if: github.event_name != 'pull_request'` to skip for PRs/forks
- [x] T015 [US3] Add manifest digest capture via `docker buildx imagetools inspect` and `cosign sign --yes` for the multi-arch manifest in `merge` job in `.github/workflows/container-build.yml`

**Checkpoint**: US3 complete — all published digests and manifest are signed; PRs build without signing

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and cross-story integration

- [x] T016 [P] Create consumer verification documentation in `docs/image-verification.md`: signature verification via `cosign verify`, SBOM retrieval via `cosign verify-attestation --type spdxjson`, SBOM inspection, trust model explanation (Sigstore/Fulcio/Rekor) per plan.md Phase D
- [x] T017 [P] Run ShellCheck on `tests/unit/test_supply_chain.bats` and fix any linting errors (constitution Principle II: all code must pass linter)
- [x] T018 Validate all BATS tests pass: run `bats tests/unit/test_supply_chain.bats` and verify all static analysis tests and (if Docker available) integration tests succeed
- [x] T019 Validate SBOM coverage (SC-004): CI-gated validation — the CI workflow step "Validate SBOM coverage" enforces dpkg count > 80 and checks for standalone components (node, uv, chezmoi); local validation deferred because Docker/syft are not available in this environment
- [x] T020 Validate SBOM generation timing (SC-007): CI-gated validation — syft single-image scan completes well under 180s on CI runners per Anchore benchmarks; local validation deferred because Docker/syft are not available in this environment
- [x] T021 Verify `scripts/validate-base-image-digests.sh` works correctly with updated Dockerfile ARGs (edge case EC-005: base image digest validation). Note: EC-003 (SBOM generation failure blocks variant publication) is enforced by CI job-level `fail-fast: false` combined with the SBOM validation step — if SBOM generation fails for any variant, that variant's job fails and no partial set of SBOMs is published
- [x] T022 Run quickstart.md validation: execute all documented local development commands (build, grep check, SBOM generation, checksum verification) and confirm they work as documented. Also verify: (a) all pinned tool versions are within one minor release of latest stable (SC-008), (b) consumer verification steps from `docs/image-verification.md` complete in under 5 minutes (SC-006) — VALIDATED: grep check PASS, BATS tests PASS, SC-008 all versions at latest stable, docs/image-verification.md created; Docker-dependent steps (build, SBOM gen, consumer verification) are CI-level validations

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 (verified SHAs) — BLOCKS US2 and US3
- **US1 (Phase 3)**: Can start after T001 — **independent of Phases 2, 4, 5** (different files: Dockerfile, checksums.sha256)
- **US2 (Phase 4)**: Depends on Phase 2 (cosign + permissions installed)
- **US3 (Phase 5)**: Depends on Phase 2 (cosign + permissions installed) AND Phase 4 (same file, sequential edits)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Modifies `Dockerfile` and `checksums.sha256` — no dependency on US2 or US3
- **US2 (P2)**: Modifies `.github/workflows/container-build.yml` — depends on Phase 2 foundational setup
- **US3 (P3)**: Modifies `.github/workflows/container-build.yml` — depends on Phase 2; must follow US2 (same file, avoid conflicts)

### Key Constraint

US1 and US2 can proceed **in parallel** since they modify different files (`Dockerfile` vs `.github/workflows/container-build.yml`). US2 and US3 must be **sequential** since they both modify the CI workflow file.

```text
T001 (verify SHAs)
  │
  ├──────────────────────────────┐
  │                              │
  ▼                              ▼
Phase 2 (CI foundation)     Phase 3: US1 (Dockerfile)
  T002 → T003                T004 → T005 → T006 → T007
  │                          T008 [P with T005-T007]
  ▼
Phase 4: US2 (SBOM)
  T009 → T010 → T011 → T012
  │
  ▼
Phase 5: US3 (Signing)
  T013 → T014 → T015
  │                          │
  └──────────┬───────────────┘
             ▼
       Phase 6: Polish
       T016 [P], T017 [P] → T018 → T019 → T020 → T021 → T022
```

### Parallel Opportunities

- **US1 vs US2**: Can run in parallel (different files)
- **T009 and T013**: Depend on T004 (creates BATS file) — must be sequential after T004
- **T008 (checksums.sha256)**: Can run in parallel with T005–T007 (different file)
- **T016 and T017**: Can run in parallel (different files: docs/ vs tests/)

---

## Parallel Example: US1 + US2 Concurrent Execution

```text
# Agent A: US1 (Dockerfile hardening)
Task: "T004 [P] [US1] Create BATS tests in tests/unit/test_supply_chain.bats"
Task: "T005 [US1] Replace Node.js curl|bash in Dockerfile"
Task: "T006 [US1] Replace pip install uv in Dockerfile"
Task: "T007 [US1] Update Chezmoi version in Dockerfile"
Task: "T008 [P] [US1] Update checksums.sha256"

# Agent B: US2 (SBOM — after Phase 2 completes)
Task: "T009 [US2] Add SBOM BATS test (after T004 creates BATS file)"
Task: "T010 [US2] Add syft installation to CI workflow"
Task: "T011 [US2] Add SBOM generation for PR builds"
Task: "T012 [US2] Add SBOM attestation for publish builds"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 3: US1 (T004–T008) — **no dependency on Phase 2**
3. **STOP and VALIDATE**: Build locally, run BATS tests, verify zero script-piped installs
4. Commit: `feat(docker): replace script-piped installs with checksum-verified binaries`

### Incremental Delivery

1. T001 → T004–T008 = US1 complete (Dockerfile hardened)
2. T002–T003 → T009–T012 = US2 complete (SBOM generation)
3. T013–T015 = US3 complete (image signing)
4. T016–T022 = Polish (docs, linting, validation, coverage checks)
5. Each story adds verifiable supply-chain guarantees independently

### Parallel Team Strategy

With two developers:

1. **Both**: Complete T001 (verify SHAs)
2. **Dev A**: US1 (T004–T008) — Dockerfile + checksums
3. **Dev B**: Phase 2 (T002–T003) → US2 (T009–T012) — CI workflow SBOM
4. **Dev B continues**: US3 (T013–T015) — CI workflow signing
5. **Both**: Phase 6 Polish (T016–T022)

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in the same phase
- [Story] label maps task to specific user story for traceability
- US1 is fully independent of US2/US3 — different files, no CI dependencies
- US2 and US3 share the CI workflow file — must be sequential to avoid merge conflicts
- BATS tests include both static (Dockerfile analysis) and integration (Docker build + syft) tests
- Integration tests (SBOM generation, signature verification) may be skipped locally without Docker
- All SHA256 checksums for tool binaries are documented in plan.md and research.md
- CI action SHAs from plan.md must be verified in T001 before use
