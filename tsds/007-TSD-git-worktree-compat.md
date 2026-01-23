# Technical Specification Document: 007-git-worktree-compat

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/007-git-worktree-compat/` and `prds/007-prd-git-worktree-compat.md`

## 1. Executive Summary

This document specifies the validation and compatibility layer for Git Worktrees. Since most modern AI tools (Claude Code, Aider) support worktrees natively via `git` CLI or `GitPython`, the technical focus is on **validation**—ensuring the environment correctly reports worktree state to these tools to prevent context hallucination.

## 2. Technical Specifications

### 2.1 Detection Logic
A script `scripts/git-context-check.sh` will be deployed to verify the environment.
*   **Logic**:
    1. Check if `.git` is a file (worktree) or directory (standard).
    2. Run `git rev-parse --is-inside-work-tree`.
    3. Run `git rev-parse --git-dir` to resolve the absolute path to metadata.

### 2.2 Tool Compatibility Layer
*   **Aider**: Uses `GitPython`. Ensure `GitPython>=3.1.0` is installed (supports worktrees).
*   **OpenCode**: Uses `go-git`. Verify version compatibility.

## 3. Data Models

### 3.1 Worktree Metadata
The system relies on standard Git metadata.
*   **File**: `.git` (text file)
*   **Content**: `gitdir: /path/to/main/.git/worktrees/my-feature`

## 4. API Contracts & Interfaces

### 4.1 Validation Script Output
`check-worktree-compat` command:
```json
{
  "is_worktree": true,
  "git_dir": "/workspace/.git/worktrees/feature-a",
  "common_dir": "/workspace/.git",
  "branch": "feature-a",
  "status": "clean"
}
```

## 5. Architectural Improvements

### 5.1 Pre-Flight Check Hook
**Problem**: If a user mounts a specific worktree folder as `/workspace` in Docker, the link to the main `.git` directory might be broken if the relative path `../.git` is not accessible inside the container.
**Solution**:
*   **Volume Strategy Update**: PRD 004 must support mounting the *repository root* and changing `WORKDIR`, OR ensure the bind mount includes the parent directory containing `.git`.
*   **Validation**: The `entrypoint.sh` should check `git rev-parse --git-dir` and warn if the git metadata is unreachable due to mount isolation.

## 6. Testing Strategy
*   **Edge Case**: Mount a worktree directory *without* mounting the parent bare repo. Verify tools report "Not a git repository" correctly rather than crashing.
*   **Success Case**: Mount parent directory, navigate to worktree. Verify `aider` commits go to the worktree branch.
