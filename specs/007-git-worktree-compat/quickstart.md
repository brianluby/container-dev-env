# Quickstart: Git Worktree Compatibility

**Feature**: 007-git-worktree-compat
**Date**: 2026-01-22

## What This Does

The container entrypoint automatically detects git worktrees and validates that the required git metadata is accessible. If you mount a worktree without its parent repository's `.git` directory, you'll get a clear warning with instructions to fix it.

## Usage

### Standard Repository (no changes needed)

```bash
# Works exactly as before — no worktree warnings
docker run -v ./my-project:/workspace devcontainer
```

### Git Worktree (recommended: mount the main repo)

```bash
# Best approach: mount the main repository root
docker run -v /path/to/main-repo:/workspace devcontainer

# Then create/use worktrees inside the container
cd /workspace
git worktree add ../feature-branch feature-branch
```

### Git Worktree (mount worktree + parent .git)

```bash
# If you must mount the worktree directly, also mount the parent .git:
docker run \
  -v /path/to/worktree:/workspace \
  -v /path/to/main-repo/.git:/path/to/main-repo/.git:ro \
  devcontainer
```

### Custom Workspace Path

```bash
# Override the default /workspace path:
docker run \
  -e WORKSPACE_DIR=/code \
  -v ./my-project:/code \
  devcontainer
```

## What Happens at Startup

1. Container starts, entrypoint runs
2. Validates `/workspace` (or `$WORKSPACE_DIR`) exists and is writable
3. Checks if `.git` is a file (worktree) or directory (standard repo)
4. If worktree: validates the referenced git metadata directory is accessible
5. If inaccessible: prints a warning to stderr with fix instructions
6. Container continues startup regardless (non-blocking)

## Warning Example

If you mount a worktree without its parent repository:

```
[entrypoint] WARNING: Git worktree detected but metadata is inaccessible
[entrypoint]   Workspace: /workspace
[entrypoint]   Expected git dir: /home/user/repos/main-project/.git/worktrees/feature-x
[entrypoint]   This path is not accessible inside the container.
[entrypoint]   Fix: Mount the main repository root instead:
[entrypoint]     docker run -v /home/user/repos/main-project:/workspace ...
```

## AI Agent Compatibility

Both Claude Code and Aider work natively in worktrees — no configuration needed:

```bash
# Inside a properly mounted worktree container:
aider           # Correctly detects branch, commits to correct branch
claude          # Full git context awareness in worktree
```

## Verifying Worktree Status

```bash
# Check if you're in a worktree:
cat .git
# Output: gitdir: /path/to/main-repo/.git/worktrees/feature-name

# List all worktrees:
git worktree list

# Check current branch:
git rev-parse --abbrev-ref HEAD
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Warning about inaccessible metadata | Parent .git not mounted | Mount main repo root or add .git volume |
| `git status` fails | Same as above | Same as above |
| Wrong branch reported | Not in worktree directory | Check `$WORKSPACE_DIR` points to worktree |
| No warning but git fails | .git directory exists but is corrupt | Check .git directory contents |
