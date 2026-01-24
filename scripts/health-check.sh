#!/bin/bash
set -euo pipefail
# Container Dev Env - Health Check Script
# Validates that core tools are available and functional
# Used by HEALTHCHECK instruction for orchestration tools

set -e

# Check Python
python3 --version > /dev/null 2>&1 || { echo "FAIL: Python not available"; exit 1; }

# Check Node.js
node --version > /dev/null 2>&1 || { echo "FAIL: Node.js not available"; exit 1; }

# Check npm
npm --version > /dev/null 2>&1 || { echo "FAIL: npm not available"; exit 1; }

# Check pip
pip --version > /dev/null 2>&1 || { echo "FAIL: pip not available"; exit 1; }

# Check git
git --version > /dev/null 2>&1 || { echo "FAIL: git not available"; exit 1; }

# Check curl
curl --version > /dev/null 2>&1 || { echo "FAIL: curl not available"; exit 1; }

# Check jq
jq --version > /dev/null 2>&1 || { echo "FAIL: jq not available"; exit 1; }

# Check make
make --version > /dev/null 2>&1 || { echo "FAIL: make not available"; exit 1; }

# Check chezmoi (Feature: 002-dotfile-management)
chezmoi --version > /dev/null 2>&1 || { echo "FAIL: chezmoi not available"; exit 1; }

# All checks passed
echo "OK: All health checks passed"
exit 0
