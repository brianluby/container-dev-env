#!/usr/bin/env bash
# test_env_vars.sh — Contract test: API key environment variables
#
# Verifies:
#   1. At least one LLM API key env var is set
#   2. API keys are not visible in process arguments

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Contract: Environment Variable API Keys ==="

# Test 1: At least one API key env var is set
echo "  [1/2] Checking at least one API key is set..."
docker run --rm \
    -e OPENAI_API_KEY="${OPENAI_API_KEY:-}" \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    "$IMAGE" bash -c '
        if [[ -z "${OPENAI_API_KEY:-}" ]] && [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
            echo "FAIL: No API key env var set (need OPENAI_API_KEY or ANTHROPIC_API_KEY)"
            exit 1
        fi
        echo "OK: API key env var is set"
    '

# Test 2: API keys not visible in process arguments
echo "  [2/2] Checking API keys not in process args..."
docker run --rm \
    -e OPENAI_API_KEY="${OPENAI_API_KEY:-sk-test-dummy-key-for-contract-test}" \
    "$IMAGE" bash -c '
        # Start a background process simulating opencode
        sleep 5 &
        PID=$!
        # Check that no process args contain the key
        if ps aux | grep -v grep | grep -q "sk-test-dummy-key"; then
            echo "FAIL: API key visible in process arguments"
            kill $PID 2>/dev/null || true
            exit 1
        fi
        kill $PID 2>/dev/null || true
        echo "OK: API keys not in process args"
    '

echo "PASS: Environment variable contract tests"
