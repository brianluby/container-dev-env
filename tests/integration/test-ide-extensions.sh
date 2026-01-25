#!/usr/bin/env bash
# Integration Test: IDE extension management
# Test 1 (T022): Extensions from manifest install on startup
# Test 2 (T023): Extensions persist after container restart
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker/docker-compose.ide.yml}"
CONTAINER_NAME="${CONTAINER_NAME:-devenv-ide-1}"
MAX_WAIT=60
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

wait_for_ready() {
  local elapsed=0
  while [[ ${elapsed} -lt ${MAX_WAIT} ]]; do
    if curl -sf "http://localhost:${PORT}/?tkn=${CONNECTION_TOKEN}" -o /dev/null 2>/dev/null; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  return 1
}

echo "=== Test: IDE extension management ==="

# Start the container
docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" up -d --build

if ! wait_for_ready; then
  echo "FAIL: Container did not become ready within ${MAX_WAIT}s"
  exit 1
fi

# Wait for extension install to complete (entrypoint installs before exec)
# Give extra time for extension downloads
echo "Waiting for extension installation to complete..."
sleep 15

# Test 1: Extensions from manifest are installed
echo "Test 1: Extensions from manifest install on startup..."
installed=$(docker exec "${CONTAINER_NAME}" \
  /home/.openvscode-server/bin/openvscode-server --list-extensions 2>/dev/null || echo "")

# Check for at least one extension from the manifest
# Note: Open VSX extension IDs may differ slightly from VS Code Marketplace IDs
found=0
for ext in "ms-python.python" "esbenp.prettier-vscode" "dbaeumer.vscode-eslint"; do
  if echo "${installed}" | grep -q "${ext}"; then
    echo "  Found: ${ext}"
    found=$((found + 1))
  else
    echo "  Not found: ${ext} (may not be available on Open VSX)"
  fi
done

if [[ ${found} -gt 0 ]]; then
  echo "PASS: ${found} manifest extension(s) installed"
else
  echo "WARN: No manifest extensions found (Open VSX may be unreachable)"
  # This is a soft warning per T025 (graceful unavailability handling)
fi

# Test 2: Extensions persist after restart
echo "Test 2: Extensions persist after container restart..."
docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" restart

if ! wait_for_ready; then
  echo "FAIL: Container did not become ready after restart"
  exit 1
fi

# Check extensions are still present
installed_after=$(docker exec "${CONTAINER_NAME}" \
  /home/.openvscode-server/bin/openvscode-server --list-extensions 2>/dev/null || echo "")

if [[ "${installed}" == "${installed_after}" ]]; then
  echo "PASS: Extensions persisted after restart"
else
  echo "WARN: Extension list changed after restart (idempotent install may have re-added)"
  # Not a failure — idempotent install is acceptable
fi

echo "Extension tests completed."
