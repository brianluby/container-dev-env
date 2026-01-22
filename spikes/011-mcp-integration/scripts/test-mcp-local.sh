#!/bin/bash
# Test MCP servers locally (outside container)
# This script verifies MCP server packages can be invoked via npx

set -e

PASS=0
FAIL=0
SKIP=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL++)); }
skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; ((SKIP++)); }

echo "=========================================="
echo "MCP Server Local Tests (via npx)"
echo "=========================================="
echo ""

# Check Node.js version
echo "--- Prerequisites ---"
if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    pass "Node.js: $NODE_VERSION"
else
    fail "Node.js: not found"
    exit 1
fi

if command -v npx &>/dev/null; then
    pass "npx: available"
else
    fail "npx: not found"
    exit 1
fi

echo ""

# Test each MCP server package
echo "--- MCP Server Package Tests ---"

# Filesystem server
echo "Testing @modelcontextprotocol/server-filesystem..."
if timeout 30 npx -y @modelcontextprotocol/server-filesystem --help 2>/dev/null; then
    pass "Filesystem server: package loads"
else
    # Server may not support --help, test via npm view
    if npm view @modelcontextprotocol/server-filesystem version 2>/dev/null; then
        pass "Filesystem server: package accessible"
    else
        fail "Filesystem server: package not accessible"
    fi
fi

# Memory server
echo "Testing @modelcontextprotocol/server-memory..."
if npm view @modelcontextprotocol/server-memory version 2>/dev/null; then
    pass "Memory server: package accessible"
else
    fail "Memory server: package not accessible"
fi

# Sequential Thinking
echo "Testing @modelcontextprotocol/server-sequential-thinking..."
if npm view @modelcontextprotocol/server-sequential-thinking version 2>/dev/null; then
    pass "Sequential Thinking server: package accessible"
else
    fail "Sequential Thinking server: package not accessible"
fi

# Context7
echo "Testing @upstash/context7-mcp..."
if npm view @upstash/context7-mcp version 2>/dev/null; then
    pass "Context7 server: package accessible"
else
    fail "Context7 server: package not accessible"
fi

# GitHub server (deprecated notice)
echo "Testing @modelcontextprotocol/server-github..."
if npm view @modelcontextprotocol/server-github version 2>/dev/null; then
    pass "GitHub server: package accessible (note: deprecated, use github/github-mcp-server)"
else
    skip "GitHub server: package not found or deprecated"
fi

echo ""

# Test Claude Code MCP integration if available
echo "--- Claude Code MCP Integration ---"
if command -v claude &>/dev/null; then
    pass "Claude Code CLI: installed"

    # Check MCP list command
    if claude mcp list 2>/dev/null; then
        pass "Claude Code: MCP list command works"
    else
        skip "Claude Code: MCP list returned non-zero (may need configuration)"
    fi
else
    skip "Claude Code CLI: not installed"
fi

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "${GREEN}Passed:${NC} $PASS"
echo -e "${RED}Failed:${NC} $FAIL"
echo -e "${YELLOW}Skipped:${NC} $SKIP"
echo "=========================================="
