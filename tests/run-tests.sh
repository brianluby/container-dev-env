#!/usr/bin/env bash
# run-tests.sh — Executes all integration and contract tests, reports pass/fail
#
# Usage: ./tests/run-tests.sh [TEST_IMAGE]
#
# Environment:
#   TEST_IMAGE  Docker image to test against (default: devcontainer:test)
#
# Exit codes:
#   0 — All tests passed
#   1 — One or more tests failed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TEST_IMAGE="${1:-${TEST_IMAGE:-devcontainer:test}}"

PASSED=0
FAILED=0
FAILURES=()

run_test() {
    local test_file="$1"
    local test_name
    test_name="$(basename "$test_file")"

    printf "  %-45s " "$test_name"
    if bash "$test_file" >/dev/null 2>&1; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL"
        ((FAILED++))
        FAILURES+=("$test_name")
    fi
}

echo "=== OpenCode Integration Test Suite ==="
echo "Image: $TEST_IMAGE"
echo ""

# Run contract tests
if [[ -d "$SCRIPT_DIR/contract" ]]; then
    echo "--- Contract Tests ---"
    for f in "$SCRIPT_DIR"/contract/test_*.sh; do
        [[ -f "$f" ]] && run_test "$f"
    done
    echo ""
fi

# Run integration tests (only opencode-specific ones)
if [[ -d "$SCRIPT_DIR/integration" ]]; then
    echo "--- Integration Tests ---"
    for f in "$SCRIPT_DIR"/integration/test_opencode_*.sh; do
        [[ -f "$f" ]] && run_test "$f"
    done
    echo ""
fi

# Summary
echo "=== Results ==="
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "  Total:  $((PASSED + FAILED))"

if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for name in "${FAILURES[@]}"; do
        echo "  - $name"
    done
    exit 1
fi

echo ""
echo "All tests passed."
exit 0
