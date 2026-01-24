#!/usr/bin/env bash
# Contract: Strategic Memory Initialization CLI
# Usage: memory-init [--workspace PATH] [--force]
#
# Creates the .memory/ directory structure with template files.
# Idempotent: skips existing files unless --force is specified.
#
# Exit codes:
#   0 - Success (files created or already exist)
#   1 - Invalid arguments
#   2 - Workspace path does not exist
#   3 - Permission denied

set -euo pipefail

# --- Contract: CLI Arguments ---
# --workspace PATH  : Target workspace (default: current directory)
# --force           : Overwrite existing template files
# --quiet           : Suppress informational output

# --- Contract: Created File Structure ---
# .memory/
# ├── goals.md           # Project objectives template
# ├── architecture.md    # System design template
# ├── patterns.md        # Coding conventions template
# ├── technology.md      # Stack choices template
# ├── status.md          # Current work state template
# └── .memoryrc          # Configuration file (YAML)

# --- Contract: .memoryrc Default Content ---
# retention_days: 30
# max_size_mb: 500
# excluded_patterns:
#   - "*.key"
#   - "*.pem"
#   - "*password*"
#   - "*secret*"
#   - "*token*"

# --- Contract: Template File Format ---
# Each .md file contains:
# - H1 heading with category name
# - Brief description of what belongs in this file
# - H2 placeholder sections with guidance comments
# - Example entries (commented out)

# --- Contract: .gitignore Integration ---
# If .gitignore exists in workspace:
#   - Ensure `.memory/.memoryrc` is NOT ignored (config is shared)
#   - Ensure tactical memory paths are ignored
# Creates .memory/.gitignore with:
#   - !*.md          (strategic files tracked)
#   - !.memoryrc     (config tracked)
#   - *.db           (tactical DB excluded)
#   - *.db-wal       (WAL file excluded)
#   - *.db-shm       (shared memory excluded)

echo "Contract: memory-init CLI specification"
echo "Implementation pending in /speckit.tasks phase"
