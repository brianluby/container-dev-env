# Feature Specification: Pin Base Images to Immutable Digests

**Feature Branch**: `001-pin-image-digests`  
**Created**: 2026-02-12  
**Status**: Draft  
**Input**: User description: "Pin all base images to immutable digests - Impact: High. FROM lines are tag-based in multiple Dockerfiles (Dockerfile, docker/Dockerfile, docker/Dockerfile.ide, docker/memory.Dockerfile), which allows upstream drift."

## Clarifications

### Session 2026-02-12

- Q: What is the exact Dockerfile scope for digest pinning? -> A: Pin only `Dockerfile`, `docker/Dockerfile`, `docker/Dockerfile.ide`, and `docker/memory.Dockerfile`.
- Q: How should missing digest coverage for supported architectures be handled? -> A: Fail the change until full supported-architecture digest coverage is available.
- Q: What verification gate is required to complete digest pinning updates? -> A: Both local and CI verification are required.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deterministic Container Builds (Priority: P1)

As a maintainer, I want all in-scope container base image references to use immutable digests so builds are repeatable and do not change unexpectedly when upstream tags are moved.

**Why this priority**: This directly addresses supply-chain drift risk and is the core security outcome of the feature.

**Independent Test**: Update all in-scope image references to immutable digests, run build validation, and confirm repeated builds resolve the same base images across runs.

**Acceptance Scenarios**:

1. **Given** a repository with tag-based base image references in the in-scope Dockerfiles, **When** the feature is applied, **Then** each in-scope base image reference uses an immutable digest.
2. **Given** the same commit is built at two different times, **When** the build process resolves base images, **Then** the same base image artifacts are used both times.

---

### User Story 2 - Clear Scope and Auditability (Priority: P2)

As a reviewer, I want an explicit inventory of which Dockerfiles were updated so I can verify coverage quickly and assess change impact.

**Why this priority**: Clear scope prevents partial hardening and reduces review ambiguity.

**Independent Test**: Compare the documented in-scope Dockerfiles against repository Dockerfiles and verify each in-scope file has digest-pinned base image references.

**Acceptance Scenarios**:

1. **Given** the feature branch, **When** a reviewer checks the specification and changed files, **Then** the four targeted Dockerfiles are clearly listed and each is covered by the change.
2. **Given** an in-scope Dockerfile contains multiple base image declarations, **When** review is performed, **Then** each declaration in that file is pinned to an immutable digest.

---

### User Story 3 - Sustainable Digest Refresh Process (Priority: P3)

As an operations owner, I want a documented refresh workflow for updating pinned digests so security updates can be adopted in a controlled, traceable way.

**Why this priority**: Pinning without a refresh process can lead to stale dependencies and delayed security patch adoption.

**Independent Test**: Follow the documented refresh workflow end to end and verify a maintainer can update digests and validate builds without ad hoc decisions.

**Acceptance Scenarios**:

1. **Given** a maintainer needs to update base images, **When** they follow the documented workflow, **Then** they can identify new digests, apply updates, and run verification checks successfully.

---

### Edge Cases

- A base image may be retired or replaced upstream, requiring a controlled fallback selection.
- Multi-stage Dockerfiles may reference both internal stages and external base images; only external base images should be digest-pinned.
- A digest refresh may change the resulting image size or tool availability and must still satisfy existing quality thresholds.
- If a selected base image cannot provide digest coverage for all supported architectures, the update is blocked until a compliant image reference is chosen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST replace tag-only external base image references with immutable digest references in the following Dockerfiles: `Dockerfile`, `docker/Dockerfile`, `docker/Dockerfile.ide`, and `docker/memory.Dockerfile`.
- **FR-002**: The system MUST ensure every external base image declaration in each in-scope Dockerfile is pinned, including all relevant stages.
- **FR-003**: The system MUST keep both existing local container verification and CI container build verification passing for `linux/amd64` and `linux/arm64` after digest pinning.
- **FR-004**: The system MUST provide a documented procedure for digest refresh that includes discovery, update, and validation steps.
- **FR-005**: The system MUST define validation criteria showing that pinned references are present and builds remain successful in both local and CI verification workflows.
- **FR-006**: The system MUST record assumptions and scope boundaries so reviewers can distinguish in-scope Dockerfiles from out-of-scope Dockerfiles.
- **FR-007**: The system MUST block completion if any in-scope base image lacks digest coverage for all currently supported architectures.

### Out of Scope

- Updating Dockerfiles outside `Dockerfile`, `docker/Dockerfile`, `docker/Dockerfile.ide`, and `docker/memory.Dockerfile`.
- Applying digest pinning to spike or experimental Dockerfiles.

### Key Entities *(include if feature involves data)*

- **In-Scope Dockerfile**: A container definition file explicitly covered by this feature; includes path, base image declarations, and stage count.
- **Base Image Reference**: The external upstream image identifier used in a Dockerfile stage; includes repository, tag context, and immutable digest.
- **Digest Refresh Record**: A change record capturing old and new digest values, reason for update, and verification outcome.

### Assumptions

- Existing CI and local verification workflows remain the source of truth for confirming build success.
- No change is required to container feature scope beyond hardening base image references and documenting refresh guidance.
- Out-of-scope Dockerfiles (for spikes or deprecated experiments) may remain unchanged unless explicitly added to scope in a future feature.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of external base image declarations in the four in-scope Dockerfiles use immutable digest references.
- **SC-002**: 100% of in-scope container builds complete successfully after digest pinning in both local and CI verification runs.
- **SC-003**: Rebuilding the same commit at two separate times yields no unexpected base image reference changes for in-scope Dockerfiles.
- **SC-004**: A maintainer can execute the documented digest refresh workflow and complete an update-and-verify cycle in under 30 minutes.
