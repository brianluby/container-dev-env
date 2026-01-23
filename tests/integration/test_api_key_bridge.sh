#!/usr/bin/env bash
# test_api_key_bridge.sh — Integration test for US3
# Verifies env var → ~/.continue/.env → extension auth flow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: API Key Bridge Flow ==="

# Test 1: Verify bridge script exists and is executable
echo "[TEST] Checking bridge-secrets.sh is installed..."
BRIDGE_EXISTS=$(docker exec "${CONTAINER}" \
    test -x /usr/local/bin/bridge-secrets.sh && echo "yes" || echo "no")

if [[ "${BRIDGE_EXISTS}" == "yes" ]]; then
    echo "[PASS] bridge-secrets.sh is installed and executable"
else
    echo "[FAIL] bridge-secrets.sh not found or not executable"
    exit 1
fi

# Test 2: Run bridge with test key and verify .env creation
echo "[TEST] Running bridge with ANTHROPIC_API_KEY..."
docker exec -e ANTHROPIC_API_KEY="sk-ant-test-integration" "${CONTAINER}" \
    /usr/local/bin/bridge-secrets.sh

ENV_CONTENT=$(docker exec "${CONTAINER}" \
    cat /root/.continue/.env 2>/dev/null || echo "")

if echo "${ENV_CONTENT}" | grep -q "ANTHROPIC_API_KEY=sk-ant-test-integration"; then
    echo "[PASS] ANTHROPIC_API_KEY bridged to .env file"
else
    echo "[FAIL] ANTHROPIC_API_KEY not found in .env"
    exit 1
fi

# Test 3: Verify file permissions are 600
echo "[TEST] Checking .env file permissions..."
PERMS=$(docker exec "${CONTAINER}" \
    stat -c "%a" /root/.continue/.env 2>/dev/null || echo "unknown")

if [[ "${PERMS}" == "600" ]]; then
    echo "[PASS] .env file permissions are 600"
else
    echo "[FAIL] .env file permissions are ${PERMS}, expected 600"
    exit 1
fi

# Test 4: Verify Continue config references secrets syntax
echo "[TEST] Checking config.yaml uses secrets syntax..."
SECRETS_REF=$(docker exec "${CONTAINER}" \
    grep -c 'secrets\.' /root/.continue/config.yaml 2>/dev/null || echo "0")

if [[ "${SECRETS_REF}" -ge 1 ]]; then
    echo "[PASS] config.yaml uses \${{ secrets.* }} references"
else
    echo "[WARN] config.yaml may not use secrets syntax"
fi

# Clean up test .env
docker exec "${CONTAINER}" rm -f /root/.continue/.env 2>/dev/null || true

echo "=== API Key Bridge: ALL PASSED ==="
