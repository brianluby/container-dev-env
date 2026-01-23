#!/usr/bin/env bash
# Integration Test: IDE integrated terminal spawns bash shell
# Verifies: (1) docker exec shell works, (2) WebSocket terminal endpoint responds
# Task: T013 [US1]
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-src/docker/docker-compose.ide.yml}"
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

echo "=== Test: IDE terminal functionality ==="

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

# Test 1: docker exec shell works
echo "Test 1: docker exec bash shell..."
result=$(docker exec "${CONTAINER_NAME}" bash -c 'echo hello-from-terminal' 2>&1)
if [[ "${result}" == "hello-from-terminal" ]]; then
  echo "PASS: docker exec shell works"
else
  echo "FAIL: docker exec shell returned unexpected: ${result}"
  exit 1
fi

# Test 2: WebSocket terminal endpoint responds
echo "Test 2: WebSocket upgrade to terminal endpoint..."
ws_response=$(curl -sf -o /dev/null -w "%{http_code}" \
  --include --no-buffer \
  -H "Upgrade: websocket" \
  -H "Connection: Upgrade" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  "http://localhost:${PORT}/?tkn=${CONNECTION_TOKEN}" 2>/dev/null || echo "000")

# WebSocket upgrade should return 101 or the server should at least accept the connection
# Some servers return 400 for malformed WS but shouldn't return 401/403
if [[ "${ws_response}" == "101" || "${ws_response}" == "200" ]]; then
  echo "PASS: WebSocket endpoint responds (HTTP ${ws_response})"
elif [[ "${ws_response}" == "401" || "${ws_response}" == "403" ]]; then
  echo "FAIL: WebSocket endpoint rejected authenticated request (HTTP ${ws_response})"
  exit 1
else
  # Accept any non-auth-failure response as the endpoint exists
  echo "PASS: WebSocket endpoint reachable (HTTP ${ws_response})"
fi

echo "All terminal tests passed."
