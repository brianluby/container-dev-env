#!/bin/bash
# =============================================================================
# Integration Tests: Documentation (US6 - New Developer Onboarding)
# Feature: 004-volume-architecture
# =============================================================================
# Tests for documentation completeness
# Success criteria: New developers understand persistence model within 5 minutes
# =============================================================================

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

# =============================================================================
# T059: Documentation completeness checklist
# =============================================================================

test_volume_architecture_doc_exists() {
    ((TESTS_RUN++))
    log_test "T059.1: Verify docs/volume-architecture.md exists"

    if [[ -f "$PROJECT_ROOT/docs/volume-architecture.md" ]]; then
        log_pass "docs/volume-architecture.md exists"
    else
        log_fail "docs/volume-architecture.md is missing"
    fi
}

test_doc_has_overview() {
    ((TESTS_RUN++))
    log_test "T059.2: Verify documentation has overview section"

    if grep -qi "overview\|introduction\|architecture" "$PROJECT_ROOT/docs/volume-architecture.md" 2>/dev/null; then
        log_pass "Documentation has overview/introduction section"
    else
        log_fail "Documentation missing overview section"
    fi
}

test_doc_has_persistence_table() {
    ((TESTS_RUN++))
    log_test "T059.3: Verify documentation has persistence model table"

    if grep -q "|.*|.*|" "$PROJECT_ROOT/docs/volume-architecture.md" 2>/dev/null; then
        log_pass "Documentation has table (persistence model)"
    else
        log_fail "Documentation missing persistence table"
    fi
}

test_doc_has_volume_types() {
    ((TESTS_RUN++))
    log_test "T059.4: Verify documentation covers all volume types"

    local doc_file="$PROJECT_ROOT/docs/volume-architecture.md"
    local found=0

    if grep -qi "bind mount" "$doc_file" 2>/dev/null; then ((found++)); fi
    if grep -qi "named volume" "$doc_file" 2>/dev/null; then ((found++)); fi
    if grep -qi "tmpfs" "$doc_file" 2>/dev/null; then ((found++)); fi

    if [[ $found -ge 3 ]]; then
        log_pass "Documentation covers all volume types (bind, named, tmpfs)"
    else
        log_fail "Documentation missing volume type coverage (found $found/3)"
    fi
}

test_doc_has_faq() {
    ((TESTS_RUN++))
    log_test "T059.5: Verify documentation has FAQ or common scenarios"

    if grep -qi "faq\|scenario\|question\|common" "$PROJECT_ROOT/docs/volume-architecture.md" 2>/dev/null; then
        log_pass "Documentation has FAQ/scenarios section"
    else
        log_fail "Documentation missing FAQ section"
    fi
}

test_doc_has_troubleshooting() {
    ((TESTS_RUN++))
    log_test "T059.6: Verify documentation has troubleshooting section"

    if grep -qi "troubleshoot\|debug\|problem\|issue" "$PROJECT_ROOT/docs/volume-architecture.md" 2>/dev/null; then
        log_pass "Documentation has troubleshooting section"
    else
        log_fail "Documentation missing troubleshooting section"
    fi
}

test_compose_has_comments() {
    ((TESTS_RUN++))
    log_test "T059.7: Verify docker-compose.yml has inline comments"

    local comment_count
    comment_count=$(grep -c "^[[:space:]]*#" "$PROJECT_ROOT/docker/docker-compose.yml" 2>/dev/null || echo "0")

    if [[ $comment_count -ge 10 ]]; then
        log_pass "docker-compose.yml has $comment_count comment lines"
    else
        log_fail "docker-compose.yml lacks sufficient comments (found $comment_count)"
    fi
}

# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

main() {
    echo "=============================================="
    echo "Integration Tests: Documentation (US6)"
    echo "=============================================="

    # Run tests
    test_volume_architecture_doc_exists
    test_doc_has_overview
    test_doc_has_persistence_table
    test_doc_has_volume_types
    test_doc_has_faq
    test_doc_has_troubleshooting
    test_compose_has_comments

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
