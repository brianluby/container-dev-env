#!/usr/bin/env bash
set -euo pipefail

MODE="text"
if [[ "${1:-}" == "--json" ]]; then
  MODE="json"
fi

REPO_ROOT="${DIGEST_VALIDATOR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
IN_SCOPE_FILES=(
  "Dockerfile"
  "docker/Dockerfile"
  "docker/Dockerfile.ide"
  "docker/memory.Dockerfile"
)

failures=()
checked_refs=()

extract_from_refs() {
  local file_path="$1"
  awk '
    /^FROM[[:space:]]/ {
      line = $0
      # Remove leading "FROM" and following whitespace.
      sub(/^FROM[[:space:]]+/, "", line)
      # Remove optional leading "--platform=..." (and surrounding whitespace).
      sub(/^[[:space:]]*--platform=[^[:space:]]+[[:space:]]+/, "", line)
      # Remove optional trailing "AS <alias>" (with flexible whitespace).
      sub(/[[:space:]]+AS[[:space:]]+.*/, "", line)
      print line
    }
  ' "${file_path}" | while read -r ref; do
    if [[ "${ref}" == "base" || "${ref}" == "development" || "${ref}" == "mcp" || "${ref}" == "python-base" ]]; then
      continue
    fi
    printf '%s\n' "${ref}"
  done
}

get_dockerhub_token() {
  local repo="$1"
  curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" | jq -r '.token'
}

check_platform_coverage() {
  local repo="$1"
  local digest="$2"
  local token
  token="$(get_dockerhub_token "${repo}")"

  local manifest
  manifest="$(curl -fsSL \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json" \
    "https://registry-1.docker.io/v2/${repo}/manifests/${digest}")"

  local has_amd64 has_arm64
  has_amd64="$(printf '%s' "${manifest}" | jq '[.manifests[]? | select(.platform?.os == "linux") | .platform?.architecture == "amd64"] | any')"
  has_arm64="$(printf '%s' "${manifest}" | jq '[.manifests[]? | select(.platform?.os == "linux") | .platform?.architecture == "arm64"] | any')"

  if [[ "${has_amd64}" != "true" || "${has_arm64}" != "true" ]]; then
    return 1
  fi

  return 0
}

for rel_file in "${IN_SCOPE_FILES[@]}"; do
  abs_file="${REPO_ROOT}/${rel_file}"
  if [[ ! -f "${abs_file}" ]]; then
    failures+=("Missing in-scope file: ${rel_file}")
    continue
  fi

  while read -r ref; do
    [[ -z "${ref}" ]] && continue

    if [[ ! "${ref}" =~ @sha256:[a-f0-9]{64}$ ]]; then
      failures+=("${rel_file}: unpinned base reference '${ref}'")
      continue
    fi

    checked_refs+=("${rel_file}:${ref}")

    image_part="${ref%@sha256:*}"
    digest="sha256:${ref##*@sha256:}"

    # Docker Hub normalization: 'debian' -> 'library/debian'
    if [[ "${image_part}" == */* ]]; then
      repo="${image_part%:*}"
    else
      repo="library/${image_part%:*}"
    fi

    if ! check_platform_coverage "${repo}" "${digest}"; then
      failures+=("${rel_file}: missing amd64/arm64 coverage for ${ref}")
    fi
  done < <(extract_from_refs "${abs_file}")
done

if [[ "${MODE}" == "json" ]]; then
  if [[ "${#failures[@]}" -eq 0 ]]; then
    printf '{"status":"pass","checked":%d,"failures":[]}\n' "${#checked_refs[@]}"
  else
    printf '{"status":"fail","checked":%d,"failures":[' "${#checked_refs[@]}"
    for i in "${!failures[@]}"; do
      item="${failures[$i]//\"/\\\"}"
      if [[ "${i}" -gt 0 ]]; then
        printf ','
      fi
      printf '"%s"' "${item}"
    done
    printf ']}\n'
  fi
else
  echo "In-scope files:" "${IN_SCOPE_FILES[*]}"
  echo "Checked references: ${#checked_refs[@]}"
  if [[ "${#failures[@]}" -eq 0 ]]; then
    echo "PASS: All in-scope external FROM references are digest-pinned with amd64/arm64 coverage."
  else
    echo "FAIL: Digest validation issues found:"
    for failure in "${failures[@]}"; do
      echo "- ${failure}"
    done
  fi
fi

if [[ "${#failures[@]}" -gt 0 ]]; then
  exit 1
fi
