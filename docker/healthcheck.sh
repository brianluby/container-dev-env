#!/usr/bin/env bash
# healthcheck.sh — Container health check for agent layer
# Verifies agent binaries are functional
# Used by: HEALTHCHECK directive in Dockerfile.agent

set -euo pipefail

# Check OpenCode (always installed)
if ! opencode --version > /dev/null 2>&1; then
  echo "UNHEALTHY: opencode binary not functional" >&2
  exit 1
fi

# Check Claude Code (only if installed)
if command -v claude &>/dev/null; then
  if ! claude --version > /dev/null 2>&1; then
    echo "UNHEALTHY: claude binary not functional" >&2
    exit 1
  fi
fi

# Check agent wrapper
if ! agent --version > /dev/null 2>&1; then
  echo "UNHEALTHY: agent wrapper not functional" >&2
  exit 1
fi

exit 0
