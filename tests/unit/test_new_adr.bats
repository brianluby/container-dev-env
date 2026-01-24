#!/usr/bin/env bats

# Tests for src/scripts/new-adr.sh
# Verifies: sequential numbering, template copy, kebab-case naming

setup() {
    # Create a temporary directory for test isolation
    TEST_DIR="$(mktemp -d)"
    TEST_DOCS_DIR="${TEST_DIR}/docs/decisions"
    mkdir -p "${TEST_DOCS_DIR}"

    # Copy the ADR template to the test directory
    cp "$(git rev-parse --show-toplevel)/docs/decisions/_template.md" "${TEST_DOCS_DIR}/_template.md"

    # Path to the script under test
    SCRIPT="$(git rev-parse --show-toplevel)/src/scripts/new-adr.sh"
}

teardown() {
    # Clean up temporary directory
    rm -rf "${TEST_DIR}"
}

@test "creates first ADR with number 001" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Use REST for API"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/001-use-rest-for-api.md" ]
}

@test "creates second ADR with number 002" {
    # Create a first ADR manually
    touch "${TEST_DOCS_DIR}/001-first-decision.md"

    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Use PostgreSQL for Storage"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/002-use-postgresql-for-storage.md" ]
}

@test "converts title to kebab-case" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Use GraphQL Over REST"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/001-use-graphql-over-rest.md" ]
}

@test "handles title with special characters" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Use Node.js for Backend"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/001-use-node-js-for-backend.md" ]
}

@test "handles title with forward slashes" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Use HTTP/2 for API"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/001-use-http-2-for-api.md" ]
    # Verify title appears correctly in file content
    grep -q "Use HTTP/2 for API" "${TEST_DOCS_DIR}/001-use-http-2-for-api.md"
}

@test "handles title with ampersands" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Use A & B Together"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/001-use-a-b-together.md" ]
    # Verify title appears correctly in file content
    grep -q "Use A & B Together" "${TEST_DOCS_DIR}/001-use-a-b-together.md"
}

@test "handles title with backslashes" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Handle Path\\Separators"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/001-handle-path-separators.md" ]
    # Verify title appears correctly in file content
    grep -q "Handle Path" "${TEST_DOCS_DIR}/001-handle-path-separators.md"
}

@test "allows multiple ADRs with same title by auto-incrementing" {
    # Running the script twice with the same title should create two files
    # with different numbers (this is expected behavior, not an error)
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Same Title"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/001-same-title.md" ]

    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Same Title"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/002-same-title.md" ]

    # The file existence check prevents overwrites in race conditions
    # but is difficult to test reliably in a unit test
}

@test "copies template content into new ADR" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Sample Decision"
    [ "$status" -eq 0 ]

    # Verify template sections are present
    grep -q "## Context" "${TEST_DOCS_DIR}/001-sample-decision.md"
    grep -q "## Decision" "${TEST_DOCS_DIR}/001-sample-decision.md"
    grep -q "## Alternatives Considered" "${TEST_DOCS_DIR}/001-sample-decision.md"
    grep -q "## Consequences" "${TEST_DOCS_DIR}/001-sample-decision.md"
}

@test "sets title in ADR header" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Adopt Microservices"
    [ "$status" -eq 0 ]

    # First line should contain the title
    head -1 "${TEST_DOCS_DIR}/001-adopt-microservices.md" | grep -q "Adopt Microservices"
}

@test "sets status to Proposed" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "New Approach"
    [ "$status" -eq 0 ]

    grep -q "Proposed" "${TEST_DOCS_DIR}/001-new-approach.md"
}

@test "sets current date" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Dated Decision"
    [ "$status" -eq 0 ]

    today="$(date +%Y-%m-%d)"
    grep -q "${today}" "${TEST_DOCS_DIR}/001-dated-decision.md"
}

@test "fails with no title argument" {
    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}"
    [ "$status" -eq 2 ]
}

@test "fails when template is missing" {
    rm "${TEST_DOCS_DIR}/_template.md"

    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "No Template"
    [ "$status" -eq 1 ]
}

@test "correctly sequences after gap in numbering" {
    # Create ADRs with a gap (001, 003)
    touch "${TEST_DOCS_DIR}/001-first.md"
    touch "${TEST_DOCS_DIR}/003-third.md"

    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "After Gap"
    [ "$status" -eq 0 ]
    # Should use next number after highest existing (004)
    [ -f "${TEST_DOCS_DIR}/004-after-gap.md" ]
}

@test "handles three-digit numbers correctly" {
    # Create ADR 099
    touch "${TEST_DOCS_DIR}/099-high-number.md"

    run bash "${SCRIPT}" --docs-dir "${TEST_DOCS_DIR}" "Century Mark"
    [ "$status" -eq 0 ]
    [ -f "${TEST_DOCS_DIR}/100-century-mark.md" ]
}
