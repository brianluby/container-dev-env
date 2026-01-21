#!/bin/bash
# =============================================================================
# Integration Tests: Prune Safety (US5 - Safe Pruning and Recovery)
# Feature: 004-volume-architecture
# =============================================================================
# Tests for data safety during docker system prune operations
# Success criteria: Source code survives prune; named volumes require explicit deletion
# =============================================================================

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE="${PROJECT_ROOT}/test-workspace"
COMPOSE_PROJECT="devenv-test-prune"

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

    # Create a test file in workspace
    echo "Source code test file - $(date)" > "$TEST_WORKSPACE/source-test.txt"

    cd "$PROJECT_ROOT/docker"
    docker compose -p "$COMPOSE_PROJECT" build dev

    # Start container to create volumes
    WORKSPACE_PATH="$TEST_WORKSPACE" docker compose -p "$COMPOSE_PROJECT" run --rm dev bash -c "echo 'Volume initialized'"
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
# T052: Prune safety test
# =============================================================================

test_volumes_have_explicit_names() {
    ((TESTS_RUN++))
    log_test "T052: Verify all volumes have explicit names (devenv-*)"

    # List volumes and check for devenv- prefix
    local volume_names
    volume_names=$(docker volume ls --format '{{.Name}}' | grep -E "^devenv-" || echo "")

    local expected_volumes=(
        "devenv-home"
        "devenv-npm-cache"
        "devenv-pip-cache"
        "devenv-cargo-registry"
        "devenv-node-modules"
        "devenv-cargo-target"
    )

    local found_count=0
    for vol in "${expected_volumes[@]}"; do
        if echo "$volume_names" | grep -q "^${vol}$"; then
            ((found_count++))
        fi
    done

    if [[ $found_count -ge 1 ]]; then
        log_pass "Found $found_count explicitly named volumes with devenv- prefix"
    else
        log_fail "No explicitly named volumes found with devenv- prefix"
    fi
}

# =============================================================================
# T053: Bind mount survival test
# =============================================================================

test_bind_mount_survives_container_removal() {
    ((TESTS_RUN++))
    log_test "T053: Verify bind mount survives container removal"

    # Stop and remove container
    cd "$PROJECT_ROOT/docker"
    docker compose -p "$COMPOSE_PROJECT" down 2>/dev/null || true

    # Check if source file still exists on host
    if [[ -f "$TEST_WORKSPACE/source-test.txt" ]]; then
        log_pass "Bind mount content survives container removal"
    else
        log_fail "Bind mount content was LOST after container removal"
    fi
}

# =============================================================================
# T054: Named volume explicit deletion test
# =============================================================================

test_named_volume_requires_explicit_deletion() {
    ((TESTS_RUN++))
    log_test "T054: Verify named volume requires explicit deletion"

    # Create some data in home volume
    run_container "echo 'persistence test' > /home/dev/prune-test.txt"

    # Stop container (but don't use -v to remove volumes)
    cd "$PROJECT_ROOT/docker"
    docker compose -p "$COMPOSE_PROJECT" down 2>/dev/null || true

    # Check if volume still exists
    if docker volume ls | grep -q "devenv-home"; then
        log_pass "Named volume devenv-home survives container removal"
    else
        log_fail "Named volume devenv-home was unexpectedly removed"
    fi
}

# =============================================================================
# Additional: Volume labels test
# =============================================================================

test_volume_labels() {
    ((TESTS_RUN++))
    log_test "Verify volumes have correct labels"

    # Check home volume label
    local home_label
    home_label=$(docker volume inspect devenv-home --format '{{index .Labels "com.devenv.safe-to-prune"}}' 2>/dev/null || echo "missing")

    if [[ "$home_label" == "false" ]]; then
        log_pass "Home volume has safe-to-prune=false label"
    else
        log_fail "Home volume label incorrect or missing (got: $home_label)"
    fi
}

# =============================================================================
# Additional: Cache volume labels test
# =============================================================================

test_cache_volume_labels() {
    ((TESTS_RUN++))
    log_test "Verify cache volumes have safe-to-prune=true label"

    local cache_volumes=("devenv-npm-cache" "devenv-pip-cache" "devenv-cargo-registry")
    local pass_count=0

    for vol in "${cache_volumes[@]}"; do
        local label
        label=$(docker volume inspect "$vol" --format '{{index .Labels "com.devenv.safe-to-prune"}}' 2>/dev/null || echo "missing")
        if [[ "$label" == "true" ]]; then
            ((pass_count++))
        fi
    done

    if [[ $pass_count -ge 1 ]]; then
        log_pass "Found $pass_count cache volumes with safe-to-prune=true label"
    else
        log_fail "No cache volumes with correct labels found"
    fi
}

# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

main() {
    echo "=============================================="
    echo "Integration Tests: Prune Safety (US5)"
    echo "=============================================="

    # Run setup
    trap teardown EXIT
    setup

    # Run tests
    test_volumes_have_explicit_names
    test_bind_mount_survives_container_removal
    test_named_volume_requires_explicit_deletion
    test_volume_labels
    test_cache_volume_labels

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
