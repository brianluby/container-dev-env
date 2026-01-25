#!/usr/bin/env bash
# Integration Test: IDE git functionality
# Test 1 (T029): git CLI available and functional inside container
# Test 2 (T030): git diff/stage/commit works in workspace volume
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker/docker-compose.ide.yml}"
CONTAINER_NAME="${CONTAINER_NAME:-devenv-ide-1}"
MAX_WAIT=30
PORT=3000

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ ! -f "${REPO_ROOT}/.env" ]]; then
  "${REPO_ROOT}/src/scripts/generate-token.sh" > "${REPO_ROOT}/.env"
fi

# shellcheck source=/dev/null
source "${REPO_ROOT}/.env"

cleanup() {
  docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" down -v --remove-orphans 2>/dev/null || true
}
trap cleanup EXIT

echo "=== Test: IDE git integration ==="

# Start the container
docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" up -d --build

# Wait for readiness
elapsed=0
while [[ ${elapsed} -lt ${MAX_WAIT} ]]; do
  if curl -sf "http://localhost:${PORT}/?tkn=${CONNECTION_TOKEN}" -o /dev/null 2>/dev/null; then
    break
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

if [[ ${elapsed} -ge ${MAX_WAIT} ]]; then
  echo "FAIL: Container did not become ready within ${MAX_WAIT}s"
  exit 1
fi

# Test 1: git CLI is available
echo "Test 1: git CLI available inside container..."
git_version=$(docker exec "${CONTAINER_NAME}" git --version 2>&1)
if echo "${git_version}" | grep -q "git version"; then
  echo "PASS: ${git_version}"
else
  echo "FAIL: git not available: ${git_version}"
  exit 1
fi

# Test 2: git operations work in workspace volume
echo "Test 2: git diff/stage/commit in workspace..."

# Initialize a git repo in the workspace
docker exec "${CONTAINER_NAME}" bash -c '
  cd /home/workspace &&
  git init -q &&
  git config user.email "test@devenv.local" &&
  git config user.name "Test User" &&
  echo "hello" > test-file.txt &&
  git add test-file.txt &&
  git commit -q -m "initial commit" &&
  echo "world" >> test-file.txt &&
  git diff --stat
'
diff_result=$?

if [[ ${diff_result} -eq 0 ]]; then
  echo "PASS: git init/add/commit/diff work in workspace"
else
  echo "FAIL: git operations failed (exit code: ${diff_result})"
  exit 1
fi

# Verify staging works
docker exec "${CONTAINER_NAME}" bash -c '
  cd /home/workspace &&
  git add test-file.txt &&
  git status --porcelain | grep -q "^M"
'
stage_result=$?

if [[ ${stage_result} -eq 0 ]]; then
  echo "PASS: git staging works"
else
  echo "FAIL: git staging verification failed"
  exit 1
fi

echo "All git tests passed."
