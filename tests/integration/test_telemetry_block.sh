#!/usr/bin/env bash
# test_telemetry_block.sh — Integration test for US7
# Verifies telemetry domains are blocked via /etc/hosts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: Telemetry Blocking ==="

BLOCKED_DOMAINS=(
    "data.cline.bot"
    "us.posthog.com"
    "eu.posthog.com"
)

ALL_PASSED=true

for domain in "${BLOCKED_DOMAINS[@]}"; do
    echo "[TEST] Checking ${domain} is blocked in /etc/hosts..."
    HOSTS_ENTRY=$(docker exec "${CONTAINER}" \
        grep -c "0.0.0.0 ${domain}" /etc/hosts 2>/dev/null || echo "0")

    if [[ "${HOSTS_ENTRY}" -ge 1 ]]; then
        echo "[PASS] ${domain} → 0.0.0.0 (blocked)"
    else
        echo "[FAIL] ${domain} NOT blocked in /etc/hosts"
        ALL_PASSED=false
    fi
done

# Verify VS Code telemetry setting is disabled
echo "[TEST] Checking VS Code telemetry setting..."
TELEMETRY_OFF=$(docker exec "${CONTAINER}" \
    cat /root/.config/Code/User/settings.json 2>/dev/null | \
    grep -c '"telemetry.telemetryLevel": "off"' || echo "0")

if [[ "${TELEMETRY_OFF}" -ge 1 ]]; then
    echo "[PASS] VS Code telemetry.telemetryLevel is 'off'"
else
    echo "[FAIL] VS Code telemetry setting not found or not 'off'"
    ALL_PASSED=false
fi

# Verify LLM API domains are NOT blocked
echo "[TEST] Verifying LLM API domains are accessible..."
ALLOWED_DOMAINS=(
    "api.anthropic.com"
    "api.openai.com"
    "api.mistral.ai"
)

for domain in "${ALLOWED_DOMAINS[@]}"; do
    BLOCKED=$(docker exec "${CONTAINER}" \
        grep -c "0.0.0.0 ${domain}" /etc/hosts 2>/dev/null || echo "0")

    if [[ "${BLOCKED}" -ge 1 ]]; then
        echo "[FAIL] ${domain} is incorrectly blocked!"
        ALL_PASSED=false
    else
        echo "[PASS] ${domain} is NOT blocked (correct)"
    fi
done

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== Telemetry Blocking: ALL PASSED ==="
else
    echo "=== Telemetry Blocking: FAILURES DETECTED ==="
    exit 1
fi
