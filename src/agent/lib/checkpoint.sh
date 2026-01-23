#!/usr/bin/env bash
# checkpoint.sh — Git-based checkpoint operations
# Version: 1.0.0
# Dependencies: git

set -euo pipefail

# create_checkpoint <session_id> <description> <operation_type>
# Creates a git stash as a checkpoint before an operation
create_checkpoint() {
  local session_id="$1"
  local description="$2"
  local operation_type="$3"
  local timestamp
  timestamp=$(date -u +"%Y%m%dT%H%M%SZ")

  # Check disk space first
  check_disk_space || return 1

  # Stage all changes for stashing
  git add -A 2>/dev/null || true

  # Create stash with metadata in message
  local message="checkpoint: ${timestamp} [${operation_type}] ${description}"
  if git stash push -m "${message}" 2>/dev/null; then
    # Check if stash was actually created (no changes = no stash)
    if git stash list | head -1 | grep -q "${timestamp}"; then
      return 0
    fi
  fi

  # If no changes to stash, that's ok
  return 0
}

# list_checkpoints [session_id]
# Lists all checkpoints with timestamps and descriptions
list_checkpoints() {
  git stash list --format="%gd: %gs" 2>/dev/null | grep "checkpoint:" || true
}

# rollback_checkpoint <checkpoint_id>
# Restores the codebase to the given checkpoint state
rollback_checkpoint() {
  local checkpoint_id="$1"

  # Verify checkpoint exists
  if ! git stash list | grep -q "${checkpoint_id}"; then
    echo "Error: Checkpoint '${checkpoint_id}' not found" >&2
    return 1
  fi

  # Apply the stash (keep it in the stash list for history)
  git stash apply "${checkpoint_id}" 2>/dev/null || {
    echo "Error: Failed to apply checkpoint '${checkpoint_id}'" >&2
    return 1
  }

  return 0
}

# prune_checkpoints <max_count>
# Removes oldest checkpoints when count exceeds max
prune_checkpoints() {
  local max_count="${1:-${AGENT_CFG_CHECKPOINT_MAX_COUNT:-50}}"
  local count
  count=$(git stash list | wc -l | tr -d ' ')

  while [[ "${count}" -gt "${max_count}" ]]; do
    # Drop the oldest stash (highest index)
    local oldest_idx=$((count - 1))
    git stash drop "stash@{${oldest_idx}}" 2>/dev/null || break
    count=$((count - 1))
  done

  return 0
}

# check_disk_space
# Warns if available disk space is below threshold (100MB)
check_disk_space() {
  local threshold_kb=102400  # 100MB in KB
  local available_kb
  available_kb=$(df -k . | tail -1 | awk '{print $4}')

  if [[ "${available_kb}" -lt "${threshold_kb}" ]]; then
    echo "Warning: Low disk space ($(( available_kb / 1024 ))MB available). Checkpoint may fail." >&2
    return 1
  fi

  return 0
}

# get_checkpoint_files <checkpoint_id>
# Returns list of files affected in a checkpoint
get_checkpoint_files() {
  local checkpoint_id="$1"
  git stash show "${checkpoint_id}" --name-only 2>/dev/null || true
}
