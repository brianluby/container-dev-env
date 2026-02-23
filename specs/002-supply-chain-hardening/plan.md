# Implementation Plan: Supply-Chain Hardening — Updated Software, Image Signing & SBOM

**Branch**: `002-supply-chain-hardening` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-supply-chain-hardening/spec.md`

## Summary

Harden the container image supply chain by: (1) eliminating the Node.js `curl | bash` install and replacing `pip install uv` with checksum-verified binary downloads, (2) generating SPDX SBOMs for every published image variant using Anchore Syft, and (3) signing all published images with cosign keyless signing via GitHub Actions OIDC. All tools updated to latest stable versions.

## Technical Context

**Language/Version**: Bash 5.x (Dockerfile RUN commands, scripts), GitHub Actions YAML (CI workflows)
**Primary Dependencies**: cosign v2.5.0 (image signing), Anchore Syft (SBOM generation), Docker Buildx (multi-arch builds, already in use)
**Storage**: OCI registry (GHCR — ghcr.io) for images, signatures, and SBOM attestations
**Testing**: BATS (Bash testing), ShellCheck (linting) — matches existing project testing patterns
**Target Platform**: GitHub Actions CI (Linux runners: ubuntu-latest for amd64, ubuntu-24.04-arm for arm64)
**Project Type**: Infrastructure/CI — Dockerfile + GitHub Actions workflow modifications
**Performance Goals**: SBOM generation < 3 min per architecture variant; total CI pipeline stays within existing build-time envelope
**Constraints**: Must work on both amd64 and arm64; keyless signing requires `id-token: write` permission; signing/SBOM skipped for PRs and forks
**Scale/Scope**: Single image type, 2 architecture variants, ~15 installed packages/tools

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | PASS | All changes are to Dockerfile and CI workflows. Version pinning aligns with "Versioned: all base images and tools pinned to specific versions." Eliminates prohibited "unpinned base image tags" pattern for tools. |
| II. Multi-Language Standards | PASS | No new languages introduced. Bash scripts will pass ShellCheck. |
| III. Test-First Development | PASS | BATS tests will verify: no script-piped installs, checksum verification, SBOM generation, signature verification. Tests written before implementation changes. |
| IV. Security-First Design | PASS | Directly implements: "Pin base image digests for reproducibility" (extended to tools), "Scan images for vulnerabilities" (SBOM enables this). Keyless signing avoids baked-in secrets. |
| V. Reproducibility & Portability | PASS | FR-001/002/003 directly implement "All package versions locked" and "No floating versions." Multi-arch support preserved. |
| VI. Observability & Debuggability | PASS | CI workflow outputs clear step-level logs for signing and SBOM generation. SBOM validation step reports package counts. |
| VII. Simplicity & Pragmatism | PASS | Two new CI tools (cosign, syft) are minimal, well-maintained, MIT-licensed, single-binary. Both are industry standard with large communities. No over-engineering — apt packages intentionally left unpinned to avoid maintenance trap (see research.md Decision 2). |

**Post-Phase-1 re-check**: No violations introduced. No complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/002-supply-chain-hardening/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 research decisions
├── data-model.md        # Phase 1 entity model
├── quickstart.md        # Phase 1 developer quickstart
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
# Modified files
Dockerfile                                      # FR-001: Replace Node.js curl|bash
                                                # FR-002: Pin uv version with checksum
                                                # FR-003: Checksum verification for all downloads
                                                # FR-004: Update tool versions
.github/workflows/container-build.yml           # FR-005–FR-012: SBOM generation + image signing
checksums.sha256                                # FR-013: Centralized checksum record

# New files
docs/image-verification.md                      # FR-014: Consumer verification documentation
tests/unit/test_supply_chain.bats               # Acceptance tests for supply-chain controls

# Existing files (may need minor updates)
scripts/validate-base-image-digests.sh          # Verify base image digests still valid
```

**Structure Decision**: This is an infrastructure feature modifying existing files at the repository root. No new `src/` directories needed — all changes are to the Dockerfile, CI workflow, checksums manifest, and documentation.

## Detailed Changes

### Phase A: Dockerfile Hardening (FR-001, FR-002, FR-003, FR-004)

**1. Replace Node.js `curl | bash` with official tarball (FR-001)**

Remove:
```dockerfile
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*
```

Replace with:
```dockerfile
ARG NODEJS_VERSION=v22.22.0
ARG NODEJS_SHA256_AMD64=9aa8e9d2298ab68c600bd6fb86a6c13bce11a4eca1ba9b39d79fa021755d7c37
ARG NODEJS_SHA256_ARM64=1bf1eb9ee63ffc4e5d324c0b9b62cf4a289f44332dfef9607cea1a0d9596ba6f
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
      amd64) NODE_ARCH="x64";  CHECKSUM="${NODEJS_SHA256_AMD64}" ;; \
      arm64) NODE_ARCH="arm64"; CHECKSUM="${NODEJS_SHA256_ARM64}" ;; \
      *)     echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    TARBALL="node-${NODEJS_VERSION}-linux-${NODE_ARCH}.tar.xz"; \
    curl -fsSL "https://nodejs.org/dist/${NODEJS_VERSION}/${TARBALL}" \
      -o "/tmp/${TARBALL}"; \
    echo "${CHECKSUM}  /tmp/${TARBALL}" | sha256sum -c -; \
    tar -xJf "/tmp/${TARBALL}" -C /usr/local --strip-components=1 \
      --exclude='*/CHANGELOG.md' \
      --exclude='*/LICENSE' \
      --exclude='*/README.md'; \
    rm -f "/tmp/${TARBALL}"; \
    node --version; npm --version
```

Add `xz-utils` to the existing apt install block for tar.xz support.

**2. Replace `pip install uv` with binary download (FR-002, FR-003)**

Remove:
```dockerfile
RUN pip install --no-cache-dir uv
```

Replace with:
```dockerfile
ARG UV_VERSION=0.10.4
ARG UV_SHA256_AMD64=6b52a47358deea1c5e173278bf46b2b489747a59ae31f2a4362ed5c6c1c269f7
ARG UV_SHA256_ARM64=c84a6e6405715caa6e2f5ef8e5f29a5d0bc558a954e9f1b5c082b9d4708c222e
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
      amd64) UV_ARCH="x86_64"; CHECKSUM="${UV_SHA256_AMD64}" ;; \
      arm64) UV_ARCH="aarch64"; CHECKSUM="${UV_SHA256_ARM64}" ;; \
      *)     echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    TARBALL="uv-${UV_ARCH}-unknown-linux-gnu.tar.gz"; \
    curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${TARBALL}" \
      -o "/tmp/${TARBALL}"; \
    echo "${CHECKSUM}  /tmp/${TARBALL}" | sha256sum -c -; \
    tar -xzf "/tmp/${TARBALL}" -C /usr/local/bin --strip-components=1 \
      "uv-${UV_ARCH}-unknown-linux-gnu/uv" \
      "uv-${UV_ARCH}-unknown-linux-gnu/uvx"; \
    chmod +x /usr/local/bin/uv /usr/local/bin/uvx; \
    rm -f "/tmp/${TARBALL}"; \
    uv --version
```

**3. Update Chezmoi version (FR-004)**

```dockerfile
ARG CHEZMOI_VERSION=v2.69.4
ARG CHEZMOI_SHA256_AMD64=5054cf09cb2993725f525c8bb6ec3ff8625489ecfc061e019c17e737e7c7057b
ARG CHEZMOI_SHA256_ARM64=560fb76182a3da7db7d445953cfa82fefbdc59284c8c673bb22363db9122ee4e
```

**4. Apt package pinning decision (FR-002)**

Keep apt packages **unpinned** with existing base image digest for reproducibility. See research.md Decision 2 for full rationale. The SBOM (FR-005) serves as the software inventory that exact pinning would otherwise provide.

### Phase B: CI Workflow — SBOM Generation (FR-005, FR-006, FR-007, FR-008)

Add SBOM generation to `.github/workflows/container-build.yml`:

**In the `build` job** (per-architecture, PR builds):
- Install syft via `anchore/sbom-action/download-syft`
- Generate SBOM against locally-loaded image (`docker:devcontainer:test`)
- Validate SBOM coverage (dpkg package count > 80 as sanity gate)
- Upload SBOM as workflow artifact (7-day retention for PRs)

**In the `merge` job** (publish builds):
- Generate SBOM against pushed image digest
- Use `cosign attest` to create signed SPDX attestation
- Upload SBOM as workflow artifact (90-day retention)

### Phase C: CI Workflow — Image Signing (FR-009, FR-010, FR-011, FR-012)

Add cosign keyless signing to `.github/workflows/container-build.yml`:

**Permissions**: Add `id-token: write` to both `build` and `merge` jobs.

**In the `build` job** (per-architecture):
- Install cosign via `sigstore/cosign-installer`
- Sign individual architecture digest: `cosign sign --yes $IMAGE@$DIGEST`
- Skip for PRs: `if: github.event_name != 'pull_request'`

**In the `merge` job** (multi-arch manifest):
- Capture manifest digest from `docker buildx imagetools inspect`
- Sign manifest: `cosign sign --yes $IMAGE@$MANIFEST_DIGEST`

### Phase D: Documentation & Checksums (FR-013, FR-014)

**Update `checksums.sha256`** (FR-013):
- Update chezmoi checksums for v2.69.4
- Add Node.js v22.22.0 tar.xz checksums
- Add uv 0.10.4 checksums
- Remove stale placeholder checksums (0000...) for OpenCode, Continue, Cline; add comment `# TODO: add checksums when these tools have pinned releases`

**Create `docs/image-verification.md`** (FR-014):
- How to verify image signature: `cosign verify --certificate-identity-regexp=... --certificate-oidc-issuer=...`
- How to retrieve SBOM: `cosign verify-attestation --type spdxjson ...`
- How to inspect SBOM contents
- Trust model explanation (Sigstore/Fulcio/Rekor)

### Phase E: Testing

**Create `tests/unit/test_supply_chain.bats`**:
- Test: No `curl | bash` or `wget | sh` patterns in Dockerfile
- Test: All ARG-defined checksums match entries in checksums.sha256
- Test: Every `curl -fsSL` download has a corresponding `sha256sum -c` verification
- Test: SBOM generation succeeds against a locally-built test image
- Test: Signature verification succeeds against a signed test image (integration test, may run only in CI)

## CI Action Pins

All GitHub Actions must be pinned to commit SHA per project conventions:

| Action | Version | SHA (verify before use) |
|--------|---------|------------------------|
| `sigstore/cosign-installer` | v3.9.0 | `fb28c2b6339dcd94da6e4cbcbc5e888961f6f8c3` |
| `anchore/sbom-action/download-syft` | v0.20.0 | `e11c554f704a0b820cbf8c51673f6945e0731532` |
| `anchore/sbom-action` | v0.20.0 | `e11c554f704a0b820cbf8c51673f6945e0731532` |

**Note**: SHA values verified via `gh api repos/{owner}/{repo}/commits?sha={tag}&per_page=1` on 2026-02-23.
