# Research: Git Worktree Compatibility

**Feature**: 007-git-worktree-compat
**Date**: 2026-01-22

## R1: Git Worktree `.git` File Format

**Decision**: Parse the `.git` file to extract the `gitdir:` path, then validate accessibility with `test -d`.

**Rationale**: The `.git` file in a worktree is a plain text file with a single line: `gitdir: /absolute/path/to/.git/worktrees/<name>`. This format is stable and documented in git's internals. Parsing is trivial with `sed` or `awk`. Using `git rev-parse --git-dir` is an alternative but requires git to be functional (which it won't be if the metadata path is broken). Direct file parsing catches the failure earlier.

**Alternatives considered**:
- `git rev-parse --git-dir`: More correct but fails with an unhelpful error when the path is broken. We need to validate *before* git commands can work.
- `git worktree list`: Requires functional git metadata access; not useful for detecting broken mounts.

## R2: BATS Testing Framework for Bash

**Decision**: Use BATS (Bash Automated Testing System) for unit testing the worktree validation function.

**Rationale**: BATS is the de facto standard for testing Bash scripts. It supports TAP output, setup/teardown functions, and can be installed via `npm install -g bats` or `apt-get install bats`. It integrates well with CI (GitHub Actions has native BATS support). The test syntax is readable and follows the AAA pattern naturally.

**Alternatives considered**:
- Plain shell test scripts: Simpler but no test runner, no TAP output, no setup/teardown helpers.
- shunit2: Less maintained, less community adoption than BATS.
- bats-core + bats-assert + bats-support: Full BATS ecosystem; bats-assert provides `assert_output`, `assert_failure`, etc. Recommended for this project.

## R3: Entrypoint Script Integration Pattern

**Decision**: Add a `validate_worktree()` function to the existing `docker/entrypoint.sh`, called from `main()` after `validate_workspace` and before `fix_home_permissions`.

**Rationale**: The existing entrypoint already has a clear function-based structure with `validate_workspace`, `fix_home_permissions`, `fix_cache_permissions`, and `log_volume_status`. The worktree check is logically a workspace validation concern, so it belongs immediately after `validate_workspace` confirms the mount exists. It uses the same logging functions (`log`, `log_warning`) for consistent output.

**Alternatives considered**:
- Separate script (`check-worktree.sh`): Unnecessary complexity; one more file to maintain, one more exec in the entrypoint.
- Docker HEALTHCHECK: Wrong tool — healthchecks run periodically, not at startup; also they report via Docker API, not stderr.
- `.bashrc` integration: Only runs for interactive shells, not for `docker exec` commands.

## R4: Warning Message Format

**Decision**: Use a multi-line stderr warning that includes the detected gitdir path, whether it's accessible, and the recommended docker volume mount command.

**Rationale**: SC-003 requires the warning to include "the specific mount command needed to fix the issue." Developers need to immediately understand: (1) what was detected, (2) what's wrong, and (3) how to fix it. The message format follows the existing `log_warning` pattern for consistency.

**Example output**:
```
[entrypoint] WARNING: Git worktree detected but metadata is inaccessible
[entrypoint]   Workspace: /workspace
[entrypoint]   Expected git dir: /home/user/repos/main-project/.git/worktrees/feature-x
[entrypoint]   This path is not accessible inside the container.
[entrypoint]   Fix: Mount the main repository root instead:
[entrypoint]     docker run -v /home/user/repos/main-project:/workspace ...
[entrypoint]   Or mount both the worktree and the main .git directory:
[entrypoint]     docker run -v /path/to/worktree:/workspace -v /home/user/repos/main-project/.git:/home/user/repos/main-project/.git ...
```

**Alternatives considered**:
- Single-line warning: Insufficient detail for SC-003.
- JSON structured warning: Over-engineered for a human-readable entrypoint message.
- Writing to a file + stderr: Unnecessary complexity (clarification confirmed stderr-only).

## R5: AI Agent Worktree Compatibility (Spike Validation)

**Decision**: No agent-side changes required. Both Claude Code and Aider natively handle worktrees.

**Rationale**: Validated in spike 007 (2026-01-21). Claude Code uses `git rev-parse` directly; Aider uses GitPython with `search_parent_directories=True`. Both correctly follow `.git` file pointers to resolve the actual git directory. The entrypoint validation is purely for early warning — agents will work correctly if the mount is correct.

**Alternatives considered**:
- Custom git wrapper script: Unnecessary; agents already work.
- Agent configuration file pointing to git dir: Over-engineering; agents auto-detect correctly.
- Patching agent source code: Not needed; both are compatible out-of-the-box.

## R6: Cross-Worktree Listing (FR-008)

**Decision**: Expose `git worktree list` output via the existing shell environment. No custom tooling needed.

**Rationale**: `git worktree list` is a standard git subcommand available in git 2.5+. It outputs all worktrees with their branch and path. This satisfies FR-008 and User Story 3 without any wrapper scripts. The entrypoint can optionally log the worktree list during startup for awareness.

**Alternatives considered**:
- Custom `worktree-status` script: YAGNI — `git worktree list` already provides the information.
- Shell prompt integration: Could Have (C-4 in PRD) — deferred, not part of MVP.
