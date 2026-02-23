# Research: Supply-Chain Hardening

**Date**: 2026-02-23
**Branch**: `002-supply-chain-hardening`

## Decision 1: Node.js Installation Method

**Decision**: Replace `curl | bash` NodeSource script with official Node.js binary tarball + SHA256 checksum verification.

**Rationale**: The NodeSource install script is the only remaining script-piped installation pattern in the Dockerfile. Official binary tarballs from `nodejs.org/dist/` provide the same binaries with verifiable checksums published at `SHASUMS256.txt`. This matches the existing installation pattern used for chezmoi and age.

**Alternatives considered**:
- NodeSource apt repository (current): Requires `curl | bash` to add GPG key and repo — supply-chain risk.
- Debian-packaged Node.js: Bookworm ships Node.js 18.x, too old for 22.x LTS requirement.
- `nvm` or `fnm`: Runtime version managers add complexity, not suitable for container images.

**Implementation details**:
- Version: `v22.22.0` (latest 22.x LTS as of 2026-02-23)
- Format: `tar.xz` (30MB vs 57MB for tar.gz)
- Requires `xz-utils` in the apt install block
- Architecture mapping: `dpkg amd64` → Node `x64`, `dpkg arm64` → Node `arm64`
- Checksums (tar.xz):
  - amd64: `9aa8e9d2298ab68c600bd6fb86a6c13bce11a4eca1ba9b39d79fa021755d7c37`
  - arm64: `1bf1eb9ee63ffc4e5d324c0b9b62cf4a289f44332dfef9607cea1a0d9596ba6f`
- Installs to `/usr/local` via `--strip-components=1` (puts `node`/`npm` on PATH automatically)

## Decision 2: Apt Package Version Pinning Strategy

**Decision**: Do NOT pin apt packages to exact versions. Keep the current approach of unpinned apt packages + pinned base image digest.

**Rationale**: Debian's standard mirrors only retain the current version of each package. Exact pins (e.g., `curl=7.88.1-10+deb12u8`) break the build when security updates ship. The only reliable alternative is `snapshot.debian.org`, which adds complexity and slower mirror speeds. The base image digest (`debian:bookworm-20260202-slim@sha256:...`) already provides build-to-build reproducibility via Docker layer cache. SBOM generation (FR-005) provides the software inventory that exact pinning would otherwise serve.

**Alternatives considered**:
- Exact pins + `snapshot.debian.org`: Maximum reproducibility but high maintenance burden and no automated tooling support (neither Dependabot nor Renovate reliably updates apt pins).
- Exact pins + live mirror: Breaks on every security update — rejected.
- Partial/wildcard pins: Not supported by apt syntax — rejected.

## Decision 3: Image Signing Approach

**Decision**: Use cosign keyless signing with GitHub Actions OIDC (Sigstore/Fulcio/Rekor). No long-lived signing keys.

**Rationale**: Keyless signing eliminates secret management entirely. The GitHub Actions OIDC token identifies the exact workflow, repository, and ref that produced the image. Signatures are recorded in the public Rekor transparency log with timestamps, providing non-repudiation. This is the industry standard for open-source container images.

**Alternatives considered**:
- cosign with long-lived key pair: Requires secure key storage, rotation policy, and secret distribution — rejected for complexity.
- Docker Content Trust (Notary v1): Legacy, being replaced by Sigstore ecosystem — rejected.
- Notation (CNCF): Newer standard, less mature tooling and fewer public verifiers — rejected.

**Implementation details**:
- cosign v2.5.0 via `sigstore/cosign-installer@v3.9.0`
- Requires `id-token: write` permission in GitHub Actions
- Sign both individual architecture digests (in `build` job) and multi-arch manifest (in `merge` job)
- `--yes` flag for non-interactive CI mode
- Skip signing for PRs/forks (no `id-token` available, and images aren't published)
- Consumer verification: `cosign verify --certificate-identity-regexp="...workflow..." --certificate-oidc-issuer="https://token.actions.githubusercontent.com"`

## Decision 4: SBOM Format and Tooling

**Decision**: Use Anchore Syft to generate SBOMs in SPDX JSON format. Attach as signed attestation via `cosign attest`.

**Rationale**: SPDX is the ISO 5962:2021 standard and is accepted by CISA, US EO 14028, and GitHub's Dependency Graph API. Syft's catalogers cover dpkg packages, Python packages, Node.js packages, and Go binary modules — matching the image's contents. `cosign attest` creates a signed in-toto attestation stored via OCI Referrers API, making the SBOM tamper-evident and discoverable.

**Alternatives considered**:
- CycloneDX: Strong security tooling ecosystem (Grype, Dependency-Track) but SPDX has broader regulatory acceptance. Can add CycloneDX as secondary output later.
- Docker BuildKit `--attest type=sbom`: Generates SPDX natively during build but less control over catalogers and format — rejected for initial implementation.
- `cosign attach sbom` (unsigned): Attaches SBOM but without signature — doesn't meet tamper-evidence requirement.

**Implementation details**:
- Syft via `anchore/sbom-action/download-syft` in CI
- `--scope all-layers` for multi-stage image completeness
- SBOM validation: Check dpkg package count > 80 as sanity gate
- PR builds: Generate SBOM against locally-loaded image (`docker:devcontainer:test`) for validation
- Publish builds: Generate against pushed digest, attest with cosign, upload as workflow artifact (90-day retention)

## Decision 5: uv Package Manager Installation

**Decision**: Replace `pip install uv` with direct binary download + SHA256 checksum verification.

**Rationale**: `pip install uv` uses an unpinned version and no integrity verification. Astral provides official pre-built binaries with per-artifact `.sha256` sidecar files on every release. This matches the checksum verification pattern used for chezmoi, age, and (now) Node.js.

**Implementation details**:
- Version: `0.10.4`
- Checksums:
  - amd64 (`uv-x86_64-unknown-linux-gnu.tar.gz`): `6b52a47358deea1c5e173278bf46b2b489747a59ae31f2a4362ed5c6c1c269f7`
  - arm64 (`uv-aarch64-unknown-linux-gnu.tar.gz`): `c84a6e6405715caa6e2f5ef8e5f29a5d0bc558a954e9f1b5c082b9d4708c222e`

## Decision 6: Tool Version Updates

**Decision**: Update all tools to latest stable releases.

| Tool | Current | Updated | Change |
|------|---------|---------|--------|
| Chezmoi | v2.69.3 | v2.69.4 | Patch bump |
| age | v1.3.1 | v1.3.1 | Already current |
| Node.js | NodeSource 22.x | v22.22.0 | Method + version change |
| uv | unpinned (pip) | 0.10.4 | Method + version pin |
| Python | 3.14 (official image) | 3.14 | Already current (from `python-base` stage) |
