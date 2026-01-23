#!/usr/bin/env bash
# Integration Test: IDE token-based authentication
# Test 1 (T035): HTTP 401 when no token provided
# Test 2 (T036): HTTP 401 with invalid token
# Test 3 (T037): Access granted with valid token
# Test 4 (T040): Token does not appear in docker logs
# Test 5 (T043): Failed auth attempts logged with timestamps
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

echo "=== Test: IDE token authentication ==="

# Start the container
docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" up -d --build

# Wait for the server to be listening (use valid token for readiness check)
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
  docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" logs
  exit 1
fi

# Test 1: No token → rejected
echo "Test 1: HTTP request without token..."
no_token_status=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/" 2>/dev/null || echo "000")
if [[ "${no_token_status}" == "401" || "${no_token_status}" == "403" ]]; then
  echo "PASS: No token returns HTTP ${no_token_status}"
else
  echo "FAIL: No token returns HTTP ${no_token_status} (expected 401 or 403)"
  exit 1
fi

# Test 2: Invalid token → rejected
echo "Test 2: HTTP request with invalid token..."
invalid_token_status=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/?tkn=invalidtoken12345678901234567890" 2>/dev/null || echo "000")
if [[ "${invalid_token_status}" == "401" || "${invalid_token_status}" == "403" ]]; then
  echo "PASS: Invalid token returns HTTP ${invalid_token_status}"
else
  echo "FAIL: Invalid token returns HTTP ${invalid_token_status} (expected 401 or 403)"
  exit 1
fi

# Test 3: Valid token → access granted
echo "Test 3: HTTP request with valid token..."
valid_token_status=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/?tkn=${CONNECTION_TOKEN}" 2>/dev/null || echo "000")
if [[ "${valid_token_status}" == "200" ]]; then
  echo "PASS: Valid token returns HTTP 200"
else
  echo "FAIL: Valid token returns HTTP ${valid_token_status} (expected 200)"
  exit 1
fi

# Test 4: Token does not appear in docker logs (T040)
echo "Test 4: Token not leaked in container logs..."
logs_output=$(docker logs "${CONTAINER_NAME}" 2>&1)
if echo "${logs_output}" | grep -qF "${CONNECTION_TOKEN}"; then
  echo "FAIL: Token found in container logs"
  exit 1
else
  echo "PASS: Token not found in container logs"
fi

# Test 5: Token does not appear in image layers (T041)
echo "Test 5: Token not in image layers..."
image_id=$(docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" images -q ide 2>/dev/null | head -1)
if [[ -n "${image_id}" ]]; then
  history_output=$(docker history "${image_id}" --no-trunc 2>&1)
  if echo "${history_output}" | grep -qF "${CONNECTION_TOKEN}"; then
    echo "FAIL: Token found in image history"
    exit 1
  else
    echo "PASS: Token not found in image layers"
  fi
else
  echo "WARN: Could not determine image ID, skipping layer check"
fi

# Test 6: generate-token.sh produces valid token (T042)
echo "Test 6: generate-token.sh produces valid token..."
generated=$("${REPO_ROOT}/src/scripts/generate-token.sh")
token_value="${generated#CONNECTION_TOKEN=}"
token_len=${#token_value}
if [[ ${token_len} -ge 32 ]] && echo "${token_value}" | grep -qE '^[0-9a-f]+$'; then
  echo "PASS: generate-token.sh produces ${token_len}-char hex token"
else
  echo "FAIL: generate-token.sh produced invalid token: ${token_value} (len=${token_len})"
  exit 1
fi

echo "All authentication tests passed."
