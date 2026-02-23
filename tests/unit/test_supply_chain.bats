#!/usr/bin/env bats

# Supply-chain hardening tests for the container Dockerfile.
# These perform static analysis on the Dockerfile to enforce:
#   1. No piped-install anti-patterns (curl|bash, wget|sh, etc.)
#   2. Every curl download has a corresponding sha256sum verification
#   3. All ARG checksum values appear in the checksums manifest

setup() {
  DOCKERFILE="${BATS_TEST_DIRNAME}/../../Dockerfile"
  CHECKSUMS="${BATS_TEST_DIRNAME}/../../checksums.sha256"

  [ -f "${DOCKERFILE}" ] || {
    echo "Dockerfile not found: ${DOCKERFILE}" >&2
    return 1
  }
  [ -f "${CHECKSUMS}" ] || {
    echo "Checksums manifest not found: ${CHECKSUMS}" >&2
    return 1
  }
}

# ---------------------------------------------------------------------------
# Test 1: No script-piped installs
# Patterns like `curl ... | bash` or `wget ... | sh` are a supply-chain risk
# because they execute remote code without integrity verification.
# ---------------------------------------------------------------------------
@test "no_script_piped_installs" {
  # Match any line that pipes a curl or wget download into a shell interpreter.
  # Using extended-regex alternation to cover all common variants.
  run grep -cE 'curl\s.*\|\s*(ba)?sh|wget\s.*\|\s*(ba)?sh' "${DOCKERFILE}"

  # grep -c returns the count of matching lines.  We expect zero.
  # If grep finds no matches it exits with status 1 and prints "0".
  if [ "${status}" -eq 0 ]; then
    # status 0 means grep found at least one match
    echo "FAIL: Found ${output} piped-install line(s) in Dockerfile:"
    grep -nE 'curl\s.*\|\s*(ba)?sh|wget\s.*\|\s*(ba)?sh' "${DOCKERFILE}"
    return 1
  fi

  # status 1 = no matches (good), status 2 = error
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Test 2: Every curl download has checksum verification
# For each `curl -fsSL` invocation that downloads a file, there must be a
# corresponding `sha256sum -c` within the same RUN block.
#
# Strategy: Use awk to join continuation lines (backslash-newline) so that
# each RUN block becomes a single logical line, then check each block that
# contains `curl -fsSL` also contains `sha256sum -c`.
# ---------------------------------------------------------------------------
@test "every_curl_download_has_checksum_verification" {
  local failures=()

  # Collapse continuation lines portably with awk.
  # After collapsing, each RUN instruction is one line.
  local collapsed
  collapsed=$(awk '
    /\\$/ { gsub(/\\$/, ""); hold = hold $0; next }
    { if (hold != "") { print hold $0; hold = "" } else { print } }
    END { if (hold != "") print hold }
  ' "${DOCKERFILE}")

  # Walk collapsed lines.  For each one containing `curl -fsSL` (an actual
  # download, not the apt package name), verify sha256sum accompanies it.
  local line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))

    # Only interested in lines with an actual curl download invocation
    echo "${line}" | grep -qE 'curl[[:space:]]+-fsSL' || continue

    # Must have sha256sum verification in the same RUN block
    if ! echo "${line}" | grep -q 'sha256sum -c'; then
      # Provide the first 120 chars for context in failure output
      local snippet="${line:0:120}"
      failures+=("collapsed line ${line_num}: curl -fsSL download without sha256sum -c  (${snippet}...)")
    fi
  done <<< "${collapsed}"

  if [ "${#failures[@]}" -gt 0 ]; then
    echo "FAIL: Found curl downloads without checksum verification:"
    for f in "${failures[@]}"; do
      echo "  - ${f}"
    done
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test 3: All ARG checksum values match the checksums manifest
# Every ARG ending in _SHA256_AMD64 or _SHA256_ARM64 must have its value
# present somewhere in checksums.sha256.
# ---------------------------------------------------------------------------
@test "all_arg_checksums_match_manifest" {
  local failures=()

  # Extract ARG lines whose names end with _SHA256_AMD64 or _SHA256_ARM64.
  # Format: ARG NAME=value
  while IFS= read -r arg_line; do
    # Parse the ARG name and value using parameter expansion (portable).
    # arg_line looks like: "ARG CHEZMOI_SHA256_AMD64=9b9bf9..."
    local name_value="${arg_line#ARG }"   # strip leading "ARG "
    local arg_name="${name_value%%=*}"    # everything before first '='
    local arg_value="${name_value#*=}"    # everything after first '='

    # Sanity: value should be a 64-char hex string (SHA-256)
    if [ "${#arg_value}" -ne 64 ]; then
      failures+=("${arg_name}: value '${arg_value}' is not a valid SHA-256 hash (length ${#arg_value})")
      continue
    fi

    # Check that this checksum appears in the manifest (ignoring comment lines)
    if ! grep -v '^#' "${CHECKSUMS}" | grep -q "${arg_value}"; then
      failures+=("${arg_name}: checksum ${arg_value} not found in checksums.sha256")
    fi
  done < <(grep -E '^ARG [A-Z_0-9]+_SHA256_(AMD64|ARM64)=' "${DOCKERFILE}")

  if [ "${#failures[@]}" -gt 0 ]; then
    echo "FAIL: ARG checksums not present in manifest:"
    for f in "${failures[@]}"; do
      echo "  - ${f}"
    done
    return 1
  fi

  # Also verify we actually checked at least one ARG (guard against regex drift)
  local count
  count=$(grep -cE '^ARG [A-Z_0-9]+_SHA256_(AMD64|ARM64)=' "${DOCKERFILE}")
  [ "${count}" -gt 0 ] || {
    echo "FAIL: No _SHA256_AMD64/_SHA256_ARM64 ARGs found in Dockerfile"
    return 1
  }
}

# ---------------------------------------------------------------------------
# Test 4: SBOM generation produces valid output (integration test)
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
  dpkg_count=$(echo "${sbom_output}" | jq '[.packages[] | select(.externalRefs[]?.referenceType == "purl" and (.externalRefs[]?.referenceLocator | test("pkg:deb/")))] | length' 2>/dev/null || echo "0")

  if [ "${dpkg_count}" -lt 80 ]; then
    echo "FAIL: SBOM contains only ${dpkg_count} dpkg packages (expected > 80)"
    return 1
  fi

  echo "PASS: SBOM contains ${dpkg_count} dpkg packages"
}

# ---------------------------------------------------------------------------
# Test 5: Image signature verification (CI-only integration test)
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
