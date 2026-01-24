#!/usr/bin/env bats
# Unit tests for safe secrets loader (T017)
# Tests: T017 (safe line-by-line .env parser with key validation and injection prevention)
# TDD: These tests validate the _secrets_load_safe function in scripts/secrets-load.sh

load '../unit/.bats-battery/bats-support/load'
load '../unit/.bats-battery/bats-assert/load'

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
SECRETS_LOAD_SCRIPT="${REPO_ROOT}/scripts/secrets-load.sh"

setup() {
    TEST_TMPDIR="$(mktemp -d)"
    SECRETS_FILE="${TEST_TMPDIR}/test.env"

    # Export REPO_ROOT so the script can find secrets-common.sh
    export REPO_ROOT

    # Ensure canary file does not exist at start
    CANARY_FILE="${TEST_TMPDIR}/CANARY_FILE"
    export CANARY_FILE
}

teardown() {
    if [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]]; then
        rm -rf "${TEST_TMPDIR}"
    fi
}

# =============================================================================
# T017.1 - Valid KEY=VALUE parsing exports correctly
# =============================================================================

@test "T017: valid KEY=VALUE pairs are exported correctly" {
    cat > "${SECRETS_FILE}" <<'EOF'
API_KEY=my-secret-key
DATABASE_URL=postgres://localhost:5432/mydb
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
        echo \"API_KEY=\${API_KEY}\"
        echo \"DATABASE_URL=\${DATABASE_URL}\"
    "
    assert_success
    assert_output --partial "API_KEY=my-secret-key"
    assert_output --partial "DATABASE_URL=postgres://localhost:5432/mydb"
}

# =============================================================================
# T017.2 - First-= split preserves KEY=val=ue
# =============================================================================

@test "T017: first-= split preserves values containing equals signs" {
    cat > "${SECRETS_FILE}" <<'EOF'
CONNECTION_STRING=host=db;user=admin;pass=s3cr=t
BASE64_VALUE=dGVzdA==
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
        echo \"CONNECTION_STRING=\${CONNECTION_STRING}\"
        echo \"BASE64_VALUE=\${BASE64_VALUE}\"
    "
    assert_success
    assert_output --partial "CONNECTION_STRING=host=db;user=admin;pass=s3cr=t"
    assert_output --partial "BASE64_VALUE=dGVzdA=="
}

# =============================================================================
# T017.3 - Key validation rejects invalid keys with [WARN]
# =============================================================================

@test "T017: key starting with digit is rejected with WARN" {
    cat > "${SECRETS_FILE}" <<'EOF'
2INVALID=value
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_output --partial "[WARN]"
    assert_output --partial "2INVALID"
}

@test "T017: key with hyphen is rejected with WARN" {
    cat > "${SECRETS_FILE}" <<'EOF'
INVALID-KEY=value
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_output --partial "[WARN]"
    assert_output --partial "INVALID-KEY"
}

@test "T017: lowercase key is rejected with WARN" {
    cat > "${SECRETS_FILE}" <<'EOF'
lowercase=value
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_output --partial "[WARN]"
    assert_output --partial "lowercase"
}

# =============================================================================
# T017.4 - Command substitution patterns are rejected and NOT executed
# =============================================================================

@test "T017: dollar-paren command substitution is rejected with WARN" {
    cat > "${SECRETS_FILE}" <<'EOF'
INJECTED=$(echo pwned)
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_output --partial "[WARN]"
    refute_output --partial "pwned"
}

@test "T017: dollar-brace substitution is rejected with WARN" {
    cat > "${SECRETS_FILE}" <<'EOF'
INJECTED=${PATH}
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_output --partial "[WARN]"
}

@test "T017: backtick command substitution is rejected with WARN" {
    cat > "${SECRETS_FILE}" <<'EOF'
INJECTED=`echo pwned`
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_output --partial "[WARN]"
    refute_output --partial "pwned"
}

@test "T017: canary file is NOT created by command substitution in value" {
    local canary="${TEST_TMPDIR}/CANARY_CREATED"
    cat > "${SECRETS_FILE}" <<EOF
EVIL=\$(touch ${canary})
EOF
    chmod 0600 "${SECRETS_FILE}"

    bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
    " 2>/dev/null || true

    # The canary file must NOT have been created
    [ ! -f "${canary}" ]
}

@test "T017: backtick canary file is NOT created" {
    local canary="${TEST_TMPDIR}/CANARY_BACKTICK"
    cat > "${SECRETS_FILE}" <<EOF
EVIL=\`touch ${canary}\`
EOF
    chmod 0600 "${SECRETS_FILE}"

    bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
    " 2>/dev/null || true

    # The canary file must NOT have been created
    [ ! -f "${canary}" ]
}

# =============================================================================
# T017.5 - Bare $ in values is allowed
# =============================================================================

@test "T017: bare dollar sign in value is allowed" {
    cat > "${SECRETS_FILE}" <<'EOF'
PRICE=costs$100
CURRENCY=$USD
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
        echo \"PRICE=\${PRICE}\"
        echo \"CURRENCY=\${CURRENCY}\"
    "
    assert_success
    assert_output --partial 'PRICE=costs$100'
    assert_output --partial 'CURRENCY=$USD'
}

# =============================================================================
# T017.6 - World-readable file is rejected with [ERROR] before any parsing
# =============================================================================

@test "T017: world-readable file (0644) is rejected with ERROR" {
    cat > "${SECRETS_FILE}" <<'EOF'
SECRET_KEY=should-not-load
EOF
    chmod 0644 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_failure
    assert_output --partial "[ERROR]"
    assert_output --partial "world-readable"
}

@test "T017: world-readable file prevents any variable from being exported" {
    cat > "${SECRETS_FILE}" <<'EOF'
SHOULD_NOT_EXIST=leaked
EOF
    chmod 0644 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>/dev/null
        echo \"VAR=\${SHOULD_NOT_EXIST:-unset}\"
    "
    assert_output --partial "VAR=unset"
}

# =============================================================================
# T017.7 - Comments and blank lines are skipped
# =============================================================================

@test "T017: comment lines and blank lines are skipped" {
    cat > "${SECRETS_FILE}" <<'EOF'
# This is a comment
FIRST_KEY=first_value

# Another comment
SECOND_KEY=second_value

EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
        echo \"FIRST_KEY=\${FIRST_KEY}\"
        echo \"SECOND_KEY=\${SECOND_KEY}\"
    "
    assert_success
    assert_output --partial "FIRST_KEY=first_value"
    assert_output --partial "SECOND_KEY=second_value"
    # No warnings should be emitted for comments/blanks
    refute_output --partial "[WARN]"
    refute_output --partial "[ERROR]"
}

# =============================================================================
# T017.8 - Values starting with = (empty key side) handled correctly
# =============================================================================

@test "T017: line starting with = (empty key) is warned and skipped" {
    cat > "${SECRETS_FILE}" <<'EOF'
=value_with_no_key
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_output --partial "[WARN]"
}

# =============================================================================
# Additional edge cases
# =============================================================================

@test "T017: key with underscore prefix is valid" {
    cat > "${SECRETS_FILE}" <<'EOF'
_PRIVATE_KEY=secret123
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
        echo \"_PRIVATE_KEY=\${_PRIVATE_KEY}\"
    "
    assert_success
    assert_output --partial "_PRIVATE_KEY=secret123"
}

@test "T017: properly restricted file (0600) is accepted" {
    cat > "${SECRETS_FILE}" <<'EOF'
GOOD_KEY=good_value
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
        echo \"GOOD_KEY=\${GOOD_KEY}\"
    "
    assert_success
    assert_output --partial "GOOD_KEY=good_value"
    refute_output --partial "[ERROR]"
}

@test "T017: empty value is allowed" {
    cat > "${SECRETS_FILE}" <<'EOF'
EMPTY_VAR=
EOF
    chmod 0600 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}'
        echo \"EMPTY_VAR=[\${EMPTY_VAR}]\"
    "
    assert_success
    assert_output --partial "EMPTY_VAR=[]"
}

@test "T017: group-writable file (0660) is rejected with ERROR" {
    cat > "${SECRETS_FILE}" <<'EOF'
SECRET=should-not-load
EOF
    chmod 0660 "${SECRETS_FILE}"

    run bash -c "
        source '${REPO_ROOT}/scripts/secrets-common.sh'
        _SECRETS_LOAD_SOURCED=true
        source '${SECRETS_LOAD_SCRIPT}'
        _secrets_load_safe '${SECRETS_FILE}' 2>&1
    "
    assert_failure
    assert_output --partial "[ERROR]"
}
