#!/bin/bash
# MCP Server Health Check Script
# Verifies that MCP servers are installed and runnable

set -e

PASS=0
FAIL=0

check_command() {
    local name="$1"
    local cmd="$2"

    if command -v "$cmd" &>/dev/null; then
        echo "[PASS] $name: $cmd found"
        ((PASS++))
        return 0
    else
        echo "[FAIL] $name: $cmd not found"
        ((FAIL++))
        return 1
    fi
}

check_npm_package() {
    local name="$1"
    local package="$2"

    if npm list -g "$package" &>/dev/null; then
        echo "[PASS] $name: $package installed"
        ((PASS++))
        return 0
    else
        echo "[FAIL] $name: $package not installed"
        ((FAIL++))
        return 1
    fi
}

echo "=========================================="
echo "MCP Server Health Check"
echo "=========================================="
echo ""

# Check Node.js
echo "--- Runtime Dependencies ---"
check_command "Node.js" "node"
check_command "npm" "npm"
check_command "npx" "npx"
echo ""

# Check MCP servers
echo "--- MCP Server Packages ---"
check_npm_package "Filesystem Server" "@modelcontextprotocol/server-filesystem"
check_npm_package "Memory Server" "@modelcontextprotocol/server-memory"
check_npm_package "Sequential Thinking" "@modelcontextprotocol/server-sequential-thinking"
check_npm_package "Context7" "@upstash/context7-mcp"
echo ""

# Check MCP server executables
echo "--- MCP Server Executables ---"
check_command "Filesystem MCP" "mcp-server-filesystem"
check_command "Memory MCP" "mcp-server-memory"
check_command "Sequential Thinking MCP" "mcp-server-sequential-thinking"
echo ""

# Summary
echo "=========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=========================================="

# Exit with failure if any checks failed
if [ $FAIL -gt 0 ]; then
    exit 1
fi

exit 0
