#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "Dockerfile"
  "docker/Dockerfile"
  "docker/Dockerfile.ide"
  "docker/memory.Dockerfile"
)

for rel in "${files[@]}"; do
  file_path="${REPO_ROOT}/${rel}"
  if [[ ! -f "${file_path}" ]]; then
    echo "Missing in-scope file: ${rel}" >&2
    exit 1
  fi

  while read -r from_ref; do
    [[ -z "${from_ref}" ]] && continue
    case "${from_ref}" in
      base|development|mcp|python-base)
        continue
        ;;
    esac
    if [[ ! "${from_ref}" =~ @sha256:[a-f0-9]{64}$ ]]; then
      echo "Unpinned FROM in ${rel}: ${from_ref}" >&2
      exit 1
    fi
  done < <(awk '/^FROM /{print $2}' "${file_path}")
done

echo "PASS: all in-scope Dockerfiles use digest-pinned external FROM references"
