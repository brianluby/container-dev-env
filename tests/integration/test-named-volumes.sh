#!/bin/bash
# =============================================================================
# Integration Tests: Named Volumes (US2 - Persistent Development Environment)
# Feature: 004-volume-architecture
# =============================================================================
# Tests for persistence of home directory, shell history, and dotfiles
# Success criteria: Data persists across 100% of container restarts (SC-007)
# =============================================================================

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE="${PROJECT_ROOT}/test-workspace"
CONTAINER_NAME="devenv-test-volumes"
COMPOSE_PROJECT="devenv-test"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# TEST UTILITIES
# =============================================================================

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((TESTS_FAILED++))
}

setup() {
    log_test "Setting up test environment..."
    mkdir -p "$TEST_WORKSPACE"

    cd "$PROJECT_ROOT/docker"

    # Build the image
    docker compose -p "$COMPOSE_PROJECT" build dev

    # Clean up any existing volumes
    docker volume rm "${COMPOSE_PROJECT}_home-data" 2>/dev/null || true
}

teardown() {
    log_test "Cleaning up test environment..."
    cd "$PROJECT_ROOT/docker"
    docker compose -p "$COMPOSE_PROJECT" down -v 2>/dev/null || true
    docker volume rm "${COMPOSE_PROJECT}_home-data" 2>/dev/null || true
    rm -rf "$TEST_WORKSPACE"
}

run_container() {
    local cmd="${1:-sleep 5}"
    cd "$PROJECT_ROOT/docker"
    WORKSPACE_PATH="$TEST_WORKSPACE" docker compose -p "$COMPOSE_PROJECT" run --rm dev bash -c "$cmd"
}

# =============================================================================
# T020: Named volume persistence test
# =============================================================================

test_named_volume_exists() {
    ((TESTS_RUN++))
    log_test "T020: Verify named volume is created"

    # Run container to trigger volume creation
    run_container "echo 'Volume test'"

    # Check if volume exists
    if docker volume ls | grep -q "${COMPOSE_PROJECT}_home-data"; then
        log_pass "Named volume home-data was created"
    else
        log_fail "Named volume home-data was NOT created"
    fi
}

# =============================================================================
# T021: Shell history persistence test
# =============================================================================

test_shell_history_persistence() {
    ((TESTS_RUN++))
    log_test "T021: Verify shell history persists across restarts"

    # First run: Add command to history
    local test_cmd
    test_cmd="echo 'HISTORY_TEST_$(date +%s)'"
    run_container "HISTFILE=/home/dev/.bash_history && history -s '$test_cmd' && history -w"

    # Second run: Check history contains the command
    local history_content
    history_content=$(run_container "cat /home/dev/.bash_history 2>/dev/null || echo ''")

    if echo "$history_content" | grep -q "HISTORY_TEST_"; then
        log_pass "Shell history persisted across container restart"
    else
        log_fail "Shell history did NOT persist across container restart"
    fi
}

# =============================================================================
# T022: Dotfile persistence test
# =============================================================================

test_dotfile_persistence() {
    ((TESTS_RUN++))
    log_test "T022: Verify dotfiles persist across restarts"

    local test_marker
    test_marker="DOTFILE_TEST_$(date +%s)"

    # First run: Create custom dotfile
    run_container "echo 'export CUSTOM_VAR=$test_marker' >> /home/dev/.bashrc"

    # Second run: Check dotfile exists with our content
    local bashrc_content
    bashrc_content=$(run_container "cat /home/dev/.bashrc 2>/dev/null || echo ''")

    if echo "$bashrc_content" | grep -q "$test_marker"; then
        log_pass "Dotfile .bashrc persisted across container restart"
    else
        log_fail "Dotfile .bashrc did NOT persist across container restart"
    fi
}

# =============================================================================
# T023: Local tool persistence test
# =============================================================================

test_local_tool_persistence() {
    ((TESTS_RUN++))
    log_test "T023: Verify local tools persist across restarts"

    local test_script
    test_script="test-tool-$(date +%s).sh"

    # First run: Create a local tool in home directory
    run_container "mkdir -p /home/dev/bin && echo '#!/bin/bash\necho \"Tool works\"' > /home/dev/bin/$test_script && chmod +x /home/dev/bin/$test_script"

    # Second run: Check tool still exists
    local tool_exists
    tool_exists=$(run_container "test -x /home/dev/bin/$test_script && echo 'exists' || echo 'missing'")

    if [[ "$tool_exists" == "exists" ]]; then
        log_pass "Local tool persisted across container restart"
    else
        log_fail "Local tool did NOT persist across container restart"
    fi
}

# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

main() {
    echo "=============================================="
    echo "Integration Tests: Named Volumes (US2)"
    echo "=============================================="

    # Run setup
    trap teardown EXIT
    setup

    # Run tests
    test_named_volume_exists
    test_shell_history_persistence
    test_dotfile_persistence
    test_local_tool_persistence

    # Summary
    echo ""
    echo "=============================================="
    echo "Test Summary"
    echo "=============================================="
    echo "Tests Run:    $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo "=============================================="

    # Exit with failure if any tests failed
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
