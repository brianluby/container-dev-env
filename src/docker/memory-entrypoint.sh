#!/usr/bin/env bash
# T038: Memory-aware container entrypoint script.
#
# Detects .memory/ in the workspace directory and logs availability
# of strategic memory files. Then starts the original container command.
#
# Environment variables:
#   MEMORY_WORKSPACE - Path to the workspace directory (default: /workspace)
#
# Usage:
#   Set as ENTRYPOINT in Dockerfile, with CMD as the default command:
#     ENTRYPOINT ["/usr/local/bin/memory-entrypoint.sh"]
#     CMD ["bash"]

set -euo pipefail

WORKSPACE="${MEMORY_WORKSPACE:-/workspace}"
MEMORY_DIR="${WORKSPACE}/.memory"

# Detect strategic memory files
if [ -d "${MEMORY_DIR}" ]; then
    MD_COUNT=$(find "${MEMORY_DIR}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "${MD_COUNT}" -gt 0 ]; then
        echo "[memory-entrypoint] Strategic memory available: ${MD_COUNT} file(s) in ${MEMORY_DIR}" >&2
    else
        echo "[memory-entrypoint] .memory/ directory exists but contains no .md files" >&2
    fi

    # Check for .memoryrc configuration
    if [ -f "${MEMORY_DIR}/.memoryrc" ]; then
        echo "[memory-entrypoint] Configuration found: ${MEMORY_DIR}/.memoryrc" >&2
    fi
else
    echo "[memory-entrypoint] No .memory/ directory found in workspace (${WORKSPACE})" >&2
    echo "[memory-entrypoint] Run 'memory-init --workspace ${WORKSPACE}' to initialize" >&2
fi

# Execute the original container command
exec "$@"
