# Data Model: Supply-Chain Hardening

**Branch**: `002-supply-chain-hardening` | **Date**: 2026-02-23

## Entities

### Pinned Dependency

A software component installed in the container image with a specific version and integrity verification artifact.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Package/tool name (e.g., `chezmoi`, `nodejs`, `uv`) |
| version | string | Pinned version (e.g., `v2.69.4`, `v22.22.0`) |
| source | enum | `apt`, `tarball`, `docker-stage` |
| checksum_amd64 | string (sha256) | SHA256 hash for amd64 artifact (null for apt packages) |
| checksum_arm64 | string (sha256) | SHA256 hash for arm64 artifact (null for apt packages) |
| download_url_pattern | string | URL template with `{version}` and `{arch}` placeholders |
| verification_method | enum | `sha256sum`, `gpg-signature`, `docker-digest`, `none` |

**Relationships**:
- Each Pinned Dependency is recorded in `checksums.sha256` (for tarball sources)
- Each Pinned Dependency appears as a component in the generated SBOM

**Lifecycle**:
- Created: When a tool is first added to the Dockerfile
- Updated: When version is bumped (new checksum computed, checksums.sha256 updated)
- Verified: At build time via `sha256sum -c` or Docker digest validation

### SBOM (Software Bill of Materials)

A machine-readable inventory of all software components in a published image.

| Field | Type | Description |
|-------|------|-------------|
| format | enum | `spdx-json` |
| image_digest | string (sha256) | Digest of the image this SBOM describes |
| architecture | enum | `amd64`, `arm64` |
| component_count | integer | Total number of components listed |
| os_package_count | integer | Number of dpkg/apt packages |
| created_at | datetime | When the SBOM was generated |
| attestation_digest | string (sha256) | Digest of the cosign attestation wrapping this SBOM |

**Relationships**:
- Linked to exactly one Image Signature (both reference the same image digest)
- Contains all Pinned Dependencies as components

**Lifecycle**:
- Generated: After successful image build (PR: local validation; publish: registry attachment)
- Attested: Signed via `cosign attest` and stored as OCI referrer
- Consumed: Downloaded by image consumers for auditing/vulnerability matching

### Image Signature

A cryptographic attestation binding a published image digest to the build pipeline identity.

| Field | Type | Description |
|-------|------|-------------|
| image_digest | string (sha256) | Digest of the signed image |
| signer_identity | string | GitHub Actions workflow URL (from Fulcio certificate SAN) |
| oidc_issuer | string | Always `https://token.actions.githubusercontent.com` |
| rekor_log_index | integer | Entry index in the Rekor transparency log |
| certificate_expiry | datetime | Fulcio short-lived cert expiry (~10 min from signing) |
| scope | enum | `architecture-digest`, `manifest` |

**Relationships**:
- One per architecture digest + one for the multi-arch manifest
- Co-located in GHCR alongside the image as OCI tag (`sha256-DIGEST.sig`)

**Lifecycle**:
- Created: After image push in the `build` job (per-arch) and `merge` job (manifest)
- Verified: By consumers using `cosign verify` with identity and issuer flags
- Immutable: Once recorded in Rekor, the signature entry cannot be altered

### Verification Record

The documented procedure and artifacts enabling consumers to verify images.

| Field | Type | Description |
|-------|------|-------------|
| verify_command | string | The `cosign verify` command template |
| attest_command | string | The `cosign verify-attestation` command template |
| identity_pattern | string | Expected certificate identity regexp |
| oidc_issuer | string | Expected OIDC issuer URL |
| documentation_path | string | Path to `docs/image-verification.md` |

**Relationships**:
- References Image Signature identity fields
- References SBOM attestation type

## State Diagram

```
Dockerfile Source
    │
    ▼
[Build] ──── checksum verification ──── FAIL → build aborts
    │
    ├── PR build: generate SBOM locally → validate coverage → done
    │
    └── Publish build:
         │
         ▼
    [Push per-arch digest] → [Sign per-arch digest]
         │
         ▼
    [Create multi-arch manifest] → [Sign manifest]
         │
         ▼
    [Generate SBOM] → [Attest SBOM] → [Upload artifact]
```
