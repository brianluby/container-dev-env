#!/bin/bash
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
if docker run --rm $IMAGE curl --version | head -1 | grep -q "curl"; then
    log_pass "TOOL-002: Curl is available"
else
    log_fail "TOOL-002: Curl is not available"
fi

# TOOL-003: Wget is available
if docker run --rm $IMAGE wget --version | head -1 | grep -q "GNU Wget"; then
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
if docker run --rm $IMAGE make --version | head -1 | grep -q "GNU Make"; then
    log_pass "TOOL-005: Make is available"
else
    log_fail "TOOL-005: Make is not available"
fi

# TOOL-006: GCC is available
if docker run --rm $IMAGE gcc --version | head -1 | grep -q "gcc"; then
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
if docker run --rm $IMAGE /home/dev/scripts/health-check.sh; then
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
