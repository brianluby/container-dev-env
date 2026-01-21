#!/bin/bash
# =============================================================================
# Integration Tests: Bind Mount (US1 - Source Code Editing from Host)
# Feature: 004-volume-architecture
# =============================================================================
# Tests for bidirectional file sync between host and container
# Success criteria: File changes sync within 1 second (SC-001)
# =============================================================================

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE="${PROJECT_ROOT}/test-workspace"
CONTAINER_NAME="devenv-test"

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

    # Build and start container with bind mount
    cd "$PROJECT_ROOT/docker"
    docker compose build dev
    docker compose run -d --name "$CONTAINER_NAME" \
        -v "$TEST_WORKSPACE:/workspace:cached" \
        dev sleep infinity

    # Wait for container to be ready
    sleep 2
}

teardown() {
    log_test "Cleaning up test environment..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    rm -rf "$TEST_WORKSPACE"
}

# =============================================================================
# T011: Bind mount sync test
# =============================================================================

test_bind_mount_exists() {
    ((TESTS_RUN++))
    log_test "T011: Verify bind mount exists in container"

    if docker exec "$CONTAINER_NAME" test -d /workspace; then
        log_pass "Bind mount /workspace exists in container"
    else
        log_fail "Bind mount /workspace does not exist"
    fi
}

# =============================================================================
# T012: Host→Container sync verification
# =============================================================================

test_host_to_container_sync() {
    ((TESTS_RUN++))
    log_test "T012: Verify host→container file sync (<1s)"

    local test_file="test-host-sync-$(date +%s).txt"
    local test_content="Hello from host at $(date)"

    # Create file on host
    echo "$test_content" > "$TEST_WORKSPACE/$test_file"

    # Wait for sync (should be <1s)
    sleep 1

    # Verify in container
    local container_content
    container_content=$(docker exec "$CONTAINER_NAME" cat "/workspace/$test_file" 2>/dev/null || echo "")

    if [[ "$container_content" == "$test_content" ]]; then
        log_pass "Host→Container sync completed within 1s"
    else
        log_fail "Host→Container sync failed or took >1s"
    fi

    # Cleanup
    rm -f "$TEST_WORKSPACE/$test_file"
}

# =============================================================================
# T013: Container→Host sync verification
# =============================================================================

test_container_to_host_sync() {
    ((TESTS_RUN++))
    log_test "T013: Verify container→host file sync (<1s)"

    local test_file="test-container-sync-$(date +%s).txt"
    local test_content="Hello from container at $(date)"

    # Create file in container
    docker exec "$CONTAINER_NAME" bash -c "echo '$test_content' > /workspace/$test_file"

    # Wait for sync (should be <1s)
    sleep 1

    # Verify on host
    local host_content
    host_content=$(cat "$TEST_WORKSPACE/$test_file" 2>/dev/null || echo "")

    if [[ "$host_content" == "$test_content" ]]; then
        log_pass "Container→Host sync completed within 1s"
    else
        log_fail "Container→Host sync failed or took >1s"
    fi

    # Cleanup
    rm -f "$TEST_WORKSPACE/$test_file"
}

# =============================================================================
# T014: File permission verification test
# =============================================================================

test_file_permissions() {
    ((TESTS_RUN++))
    log_test "T014: Verify file permissions are host-readable"

    local test_file="test-permissions-$(date +%s).txt"

    # Create file in container
    docker exec "$CONTAINER_NAME" bash -c "echo 'permission test' > /workspace/$test_file"

    # Wait for sync
    sleep 1

    # Check host user can read the file
    if [[ -r "$TEST_WORKSPACE/$test_file" ]]; then
        log_pass "File created in container is readable by host user"
    else
        log_fail "File created in container is NOT readable by host user"
    fi

    # Check host user can write to the file
    if [[ -w "$TEST_WORKSPACE/$test_file" ]]; then
        log_pass "File created in container is writable by host user"
    else
        log_fail "File created in container is NOT writable by host user"
    fi

    # Cleanup
    rm -f "$TEST_WORKSPACE/$test_file"
}

# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

main() {
    echo "=============================================="
    echo "Integration Tests: Bind Mount (US1)"
    echo "=============================================="

    # Run setup
    trap teardown EXIT
    setup

    # Run tests
    test_bind_mount_exists
    test_host_to_container_sync
    test_container_to_host_sync
    test_file_permissions

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
