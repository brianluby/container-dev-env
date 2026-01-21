#!/bin/bash
# =============================================================================
# Entrypoint Contract: Volume Architecture
# Feature: 004-volume-architecture
# Date: 2026-01-20
#
# This contract defines the expected behavior of the container entrypoint script.
# Implementation MUST satisfy all requirements documented here.
# =============================================================================

# =============================================================================
# CONFIGURATION CONTRACT
# =============================================================================

# Environment variables (with defaults)
# LOCAL_UID: Host user UID (default: 1000)
# LOCAL_GID: Host user GID (default: 1000)

# Volume directories requiring permission fixes (named volumes only)
VOLUME_DIRS=(
    "/home/dev"
    "/home/dev/.npm"
    "/home/dev/.cache/pip"
    "/home/dev/.cargo/registry"
    "/workspace/node_modules"
    "/workspace/target"
)

# =============================================================================
# BEHAVIOR CONTRACT
# =============================================================================

# 1. VALIDATION PHASE (FR-013)
# -----------------------------------------------------------------------------
# MUST: Check /workspace bind mount exists
# MUST: Fail with exit code 1 and clear error message if missing
# MUST: Log error to stderr with path information

# 2. PERMISSION FIX PHASE (FR-005, FR-006)
# -----------------------------------------------------------------------------
# MUST: Detect host UID from LOCAL_UID (default 1000)
# MUST: Detect host GID from LOCAL_GID (default 1000)
# MUST: For each directory in VOLUME_DIRS:
#   - Skip if directory doesn't exist
#   - Check current ownership
#   - If owned by root (UID 0), change to LOCAL_UID:LOCAL_GID
#   - Use sudo for permission changes (non-root container user)
# MUST: Complete permission fixes in under 3 seconds (SC-003)

# 3. LOGGING PHASE (FR-014)
# -----------------------------------------------------------------------------
# MUST: Log to stderr with "[entrypoint]" prefix
# MUST: Log at startup:
#   - Current user and UID/GID
#   - Volume mount status for /workspace and /home/dev
#   - Any permission changes made
#   - Any warnings (missing volumes, permission issues)
# SHOULD: Log working directory
# SHOULD: Log environment (LOCAL_UID, LOCAL_GID values)

# 4. VOLUME RECOVERY PHASE (FR-012)
# -----------------------------------------------------------------------------
# MUST: If named volume directory is missing:
#   - Log warning (not error)
#   - Create directory with correct ownership
#   - Continue startup (do not fail)

# 5. EXECUTION PHASE
# -----------------------------------------------------------------------------
# MUST: Use `exec "$@"` to replace shell process with command
# MUST: Ensure signals (SIGTERM, SIGINT) reach the child process
# MUST: If no command provided, default to interactive shell

# =============================================================================
# OUTPUT CONTRACT
# =============================================================================

# Exit Codes:
# 0   - Success (or command exit code)
# 1   - Workspace bind mount missing (FR-013)
# 126 - Command not executable
# 127 - Command not found

# Log Format:
# [entrypoint] <message>
# [entrypoint] ERROR: <error message>
# [entrypoint] WARNING: <warning message>

# Example output on successful startup:
# [entrypoint] === Container Entrypoint Starting ===
# [entrypoint] User: dev (UID: 1000, GID: 1000)
# [entrypoint] LOCAL_UID: 501, LOCAL_GID: 20
# [entrypoint] === Validating Bind Mounts ===
# [entrypoint]   /workspace: mounted and writable
# [entrypoint] === Fixing Named Volume Permissions ===
# [entrypoint]   Fixing ownership: /home/dev (root -> 501:20)
# [entrypoint]   Fixing ownership: /home/dev/.npm (root -> 501:20)
# [entrypoint] === Volume Status ===
# [entrypoint]   /workspace: owner=dev:dev, size=1.2G
# [entrypoint]   /home/dev: owner=dev:dev, size=45M
# [entrypoint] === Container Ready ===
# [entrypoint] Executing: /bin/bash -l

# Example output on workspace missing:
# [entrypoint] === Container Entrypoint Starting ===
# [entrypoint] === Validating Bind Mounts ===
# [entrypoint] ERROR: workspace bind mount not found at /workspace
# [entrypoint] Please run with: docker run -v ./src:/workspace:cached ...
# (exits with code 1)

# =============================================================================
# PERFORMANCE CONTRACT
# =============================================================================

# Startup overhead MUST be under 3 seconds (SC-003)
# Permission fixes MUST be targeted (not recursive scan of entire filesystem)
# Only fix directories in VOLUME_DIRS (not bind mounts)

# =============================================================================
# COMPATIBILITY CONTRACT
# =============================================================================

# MUST: Work with bash and sh
# MUST: Handle both Linux stat and macOS stat syntax
# MUST: Work as PID 1 (init process)
# MUST: Work with docker-compose and VS Code devcontainers
# MUST: Support macOS UID 501 and Linux UID 1000+
