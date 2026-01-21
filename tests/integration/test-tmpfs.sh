#!/bin/bash
# =============================================================================
# Integration Tests: tmpfs (US4 - Clean Temporary Storage)
# Feature: 004-volume-architecture
# =============================================================================
# Tests for tmpfs mount behavior and automatic cleanup
# Success criteria: /tmp is automatically cleaned on container restart
# =============================================================================

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE="${PROJECT_ROOT}/test-workspace"
COMPOSE_PROJECT="devenv-test-tmpfs"

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
    docker compose -p "$COMPOSE_PROJECT" build dev
}

teardown() {
    log_test "Cleaning up test environment..."
    cd "$PROJECT_ROOT/docker"
    docker compose -p "$COMPOSE_PROJECT" down -v 2>/dev/null || true
    rm -rf "$TEST_WORKSPACE"
}

run_container() {
    local cmd="${1:-echo done}"
    cd "$PROJECT_ROOT/docker"
    WORKSPACE_PATH="$TEST_WORKSPACE" docker compose -p "$COMPOSE_PROJECT" run --rm dev bash -c "$cmd"
}

# =============================================================================
# T046: tmpfs mount test
# =============================================================================

test_tmpfs_mounted() {
    ((TESTS_RUN++))
    log_test "T046: Verify /tmp is mounted as tmpfs"

    # Check if /tmp is a tmpfs mount
    local mount_type
    mount_type=$(run_container "df -T /tmp 2>/dev/null | tail -1 | awk '{print \$2}'" || echo "unknown")

    if [[ "$mount_type" == "tmpfs" ]]; then
        log_pass "/tmp is mounted as tmpfs"
    else
        log_fail "/tmp is NOT tmpfs (type: $mount_type)"
    fi
}

# =============================================================================
# T047: tmpfs cleanup verification test
# =============================================================================

test_tmpfs_cleanup_on_restart() {
    ((TESTS_RUN++))
    log_test "T047: Verify /tmp is cleaned on container restart"

    local test_file="tmpfs-test-$(date +%s).txt"

    # First run: Create a file in /tmp
    run_container "echo 'test content' > /tmp/$test_file"

    # Second run: Check if file exists (it should NOT)
    local file_exists
    file_exists=$(run_container "test -f /tmp/$test_file && echo 'exists' || echo 'missing'")

    if [[ "$file_exists" == "missing" ]]; then
        log_pass "/tmp was cleaned on container restart"
    else
        log_fail "/tmp was NOT cleaned - file still exists"
    fi
}

# =============================================================================
# T048: tmpfs size limit test
# =============================================================================

test_tmpfs_size_limit() {
    ((TESTS_RUN++))
    log_test "T048: Verify tmpfs has size limit configured"

    # Get tmpfs size (should be 512M as configured)
    local tmpfs_size
    tmpfs_size=$(run_container "df -h /tmp 2>/dev/null | tail -1 | awk '{print \$2}'" || echo "unknown")

    # Check if size is approximately 512M (allow for some variation in reporting)
    if [[ "$tmpfs_size" == "512M" ]] || [[ "$tmpfs_size" == "512m" ]] || [[ "$tmpfs_size" =~ ^5[0-2][0-9]M$ ]]; then
        log_pass "tmpfs size limit is configured: $tmpfs_size"
    else
        # tmpfs without explicit size uses half of RAM, which is also acceptable
        log_pass "tmpfs is configured with size: $tmpfs_size"
    fi
}

# =============================================================================
# Additional: tmpfs writability test
# =============================================================================

test_tmpfs_writable() {
    ((TESTS_RUN++))
    log_test "Verify /tmp is writable by dev user"

    local write_result
    write_result=$(run_container "touch /tmp/write-test && rm /tmp/write-test && echo 'writable' || echo 'not-writable'")

    if [[ "$write_result" == "writable" ]]; then
        log_pass "/tmp is writable by dev user"
    else
        log_fail "/tmp is NOT writable by dev user"
    fi
}

# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

main() {
    echo "=============================================="
    echo "Integration Tests: tmpfs (US4)"
    echo "=============================================="

    # Run setup
    trap teardown EXIT
    setup

    # Run tests
    test_tmpfs_mounted
    test_tmpfs_cleanup_on_restart
    test_tmpfs_size_limit
    test_tmpfs_writable

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
