# Data Model: Git Worktree Compatibility

**Feature**: 007-git-worktree-compat
**Date**: 2026-01-22

## Entities

### WorkspaceState

Represents the detected state of the workspace directory at container startup.

| Field | Type | Description |
|-------|------|-------------|
| workspace_path | string | Resolved path from `$WORKSPACE_DIR` (default: `/workspace`) |
| git_type | enum | `none`, `standard`, `worktree` |
| git_dir_path | string | null | Resolved git directory path (from `.git` file or `.git/` directory) |
| metadata_accessible | boolean | Whether the git metadata directory exists and is readable |
| branch | string | null | Current branch name (null if not a git repo or detached HEAD) |
| is_detached | boolean | Whether HEAD is detached |

### GitWorktreeInfo

Represents parsed information from a worktree's `.git` file.

| Field | Type | Description |
|-------|------|-------------|
| gitdir_pointer | string | Raw content of the `gitdir:` line in `.git` file |
| resolved_path | string | Absolute path after resolving the pointer |
| main_repo_root | string | null | Inferred main repository root (parent of `.git/worktrees/`) |
| worktree_name | string | Name of this worktree (from path: `.git/worktrees/<name>`) |

## State Transitions

```
Container Start
     │
     ▼
┌─────────────┐
│ Check $WORKSPACE_DIR │
└─────────────┘
     │
     ▼
┌─────────────┐    no .git found     ┌──────────┐
│ Check .git  │──────────────────────►│ git_type │
│ existence   │                       │ = none   │
└─────────────┘                       └──────────┘
     │
     │ .git exists
     ▼
┌─────────────┐    .git is directory  ┌──────────────┐
│ Check .git  │──────────────────────►│ git_type     │
│ type        │                       │ = standard   │
└─────────────┘                       └──────────────┘
     │
     │ .git is file
     ▼
┌─────────────┐
│ Parse gitdir│
│ pointer     │
└─────────────┘
     │
     ▼
┌─────────────┐    path accessible    ┌──────────────────────┐
│ Validate    │──────────────────────►│ git_type = worktree  │
│ resolved    │                       │ metadata_accessible  │
│ path        │                       │ = true               │
└─────────────┘                       └──────────────────────┘
     │
     │ path not accessible
     ▼
┌──────────────────────┐
│ git_type = worktree  │
│ metadata_accessible  │
│ = false              │
│ → print stderr warn  │
└──────────────────────┘
```

## Validation Rules

| Rule | Entity | Condition | Action |
|------|--------|-----------|--------|
| VR-001 | WorkspaceState | `git_type == worktree && !metadata_accessible` | Print stderr warning with fix instructions |
| VR-002 | WorkspaceState | `git_type == none` | Skip worktree validation (no warning needed) |
| VR-003 | WorkspaceState | `git_type == standard` | Skip worktree validation (no warning needed) |
| VR-004 | GitWorktreeInfo | `gitdir_pointer` does not start with `gitdir:` | Treat as corrupt; warn and continue |
| VR-005 | WorkspaceState | All states | Continue container startup (non-blocking) |

## Relationships

```
WORKSPACE_DIR env var
       │
       │ resolves to
       ▼
  WorkspaceState
       │
       │ if git_type == worktree
       ▼
  GitWorktreeInfo
       │
       │ resolved_path points to
       ▼
  Main Repository (.git/worktrees/<name>/)
```

## Environment Variables

| Variable | Default | Description | Set By |
|----------|---------|-------------|--------|
| WORKSPACE_DIR | `/workspace` | Path to check for worktree | User / docker-compose |
| (internal) git_type | — | Detected git type | validate_worktree() |
| (internal) gitdir_path | — | Resolved git directory | validate_worktree() |
