#!/usr/bin/env bash
# test_provider_switch.sh — Integration test for US4
# Verifies multiple LLM providers are configured and can be selected
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.bash" 2>/dev/null || true

CONTAINER="${TEST_CONTAINER:-container-dev-env-test}"

echo "=== Test: Multi-Provider Configuration ==="

ALL_PASSED=true

# Test 1: Anthropic provider configured
echo "[TEST] Anthropic provider present..."
if docker exec "${CONTAINER}" grep -q "provider: anthropic" /root/.continue/config.yaml 2>/dev/null; then
    echo "[PASS] Anthropic provider configured"
else
    echo "[FAIL] Anthropic provider missing"
    ALL_PASSED=false
fi

# Test 2: OpenAI provider configured
echo "[TEST] OpenAI provider present..."
if docker exec "${CONTAINER}" grep -q "provider: openai" /root/.continue/config.yaml 2>/dev/null; then
    echo "[PASS] OpenAI provider configured"
else
    echo "[FAIL] OpenAI provider missing"
    ALL_PASSED=false
fi

# Test 3: Mistral provider configured (for autocomplete)
echo "[TEST] Mistral provider present..."
if docker exec "${CONTAINER}" grep -q "provider: mistral" /root/.continue/config.yaml 2>/dev/null; then
    echo "[PASS] Mistral provider configured"
else
    echo "[FAIL] Mistral provider missing"
    ALL_PASSED=false
fi

# Test 4: Ollama (local) provider configured
echo "[TEST] Ollama provider present..."
if docker exec "${CONTAINER}" grep -q "provider: ollama" /root/.continue/config.yaml 2>/dev/null; then
    echo "[PASS] Ollama provider configured"
else
    echo "[FAIL] Ollama provider missing"
    ALL_PASSED=false
fi

# Test 5: Multiple chat models available for switching
echo "[TEST] Multiple chat models configured..."
CHAT_MODELS=$(docker exec "${CONTAINER}" \
    grep -A2 "roles:" /root/.continue/config.yaml 2>/dev/null | \
    grep -c "chat" || echo "0")

if [[ "${CHAT_MODELS}" -ge 2 ]]; then
    echo "[PASS] ${CHAT_MODELS} chat models available for switching"
else
    echo "[FAIL] Only ${CHAT_MODELS} chat model(s) — need at least 2 for switching"
    ALL_PASSED=false
fi

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== Multi-Provider: ALL PASSED ==="
else
    echo "=== Multi-Provider: FAILURES DETECTED ==="
    exit 1
fi
