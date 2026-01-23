#!/bin/bash
# =============================================================================
# Test Runner: Git Worktree Compatibility
# Feature: 007-git-worktree-compat
# =============================================================================
# Runs both unit tests (BATS) and integration tests (Docker).
#
# Usage:
#   ./scripts/test-worktree.sh          # Run all tests
#   ./scripts/test-worktree.sh unit     # Unit tests only
#   ./scripts/test-worktree.sh integration  # Integration tests only
# =============================================================================

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="${1:-all}"

run_unit_tests() {
    echo "=== Unit Tests (BATS) ==="
    local bats_bin="$PROJECT_ROOT/tests/unit/.bats-battery/bats-core/bin/bats"

    if [[ ! -x "$bats_bin" ]]; then
        echo "ERROR: BATS not found at $bats_bin"
        echo "To install the BATS test dependencies (as in CI), run from the project root:"
        echo "  cd tests/unit"
        echo "  git clone --depth 1 https://github.com/bats-core/bats-core.git .bats-battery/bats-core"
        echo "  git clone --depth 1 https://github.com/bats-core/bats-support.git .bats-battery/bats-support"
        echo "  git clone --depth 1 https://github.com/bats-core/bats-assert.git .bats-battery/bats-assert"
        exit 2
    fi

    "$bats_bin" "$PROJECT_ROOT/tests/unit/test_worktree_validation.bats"
    echo ""
}

run_integration_tests() {
    echo "=== Integration Tests (Docker) ==="

    if ! command -v docker &>/dev/null; then
        echo "SKIP: Docker not available"
        return 0
    fi

    bash "$PROJECT_ROOT/tests/integration/test_worktree_container.sh"
    echo ""
}

case "$MODE" in
    unit)
        run_unit_tests
        ;;
    integration)
        run_integration_tests
        ;;
    all)
        run_unit_tests
        run_integration_tests
        ;;
    *)
        echo "Usage: $0 [unit|integration|all]"
        exit 1
        ;;
esac

echo "=== All worktree tests passed ==="
