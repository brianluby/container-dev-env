#!/bin/bash
set -euo pipefail
# Container Dev Env - Acceptance Test Runner
# Validates container meets all specification requirements
# Spec: specs/001-container-base-image/contracts/test-contract.md

set -e

IMAGE="${1:-devcontainer}"
PASSED=0
FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASSED++)) || true
}

log_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAILED++)) || true
}

log_section() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Check if image exists
if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Image '$IMAGE' not found. Build it first with: docker build -t $IMAGE .${NC}"
    exit 2
fi

log_section "User Tests"

# USER-001: Default user is non-root
if [ "$(docker run --rm $IMAGE whoami)" = "dev" ]; then
    log_pass "USER-001: Default user is 'dev'"
else
    log_fail "USER-001: Default user is not 'dev'"
fi

# USER-004: UID is 1000
if [ "$(docker run --rm $IMAGE id -u)" = "1000" ]; then
    log_pass "USER-004: UID is 1000"
else
    log_fail "USER-004: UID is not 1000"
fi

# USER-005: GID is 1000
if [ "$(docker run --rm $IMAGE id -g)" = "1000" ]; then
    log_pass "USER-005: GID is 1000"
else
    log_fail "USER-005: GID is not 1000"
fi

# USER-002: Home directory exists
if docker run --rm $IMAGE ls -la /home/dev > /dev/null 2>&1; then
    log_pass "USER-002: Home directory exists"
else
    log_fail "USER-002: Home directory does not exist"
fi

# USER-003: Sudo access works
if docker run --rm $IMAGE sudo whoami | grep -q root; then
    log_pass "USER-003: Sudo access works"
else
    log_fail "USER-003: Sudo access does not work"
fi

log_section "Tool Tests"

# TOOL-001: Git is available
if docker run --rm $IMAGE git --version | grep -q "git version"; then
    log_pass "TOOL-001: Git is available"
else
    log_fail "TOOL-001: Git is not available"
fi

# TOOL-002: Curl is available
if docker run --rm $IMAGE bash -c 'curl --version >/dev/null 2>&1'; then
    log_pass "TOOL-002: Curl is available"
else
    log_fail "TOOL-002: Curl is not available"
fi

# TOOL-003: Wget is available
if docker run --rm $IMAGE bash -c 'wget --version >/dev/null 2>&1'; then
    log_pass "TOOL-003: Wget is available"
else
    log_fail "TOOL-003: Wget is not available"
fi

# TOOL-004: Jq is available
if docker run --rm $IMAGE jq --version | grep -q "jq-"; then
    log_pass "TOOL-004: Jq is available"
else
    log_fail "TOOL-004: Jq is not available"
fi

# TOOL-005: Make is available
if docker run --rm $IMAGE bash -c 'make --version >/dev/null 2>&1'; then
    log_pass "TOOL-005: Make is available"
else
    log_fail "TOOL-005: Make is not available"
fi

# TOOL-006: GCC is available
if docker run --rm $IMAGE bash -c 'gcc --version >/dev/null 2>&1'; then
    log_pass "TOOL-006: GCC is available"
else
    log_fail "TOOL-006: GCC is not available"
fi

log_section "Runtime Tests"

# PY-001: Python 3.14+ available
if docker run --rm $IMAGE python3 --version | grep -q "Python 3.14"; then
    log_pass "PY-001: Python 3.14+ available"
else
    log_fail "PY-001: Python 3.14+ not available"
fi

# PY-002: Pip is available
if docker run --rm $IMAGE pip --version | grep -q "pip"; then
    log_pass "PY-002: Pip is available"
else
    log_fail "PY-002: Pip is not available"
fi

# PY-003: Uv is available
if docker run --rm $IMAGE uv --version | grep -q "uv"; then
    log_pass "PY-003: Uv is available"
else
    log_fail "PY-003: Uv is not available"
fi

# NODE-001: Node.js 22.x LTS available
if docker run --rm $IMAGE node --version | grep -q "v22"; then
    log_pass "NODE-001: Node.js 22.x available"
else
    log_fail "NODE-001: Node.js 22.x not available"
fi

# NODE-002: Npm is available
if docker run --rm $IMAGE npm --version | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+"; then
    log_pass "NODE-002: Npm is available"
else
    log_fail "NODE-002: Npm is not available"
fi

log_section "Shell Tests"

# SHELL-001: Bash is default shell
if docker run --rm $IMAGE echo '$SHELL' | grep -q "/bin/bash" || docker run --rm $IMAGE bash -c 'echo $SHELL' | grep -q "/bin/bash"; then
    log_pass "SHELL-001: Bash is default shell"
else
    log_fail "SHELL-001: Bash is not default shell"
fi

# SHELL-002: ll alias works
if docker run --rm $IMAGE bash -ic "type ll" 2>&1 | grep -q "alias"; then
    log_pass "SHELL-002: ll alias works"
else
    log_fail "SHELL-002: ll alias does not work"
fi

# SHELL-003: la alias works
if docker run --rm $IMAGE bash -ic "type la" 2>&1 | grep -q "alias"; then
    log_pass "SHELL-003: la alias works"
else
    log_fail "SHELL-003: la alias does not work"
fi

# SHELL-004: HISTSIZE is set
if docker run --rm $IMAGE bash -c 'source ~/.bashrc && echo $HISTSIZE' | grep -q "1000"; then
    log_pass "SHELL-004: HISTSIZE is 1000"
else
    log_fail "SHELL-004: HISTSIZE is not 1000"
fi

log_section "Locale Tests"

# LOCALE-001: UTF-8 configured
if docker run --rm $IMAGE locale | grep -q "UTF-8"; then
    log_pass "LOCALE-001: UTF-8 configured"
else
    log_fail "LOCALE-001: UTF-8 not configured"
fi

# LOCALE-002: LANG is set
if docker run --rm $IMAGE bash -c 'echo $LANG' | grep -q "en_US.UTF-8"; then
    log_pass "LOCALE-002: LANG is en_US.UTF-8"
else
    log_fail "LOCALE-002: LANG is not en_US.UTF-8"
fi

log_section "Health Check Tests"

# HEALTH-001: Health check script passes
if docker run --rm $IMAGE /usr/local/bin/health-check.sh; then
    log_pass "HEALTH-001: Health check passes"
else
    log_fail "HEALTH-001: Health check fails"
fi

log_section "Native Extension Tests"

# PY-004: Can install numpy (Python native extensions)
if docker run --rm $IMAGE pip install --quiet numpy 2>&1; then
    log_pass "PY-004: Can install numpy (Python native extensions work)"
else
    log_fail "PY-004: Cannot install numpy"
fi

# NODE-003: Can install typescript (Node native extensions)
if docker run --rm $IMAGE bash -c 'npm install -g typescript >/dev/null 2>&1 && tsc --version' > /dev/null 2>&1; then
    log_pass "NODE-003: Can install typescript (Node native extensions work)"
else
    log_fail "NODE-003: Cannot install typescript"
fi

# =============================================================================
# Chezmoi Tests (Feature: 002-dotfile-management)
# =============================================================================

log_section "Chezmoi Tests"

# INST-001/002: Chezmoi binary exists and returns version
if docker run --rm $IMAGE chezmoi --version 2>&1 | grep -q "chezmoi version"; then
    log_pass "INST-001/002: Chezmoi is installed and executable"
else
    log_fail "INST-001/002: Chezmoi not available"
fi

# INST-003/004: age binary exists and returns version
if docker run --rm $IMAGE age --version 2>&1 | grep -q "v1"; then
    log_pass "INST-003/004: age is installed and executable"
else
    log_fail "INST-003/004: age not available"
fi

# INST-005/006: age-keygen binary exists and returns version
if docker run --rm $IMAGE age-keygen --version 2>&1 | grep -q "v1"; then
    log_pass "INST-005/006: age-keygen is installed and executable"
else
    log_fail "INST-005/006: age-keygen not available"
fi

# FUNC-004: chezmoi source-path is available
CHEZMOI_SOURCE_PATH="$(docker run --rm $IMAGE chezmoi source-path 2>/dev/null || true)"
if [[ -n "$CHEZMOI_SOURCE_PATH" ]] && [[ "$CHEZMOI_SOURCE_PATH" == /* ]]; then
    log_pass "FUNC-004: chezmoi source-path resolves"
else
    log_fail "FUNC-004: chezmoi source-path unavailable"
fi

# PERM-001: Non-root user can run chezmoi
if [ "$(docker run --rm $IMAGE whoami)" = "dev" ] && docker run --rm $IMAGE chezmoi --version > /dev/null 2>&1; then
    log_pass "PERM-001: Non-root user can run chezmoi"
else
    log_fail "PERM-001: Permission issues with chezmoi"
fi

log_section "Chezmoi Template Tests"

# TMPL-001: Hostname template variable
if docker run --rm $IMAGE chezmoi execute-template '{{ .chezmoi.hostname }}' 2>&1 | grep -qE ".+"; then
    log_pass "TMPL-001: Hostname template variable works"
else
    log_fail "TMPL-001: Hostname template variable not working"
fi

# TMPL-002: OS template variable returns 'linux'
if docker run --rm $IMAGE chezmoi execute-template '{{ .chezmoi.os }}' 2>&1 | grep -q "linux"; then
    log_pass "TMPL-002: OS template variable returns 'linux'"
else
    log_fail "TMPL-002: OS template variable not working"
fi

# TMPL-003: Arch template variable (amd64 or arm64)
if docker run --rm $IMAGE chezmoi execute-template '{{ .chezmoi.arch }}' 2>&1 | grep -qE "(amd64|arm64)"; then
    log_pass "TMPL-003: Arch template variable works"
else
    log_fail "TMPL-003: Arch template variable not working"
fi

# TMPL-004: Username template variable returns 'dev'
if docker run --rm $IMAGE chezmoi execute-template '{{ .chezmoi.username }}' 2>&1 | grep -q "dev"; then
    log_pass "TMPL-004: Username template variable returns 'dev'"
else
    log_fail "TMPL-004: Username template variable not working"
fi

# TMPL-005: homeDir template variable returns '/home/dev'
if docker run --rm $IMAGE chezmoi execute-template '{{ .chezmoi.homeDir }}' 2>&1 | grep -q "/home/dev"; then
    log_pass "TMPL-005: homeDir template variable returns '/home/dev'"
else
    log_fail "TMPL-005: homeDir template variable not working"
fi

log_section "Chezmoi Permission Tests"

# PERM-002: Source directory is writable
if docker run --rm $IMAGE bash -c 'mkdir -p ~/.local/share/chezmoi && touch ~/.local/share/chezmoi/.test && rm ~/.local/share/chezmoi/.test' 2>&1; then
    log_pass "PERM-002: Source directory (~/.local/share/chezmoi) is writable"
else
    log_fail "PERM-002: Source directory is not writable"
fi

# PERM-003: Config directory is writable
if docker run --rm $IMAGE bash -c 'mkdir -p ~/.config/chezmoi && touch ~/.config/chezmoi/.test && rm ~/.config/chezmoi/.test' 2>&1; then
    log_pass "PERM-003: Config directory (~/.config/chezmoi) is writable"
else
    log_fail "PERM-003: Config directory is not writable"
fi

log_section "Chezmoi Encryption Tests"

# ENC-001: age-keygen generates key pair
AGE_KEYGEN_OUTPUT="$(docker run --rm $IMAGE bash -c 'age-keygen 2>&1' || true)"
if printf '%s' "$AGE_KEYGEN_OUTPUT" | grep -q "public key"; then
    log_pass "ENC-001: age-keygen generates key pair"
else
    log_fail "ENC-001: age-keygen not working"
fi

# Summary
log_section "Summary"
TOTAL=$((PASSED + FAILED))
echo -e "Passed: ${GREEN}$PASSED${NC}/$TOTAL"
echo -e "Failed: ${RED}$FAILED${NC}/$TOTAL"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}=== All tests passed ===${NC}"
    exit 0
else
    echo -e "\n${RED}=== Some tests failed ===${NC}"
    exit 1
fi
