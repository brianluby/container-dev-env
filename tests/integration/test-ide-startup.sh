#!/usr/bin/env bash
# Integration Test: IDE container starts and returns HTTP 200 on localhost:3000 within 30s
# Task: T012 [US1]
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-src/docker/docker-compose.ide.yml}"
CONTAINER_NAME="${CONTAINER_NAME:-devenv-ide-1}"
MAX_WAIT=30
PORT=3000

# Source test helper if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Ensure .env exists with a valid token
if [[ ! -f "${REPO_ROOT}/.env" ]]; then
  "${REPO_ROOT}/src/scripts/generate-token.sh" > "${REPO_ROOT}/.env"
fi

# shellcheck source=/dev/null
source "${REPO_ROOT}/.env"

cleanup() {
  echo "Cleaning up..."
  docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" down -v --remove-orphans 2>/dev/null || true
}
trap cleanup EXIT

echo "=== Test: IDE container starts and HTTP 200 on localhost:${PORT} ==="

# Start the container
echo "Starting IDE container..."
docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" up -d --build

# Wait for HTTP 200
echo "Waiting for HTTP 200 on localhost:${PORT} (max ${MAX_WAIT}s)..."
elapsed=0
while [[ ${elapsed} -lt ${MAX_WAIT} ]]; do
  if curl -sf "http://localhost:${PORT}/?tkn=${CONNECTION_TOKEN}" -o /dev/null 2>/dev/null; then
    echo "PASS: HTTP 200 received after ${elapsed}s"
    exit 0
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

echo "FAIL: No HTTP 200 within ${MAX_WAIT}s"
docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" logs
exit 1
