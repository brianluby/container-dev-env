# Data Model: Pin Base Images to Immutable Digests

## Entity: InScopeDockerfile

- **Description**: Dockerfile explicitly included in this feature scope.
- **Fields**:
  - `path` (string, unique): Repository-relative file path.
  - `external_from_count` (integer, >=0): Number of external `FROM` declarations.
  - `in_scope` (boolean): Must be `true` for this feature.
- **Validation Rules**:
  - `path` must be one of: `Dockerfile`, `docker/Dockerfile`, `docker/Dockerfile.ide`, `docker/memory.Dockerfile`.
  - Every external `FROM` in this entity must map to at least one `BaseImageReference`.

## Entity: BaseImageReference

- **Description**: An external base image used in a `FROM` statement.
- **Fields**:
  - `dockerfile_path` (string, foreign key -> InScopeDockerfile.path)
  - `stage_name` (string, optional): Docker stage alias if present.
  - `image_repository` (string): Upstream image repository.
  - `image_tag` (string): Human-readable version tag.
  - `image_digest` (string): Immutable digest (`sha256:*`).
  - `platforms` (set<string>): Supported platforms from resolved image metadata.
- **Validation Rules**:
  - `image_digest` must match `^sha256:[a-f0-9]{64}$`.
  - `platforms` must include both `linux/amd64` and `linux/arm64`.
  - No tag-only external references are allowed in-scope.

## Entity: VerificationRun

- **Description**: Evidence that pinning changes satisfy required gates.
- **Fields**:
  - `run_type` (enum): `local` or `ci`.
  - `status` (enum): `pass` or `fail`.
  - `timestamp` (datetime)
  - `evidence_ref` (string): Link/path to output log or workflow run.
- **Validation Rules**:
  - At least one passing `local` run and one passing `ci` run are required for completion.

## Entity: DigestRefreshRecord

- **Description**: Audit record for updating pinned digests.
- **Fields**:
  - `reference_id` (string): Identifier for the affected base image reference.
  - `old_digest` (string)
  - `new_digest` (string)
  - `reason` (string)
  - `coverage_check` (enum): `pass` or `fail`.
  - `verification_summary` (string)
- **Validation Rules**:
  - `old_digest` and `new_digest` must differ.
  - `coverage_check` must be `pass` before merge readiness.

## Relationships

- `InScopeDockerfile` 1..* -> `BaseImageReference`
- `BaseImageReference` 1..* -> `DigestRefreshRecord`
- Feature completion requires `VerificationRun(local=pass)` AND `VerificationRun(ci=pass)`.

## State Transitions

### BaseImageReference Lifecycle

1. `unresolved` -> `pinned` (digest added)
2. `pinned` -> `coverage_validated` (amd64 + arm64 confirmed)
3. `coverage_validated` -> `verified` (local and CI runs pass)
4. `verified` -> `released` (merged)

Invalid transition:

- `pinned` -> `released` is not allowed without coverage and verification.
