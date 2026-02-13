# Phase 0 Research: Pin Base Images to Immutable Digests

## Decision 1: Pin base image references as `tag@digest`

- **Decision**: Use `FROM <image>:<version>@sha256:<digest>` for each external base image reference in scope.
- **Rationale**: Preserves readability of intended version while enforcing immutable content for deterministic builds.
- **Alternatives considered**:
  - Digest-only references: stricter but less human-readable in reviews.
  - Tag-only references: rejected due to upstream drift risk.

## Decision 2: Enforce full supported-architecture digest coverage

- **Decision**: Block completion if a selected digest does not support both `linux/amd64` and `linux/arm64`.
- **Rationale**: Avoids architecture split behavior and protects portability guarantees in the constitution.
- **Alternatives considered**:
  - Temporary single-arch exceptions: rejected due to reproducibility and reliability risk.
  - Per-arch divergent pins: rejected as higher maintenance and debugging complexity.

## Decision 3: Require both local and CI verification gates

- **Decision**: A digest pinning update is complete only when local verification and CI verification both pass.
- **Rationale**: Local checks provide fast feedback; CI provides authoritative multi-arch validation.
- **Alternatives considered**:
  - CI-only verification: slower feedback during development.
  - Local-only verification: insufficient release confidence.

## Decision 4: Keep blast radius constrained to explicit scope

- **Decision**: Update only these Dockerfiles: `Dockerfile`, `docker/Dockerfile`, `docker/Dockerfile.ide`, `docker/memory.Dockerfile`.
- **Rationale**: Delivers high-impact hardening with controlled change size and review complexity.
- **Alternatives considered**:
  - Repo-wide Dockerfile pinning: broader hardening but larger risk and effort.
  - Include spike Dockerfiles: rejected due to low value and higher churn.

## Decision 5: Digest refresh must be documented and repeatable

- **Decision**: Define a repeatable refresh flow: discover candidate digests, validate architecture coverage, apply updates, run local checks, pass CI.
- **Rationale**: Prevents stale pins and ad hoc update behavior.
- **Alternatives considered**:
  - Manual, undocumented updates: rejected due to inconsistency risk.
  - Fully automated updates without gate checks: rejected due to reduced control.
