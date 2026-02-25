# Quickstart: Supply-Chain Hardening

**Branch**: `002-supply-chain-hardening` | **Date**: 2026-02-23

## Prerequisites

- Docker with Buildx support (24+)
- Access to the GHCR container registry (for publish testing)
- cosign CLI (for local signature verification)
- syft CLI (for local SBOM generation)

## Local Development

### Build the hardened image

```bash
docker buildx build --platform linux/amd64 -t devcontainer:test --load .
```

### Verify no script-piped installs remain

```bash
grep -E 'curl.*\|.*bash|wget.*\|.*sh' Dockerfile && echo "FAIL: script-piped install found" || echo "PASS"
```

### Generate a local SBOM

```bash
# Install syft (one-time)
# macOS:
brew install syft
# Linux (pinned binary — replace version as needed):
# SYFT_VERSION=1.20.0
# curl -sSfL -o syft_${SYFT_VERSION}_linux_amd64.tar.gz \
#   https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz
# tar -xzf syft_${SYFT_VERSION}_linux_amd64.tar.gz -C /usr/local/bin syft

# Generate SBOM for the local image
syft docker:devcontainer:test --output spdx-json=sbom-local.spdx.json --scope all-layers

# Human-readable summary
syft docker:devcontainer:test --output table
```

### Verify checksum integrity

```bash
# Verify all checksums in the manifest
sha256sum -c checksums.sha256
```

### Run supply chain tests

```bash
# Requires BATS: brew install bats-core (macOS) or apt-get install bats
# Static analysis tests (no Docker required)
bats tests/unit/test_supply_chain.bats
# Integration tests (requires Docker + syft/cosign)
bats tests/integration/test_supply_chain.bats
```

## CI Pipeline Flow

### PR builds
1. Build image on both amd64 and arm64 runners
2. Run acceptance tests
3. Generate SBOM against locally-loaded image
4. Validate SBOM coverage (dpkg packages > 80)
5. No signing (PRs don't publish to registry)

### Publish builds (push to main)
1. Build and push per-architecture digests to GHCR
2. Sign each architecture digest with cosign (keyless/OIDC)
3. Create multi-architecture manifest
4. Sign the manifest with cosign
5. Generate SPDX SBOM for the manifest
6. Attest the SBOM with cosign (signed, stored in Rekor)
7. Upload SBOM as workflow artifact (90-day retention)

## Consumer Verification

### Verify image signature

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/OWNER/REPO/.github/workflows/container-build.yml@refs/heads/main" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/OWNER/REPO:latest
```

### Retrieve and inspect SBOM

```bash
cosign verify-attestation \
  --certificate-identity-regexp="https://github.com/OWNER/REPO/.github/workflows/container-build.yml@refs/heads/main" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  --type spdxjson \
  ghcr.io/OWNER/REPO:latest \
  | jq -r '.payload' | base64 -d | jq '.predicate'
```

## Updating Tool Versions

When updating a pinned tool version:

1. Download the new release artifacts for both amd64 and arm64
2. Compute SHA256 checksums: `sha256sum <artifact>`
3. Update the `ARG` lines in `Dockerfile` (version + checksums)
4. Update `checksums.sha256` with new entries
5. Build locally to verify: `docker buildx build --platform linux/amd64 -t devcontainer:test --load .`
6. Run SBOM generation to confirm the new version appears
7. Commit with: `chore(deps): bump <tool> from <old> to <new>`
