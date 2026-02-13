#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEPLOY_DOC="${REPO_ROOT}/docs/operations/deployment.md"
QUICKSTART_DOC="${REPO_ROOT}/specs/001-pin-image-digests/quickstart.md"

grep -q "Digest refresh procedure" "${DEPLOY_DOC}"
grep -q "under 30 minutes" "${DEPLOY_DOC}"
grep -q "timed refresh" "${QUICKSTART_DOC}"
grep -q "old/new digests" "${QUICKSTART_DOC}"

echo "PASS: refresh workflow and timing requirements are documented"
