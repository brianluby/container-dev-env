#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_one() {
  "${REPO_ROOT}/scripts/validate-base-image-digests.sh" --json
}

first_run="$(run_one)"
second_run="$(run_one)"

if [[ "${first_run}" != "${second_run}" ]]; then
  echo "Digest validation output differs between runs" >&2
  echo "run1=${first_run}" >&2
  echo "run2=${second_run}" >&2
  exit 1
fi

echo "PASS: digest validation output is stable across repeated runs"
