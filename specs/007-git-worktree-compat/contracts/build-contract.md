# Build Contract: Git Worktree Compatibility

**Feature**: 007-git-worktree-compat
**Date**: 2026-01-22

## Overview

This contract defines the build and integration requirements for the worktree validation addition to the container entrypoint script.

## Build Command

```bash
# No separate build step — the entrypoint.sh is a shell script copied into the image.
# Build the container image (includes updated entrypoint):
docker build -t devcontainer .

# Install BATS for local test development:
npm install -g bats bats-support bats-assert
```

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| docker/entrypoint.sh | file | Yes | Container entrypoint with validate_worktree() function |
| tests/unit/test_worktree_validation.bats | file | Yes | BATS unit tests |
| tests/integration/test_worktree_container.sh | file | Yes | Docker integration tests |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| Container Image | OCI image | Updated image with worktree-aware entrypoint |
| BATS test results | TAP output | Unit test results for validation logic |
| Integration test results | text | Docker-based scenario test results |

## Environment Variables (Runtime)

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| WORKSPACE_DIR | /workspace | No | Path to workspace directory for worktree detection |

## Function Contract: validate_worktree()

### Signature

```bash
validate_worktree()
# No arguments — reads $WORKSPACE_DIR (or defaults to /workspace)
# No return value — always succeeds (non-blocking)
# Side effects: prints to stderr if worktree metadata is inaccessible
```

### Preconditions

- `$WORKSPACE_DIR` directory exists (validated by prior `validate_workspace` call)
- `log_warning` and `log` functions are defined (from entrypoint.sh)

### Postconditions

- If workspace is not a git repo: no output, function returns 0
- If workspace is a standard repo: no output, function returns 0
- If workspace is a worktree with accessible metadata: informational log, returns 0
- If workspace is a worktree with inaccessible metadata: warning to stderr, returns 0
- Container startup ALWAYS continues regardless of validation result

### Error Handling

| Condition | Behavior |
|-----------|----------|
| .git file exists but is empty | Log warning, continue |
| .git file exists but has no `gitdir:` prefix | Log warning about corrupt .git file, continue |
| gitdir path is relative (not absolute) | Resolve relative to workspace, then validate |
| Permission denied reading .git file | Log warning, continue |
| WORKSPACE_DIR not set and /workspace doesn't exist | Skip validation silently (validate_workspace handles this) |

## Integration Point

The function is called from `main()` in `docker/entrypoint.sh`:

```bash
main() {
    # ... existing setup ...
    validate_workspace          # Existing: validates /workspace mount
    validate_worktree           # NEW: validates worktree metadata access
    fix_home_permissions        # Existing: fixes named volume perms
    # ... rest of startup ...
}
```

## Success Criteria

| Criterion | Check | Expected |
|-----------|-------|----------|
| Function exists | `type validate_worktree` | function defined |
| Non-blocking on success | Standard repo exits 0 | Container starts |
| Non-blocking on failure | Broken worktree exits 0 | Container starts |
| Warning on stderr | Redirect stderr | Contains "worktree" and "inaccessible" |
| No output for standard repo | Redirect stderr | No worktree-related output |
| Completes in <100ms | time validate_worktree | real < 0.1s |
