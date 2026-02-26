#!/usr/bin/env bats

# Supply-chain hardening integration tests.
# These require external tools (Docker, syft, cosign) and are skipped
# when those tools are not available.

# ---------------------------------------------------------------------------
# Test 1: SBOM generation produces valid output
# Requires Docker and syft to be available. Skipped if either is missing.
# ---------------------------------------------------------------------------
@test "sbom_generation_produces_valid_spdx_json" {
  # Skip if Docker is not available
  command -v docker >/dev/null 2>&1 || skip "Docker not available"
  command -v syft >/dev/null 2>&1 || skip "syft not available"

  # Check if test image exists (built during CI or local dev)
  docker image inspect devcontainer:test >/dev/null 2>&1 || skip "devcontainer:test image not built"

  # Generate SBOM and capture output
  local sbom_output
  sbom_output=$(syft docker:devcontainer:test --output spdx-json --scope all-layers 2>/dev/null)

  # Verify it's valid JSON with SPDX format
  if ! echo "${sbom_output}" | jq -e '.spdxVersion' >/dev/null 2>&1; then
    echo "FAIL: SBOM output is not valid SPDX JSON"
    return 1
  fi

  # Count dpkg packages in the SBOM
  local dpkg_count
  dpkg_count=$(echo "${sbom_output}" | jq '[.packages[] | select(any(.externalRefs[]?; .referenceType == "purl" and ((.referenceLocator // "") | test("pkg:deb/"))))] | length' 2>/dev/null || echo "0")

  if [ "${dpkg_count}" -lt 80 ]; then
    echo "FAIL: SBOM contains only ${dpkg_count} dpkg packages (expected > 80)"
    return 1
  fi

  echo "PASS: SBOM contains ${dpkg_count} dpkg packages"
}

# ---------------------------------------------------------------------------
# Test 2: Image signature verification (CI-only integration test)
# Requires cosign and a signed image. Skipped locally.
# ---------------------------------------------------------------------------
@test "image_signature_verification" {
  # Skip if cosign is not available
  command -v cosign >/dev/null 2>&1 || skip "cosign not available"

  # Skip if not in CI with a published image
  [ -n "${CI:-}" ] || skip "Signature verification only runs in CI with published images"
  [ -n "${IMAGE_REF:-}" ] || skip "IMAGE_REF not set — no published image to verify"

  # Verify the image signature using keyless/OIDC identity
  run cosign verify \
    --certificate-identity-regexp="https://github.com/.*/.github/workflows/container-build.yml@refs/heads/main" \
    --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
    "${IMAGE_REF}"

  [ "${status}" -eq 0 ] || {
    echo "FAIL: cosign verify failed for ${IMAGE_REF}:"
    echo "${output}"
    return 1
  }

  echo "PASS: Image signature verified for ${IMAGE_REF}"
}
