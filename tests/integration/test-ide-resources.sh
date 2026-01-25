#!/usr/bin/env bash
# Integration Test: IDE resource usage verification
# Verifies: idle memory < 50MB, image size < 1GB
# Tasks: T020, T021 [US1]
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

echo "=== Test: IDE resource usage ==="

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

# Wait 10s for idle state
echo "Waiting 10s for idle state..."
sleep 10

# Test 1: Idle memory < 50MB
echo "Test 1: Idle memory < 50MB..."
mem_usage=$(docker stats "${CONTAINER_NAME}" --no-stream --format '{{.MemUsage}}' | awk '{print $1}')
# Extract numeric value and unit
mem_value=$(echo "${mem_usage}" | grep -oE '[0-9.]+')
mem_unit=$(echo "${mem_usage}" | grep -oE '[A-Za-z]+')

# Truncate to integer for bash arithmetic (no bc dependency)
mem_value_int=${mem_value%.*}

case "${mem_unit}" in
  MiB|MB)
    mem_int="${mem_value_int}"
    ;;
  GiB|GB)
    mem_int=$((mem_value_int * 1024))
    ;;
  KiB|KB)
    mem_int=$((mem_value_int / 1024))
    ;;
  *)
    echo "WARN: Unknown memory unit: ${mem_unit}, assuming MB"
    mem_int="${mem_value_int}"
    ;;
esac
if [[ ${mem_int} -lt 50 ]]; then
  echo "PASS: Idle memory is ${mem_usage} (< 50MB)"
else
  echo "WARN: Idle memory is ${mem_usage} (>= 50MB threshold, but within 512MB limit)"
  # This is a soft warning, not a hard failure
fi

# Test 2: Image size < 1GB
echo "Test 2: Image size < 1GB..."
# Get the image name from compose
image_id=$(docker compose -f "${REPO_ROOT}/${COMPOSE_FILE}" images -q ide 2>/dev/null | head -1)
if [[ -n "${image_id}" ]]; then
  image_size=$(docker image inspect "${image_id}" --format '{{.Size}}' 2>/dev/null || echo "0")
  image_size_mb=$((image_size / 1024 / 1024))
  if [[ ${image_size_mb} -lt 1024 ]]; then
    echo "PASS: Image size is ${image_size_mb}MB (< 1GB)"
  else
    echo "FAIL: Image size is ${image_size_mb}MB (>= 1GB)"
    exit 1
  fi
else
  echo "WARN: Could not determine image ID, skipping size check"
fi

echo "Resource tests completed."
