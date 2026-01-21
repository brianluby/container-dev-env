# 007-prd-git-worktree-compat

## Problem Statement

Git worktrees allow developers to check out multiple branches simultaneously in
separate directories, enabling parallel work on features, hotfixes, and reviews
without stashing or switching contexts. However, many terminal AI agents and
development tools assume a traditional single-checkout repository structure where
`.git` is a directory at the repository root. In worktree checkouts, `.git` is a
file pointing to the main repository's worktree metadata, which breaks tools that:

- Look for `.git/` directory directly
- Assume the repository root contains the full git database
- Cannot resolve the actual git directory path
- Fail to detect repository boundaries correctly

Without worktree compatibility, developers using modern git workflows face broken
auto-commit features, incorrect file context, and failed repository detection in
their AI-assisted development tools.

## Requirements

### Must Have (M)

- [ ] Detect worktree environment (`.git` file vs `.git` directory)
- [ ] Resolve correct git directory path using `git rev-parse --git-dir`
- [ ] Auto-commit works correctly in worktree checkouts
- [ ] Repository context detection works (root, branch, status)
- [ ] File operations respect worktree boundaries
- [ ] Selected AI agent (from 005-prd-terminal-ai-agent) functions in worktrees

### Should Have (S)

- [ ] Correctly identify which worktree the user is in
- [ ] Support operations across linked worktrees (view other branches)
- [ ] Handle worktree-specific refs (worktrees have independent HEAD)
- [ ] Graceful degradation when main repository is inaccessible
- [ ] Clear error messages explaining worktree-related issues

### Could Have (C)

- [ ] Worktree management commands (list, add, remove)
- [ ] Cross-worktree file comparison
- [ ] Awareness of other active worktrees during operations
- [ ] Worktree status in prompt/context display
- [ ] Support for `git worktree lock/unlock` status

### Won't Have (W)

- [ ] Creating worktrees automatically
- [ ] Worktree-specific configuration management
- [ ] Bare repository support (different use case)
- [ ] Submodule worktree interactions (complex edge case)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Auto-commit in worktree | Must | Core workflow must not break |
| Correct repo detection | Must | Agent must find repository root |
| Branch awareness | Must | Know current worktree's branch |
| Git operations work | High | status, diff, log, commit |
| No false repo boundaries | High | Don't stop at worktree root incorrectly |
| Error clarity | Medium | User understands what went wrong |
| Performance | Medium | No significant slowdown for detection |
| Edge case handling | Medium | Linked worktrees, pruned worktrees |

## Tool Candidates

Evaluation of tools from 005-prd-terminal-ai-agent for worktree compatibility:

| Tool | License | Worktree Support | Git Detection Method | Notes |
|------|---------|------------------|---------------------|-------|
| Aider | Apache 2.0 | Needs testing | Uses GitPython | May handle worktrees via GitPython |
| Claude Code | Proprietary | Needs testing | Built-in git commands | Likely uses git CLI directly |
| Codex CLI | MIT | Needs testing | Unknown | Requires investigation |
| Mentat | MIT | Needs testing | Unknown | Requires investigation |

## Selected Approach

[Filled after spike - will document which tools work out-of-box and which need workarounds]

## Acceptance Criteria

- [ ] Given a worktree checkout, when I run the AI agent, then it correctly identifies the repository
- [ ] Given a worktree with `.git` file, when I ask for git status, then correct status is shown
- [ ] Given a worktree, when I approve code changes, then auto-commit creates commit in correct branch
- [ ] Given a worktree, when I ask "what branch am I on", then the worktree's branch is reported (not main repo's)
- [ ] Given a linked worktree, when I request file context, then only worktree files are included (not main repo files)
- [ ] Given a worktree, when I run `git log`, then history is shown for the worktree's branch
- [ ] Given a worktree whose main repository moved, when I run the agent, then I get a clear error message
- [ ] Given a worktree, when I create a new file and commit, then the file appears in the correct branch
- [ ] Given a bare repository with worktrees, when I'm in a worktree, then the agent works correctly
- [ ] Given nested git repositories (submodules), when I'm in a worktree, then boundaries are respected

## Test Scenarios

### Basic Worktree Detection

```bash
# Setup: Create worktree
cd /path/to/main-repo
git worktree add ../feature-branch feature-branch

# Test: Agent detection
cd ../feature-branch
# Agent should detect this as a valid git repository
# Agent should report branch as 'feature-branch', not main repo's branch
```

### Auto-Commit in Worktree

```bash
# Setup: In worktree
cd /path/to/feature-branch

# Test: Make changes via agent
# Agent creates changes to file.py
# User approves changes
# Agent should create commit on 'feature-branch'
# Commit should appear in git log for feature-branch
```

### Repository Boundary

```bash
# Setup: Nested structure
/projects/
├── main-repo/          # Main git repository
│   └── .git/           # Full git directory
└── worktrees/
    └── feature/        # Worktree checkout
        └── .git        # File pointing to main-repo

# Test: Agent in worktree should:
# - Use /projects/main-repo/.git for git operations
# - Consider /projects/worktrees/feature as working directory
# - Not treat /projects/ as repository root
```

## Dependencies

- Requires: 005-prd-terminal-ai-agent (tool selection determines compatibility testing)
- Requires: 001-prd-container-base (git installed in container)
- Blocks: none (compatibility feature)

## Spike Tasks

- [ ] Create test repository with multiple worktrees
- [ ] Test Aider in worktree environment - document behavior
- [ ] Test Claude Code in worktree environment - document behavior
- [ ] Test Codex CLI in worktree environment - document behavior
- [ ] Test Mentat in worktree environment - document behavior
- [ ] Identify git detection code in each tool's source
- [ ] Document workarounds for tools with broken detection
- [ ] Test auto-commit creates commits on correct branch
- [ ] Test with bare repository + worktrees pattern
- [ ] Test edge case: worktree with detached HEAD
- [ ] Test edge case: worktree pointing to pruned branch
- [ ] Test edge case: worktree in different filesystem (tmpfs, named volume)
- [ ] Create compatibility matrix (tool x scenario)
- [ ] Document any required configuration or patches
