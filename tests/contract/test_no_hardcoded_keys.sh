#!/usr/bin/env bash
# test_no_hardcoded_keys.sh — Contract test for US3
# Scans src/ for literal API key patterns to prevent accidental commits
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/../../src"

echo "=== Contract Test: No Hardcoded API Keys ==="

ALL_PASSED=true

# Patterns that indicate hardcoded API keys
declare -a KEY_PATTERNS=(
    'sk-ant-[a-zA-Z0-9]'       # Anthropic API key prefix
    'sk-[a-zA-Z0-9]{20,}'      # OpenAI API key prefix
    'sk-proj-[a-zA-Z0-9]'      # OpenAI project key prefix
)

for pattern in "${KEY_PATTERNS[@]}"; do
    echo "[TEST] Scanning for pattern: ${pattern}"
    MATCHES=$(grep -rE "${pattern}" "${SRC_DIR}" \
        --include="*.sh" \
        --include="*.yaml" \
        --include="*.yml" \
        --include="*.json" \
        --include="*.tmpl" \
        --include="*.conf" \
        --include="*.env" \
        2>/dev/null || true)

    if [[ -n "${MATCHES}" ]]; then
        echo "[FAIL] Found potential hardcoded key:"
        echo "${MATCHES}" | head -5
        ALL_PASSED=false
    else
        echo "[PASS] No matches for ${pattern}"
    fi
done

# Also check for literal key assignments (KEY=value without variable reference)
echo "[TEST] Scanning for literal key assignments in config files..."
LITERAL_KEYS=$(grep -rE '(apiKey|api_key|API_KEY)\s*[:=]\s*"?[a-zA-Z0-9_-]{20,}' "${SRC_DIR}" \
    --include="*.yaml" \
    --include="*.yml" \
    --include="*.json" \
    --include="*.tmpl" \
    2>/dev/null | grep -v 'secrets\.' | grep -v '\${{' | grep -v 'placeholder' || true)

if [[ -n "${LITERAL_KEYS}" ]]; then
    echo "[FAIL] Found literal API key assignments:"
    echo "${LITERAL_KEYS}" | head -5
    ALL_PASSED=false
else
    echo "[PASS] No literal key assignments (all use secrets references)"
fi

if [[ "${ALL_PASSED}" == "true" ]]; then
    echo "=== No Hardcoded Keys: ALL PASSED ==="
else
    echo "=== No Hardcoded Keys: FAILURES DETECTED ==="
    exit 1
fi
