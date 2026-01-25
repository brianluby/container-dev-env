#!/usr/bin/env bash
# Contract Test: IDE container interface compliance
# Verifies: port 3000 only, UID 1000, localhost binding (127.0.0.1)
# Task: T014 [US1]
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

echo "=== Contract Test: IDE interface compliance ==="

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

# Test 1: Container runs as UID 1000
echo "Test 1: Container runs as UID 1000..."
uid=$(docker exec "${CONTAINER_NAME}" id -u)
if [[ "${uid}" == "1000" ]]; then
  echo "PASS: Container runs as UID 1000"
else
  echo "FAIL: Container runs as UID ${uid}, expected 1000"
  exit 1
fi

# Test 2: Only port 3000 is exposed
echo "Test 2: Only port 3000 exposed..."
ports=$(docker port "${CONTAINER_NAME}" 2>/dev/null)
port_count=$(echo "${ports}" | grep -c ":" || true)
if [[ ${port_count} -eq 1 ]] && echo "${ports}" | grep -q "3000/tcp"; then
  echo "PASS: Only port 3000 is exposed"
else
  echo "FAIL: Unexpected port mapping: ${ports}"
  exit 1
fi

# Test 3: Port binds to 127.0.0.1
echo "Test 3: Port binds to 127.0.0.1..."
if echo "${ports}" | grep -q "127.0.0.1:${PORT}"; then
  echo "PASS: Port 3000 binds to 127.0.0.1"
else
  echo "FAIL: Port not bound to 127.0.0.1: ${ports}"
  exit 1
fi

echo "All contract tests passed."
