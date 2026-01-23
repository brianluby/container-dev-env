# Test Contract: Git Worktree Compatibility

**Feature**: 007-git-worktree-compat
**Date**: 2026-01-22

## Overview

This contract defines the acceptance tests for the git worktree validation feature.

## Test Categories

### 1. Unit Tests (BATS)

Tests for `validate_worktree()` function logic, run outside Docker.

| Test ID | Description | Setup | Expected |
|---------|-------------|-------|----------|
| WT-U001 | No .git in workspace | Empty temp dir | No output, exit 0 |
| WT-U002 | Standard .git directory | `mkdir .git` | No worktree warning, exit 0 |
| WT-U003 | Worktree with accessible metadata | `.git` file + valid gitdir path | Informational log, exit 0 |
| WT-U004 | Worktree with inaccessible metadata | `.git` file + non-existent gitdir path | Warning on stderr, exit 0 |
| WT-U005 | Empty .git file | `touch .git` (empty) | Warning about corrupt file, exit 0 |
| WT-U006 | .git file without gitdir prefix | `.git` with random content | Warning about corrupt file, exit 0 |
| WT-U007 | Relative gitdir path | `.git` with `gitdir: ../main/.git/worktrees/x` | Resolves correctly |
| WT-U008 | WORKSPACE_DIR override | Set env var to custom path | Uses custom path |
| WT-U009 | Permission denied on .git file | `.git` with mode 000 | Warning, exit 0 |
| WT-U010 | Detached HEAD in worktree | Valid worktree + detached HEAD | No warning (metadata accessible) |

### 2. Integration Tests (Docker)

Tests for full container startup behavior with worktree mounts.

| Test ID | Description | Docker Setup | Expected |
|---------|-------------|--------------|----------|
| WT-I001 | Standard repo mount | `-v repo_with_.git_dir:/workspace` | No worktree warning in stderr |
| WT-I002 | Worktree with parent accessible | `-v worktree:/workspace -v parent_git:/path/to/parent/.git` | No warning, git status works |
| WT-I003 | Worktree without parent | `-v worktree_only:/workspace` | Warning on stderr, container starts |
| WT-I004 | Non-git directory | `-v plain_dir:/workspace` | No git-related warnings |
| WT-I005 | Git operations in worktree | Mount worktree + parent | `git status`, `git log`, `git branch` all succeed |
| WT-I006 | Commit on correct branch | Mount worktree on feature-x | `git rev-parse --abbrev-ref HEAD` returns `feature-x` |
| WT-I007 | Detached HEAD worktree | Mount worktree with detached HEAD | `git rev-parse --abbrev-ref HEAD` returns `HEAD` |
| WT-I008 | Custom WORKSPACE_DIR | `-e WORKSPACE_DIR=/custom -v repo:/custom` | Detection works at /custom |
| WT-I009 | Worktree list accessible | Mount worktree + parent | `git worktree list` shows all worktrees |
| WT-I010 | Warning includes fix command | Mount broken worktree | Stderr contains mount command suggestion |

### 3. Regression Tests

Ensure existing entrypoint behavior is unchanged.

| Test ID | Description | Expected |
|---------|-------------|----------|
| WT-R001 | Workspace validation still works | Exit 1 if /workspace missing |
| WT-R002 | Permission fix still runs | Named volumes get correct ownership |
| WT-R003 | Signal handling preserved | SIGTERM propagated to child |
| WT-R004 | Volume status logging preserved | Status section in stderr |
| WT-R005 | Default shell exec preserved | `/bin/bash -l` when no args |

## Test Runner

```bash
#!/bin/bash
# scripts/test-worktree.sh
set -e

echo "=== Unit Tests (BATS) ==="
bats tests/unit/test_worktree_validation.bats

echo "=== Integration Tests ==="
bash tests/integration/test_worktree_container.sh

echo "=== All worktree tests passed ==="
```

## Test Fixtures

### Setup Script for Test Repositories

```bash
# tests/fixtures/create-worktree-fixtures.sh
# Creates:
# - fixtures/standard-repo/     (normal .git/ directory)
# - fixtures/main-repo/         (main repo with worktrees)
# - fixtures/worktree-feature/  (worktree checkout with .git file)
# - fixtures/worktree-detached/ (worktree with detached HEAD)
# - fixtures/broken-worktree/   (worktree with invalid gitdir pointer)
```

## CI Integration

```yaml
# .github/workflows/worktree-tests.yml
test-worktree:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Install BATS
      run: npm install -g bats bats-support bats-assert
    - name: Run unit tests
      run: bats tests/unit/test_worktree_validation.bats
    - name: Build container
      run: docker build -t devcontainer .
    - name: Run integration tests
      run: bash tests/integration/test_worktree_container.sh
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Test assertion failed |
| 2 | BATS not installed |
| 3 | Docker not available for integration tests |

## Coverage Requirements

| Category | Minimum Coverage | Notes |
|----------|-----------------|-------|
| validate_worktree() branches | 100% | All git_type states tested |
| Error conditions | 100% | All VR-* validation rules tested |
| Integration scenarios | 80%+ | Core mount patterns tested |
| Regression | 100% | All existing entrypoint functions unaffected |
