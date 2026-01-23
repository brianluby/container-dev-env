# Feature Specification: Git Worktree Compatibility

**Feature Branch**: `007-git-worktree-compat`
**Created**: 2026-01-22
**Status**: Draft
**Input**: User description: "prds/007-prd-git-worktree-compat.md"

## Clarifications

### Session 2026-01-22

- Q: How should the worktree validation warning be delivered to the developer? → A: Print to stderr during container entrypoint startup.
- Q: Should the container block startup or continue when worktree metadata is inaccessible? → A: Continue with stderr warning (non-blocking).
- Q: When worktree `.git` file points to a non-existent path (parent moved/deleted), treat identically to inaccessible metadata? → A: Yes, treat identically.
- Q: Should the worktree validation check run on every container start or only first initialization? → A: Every container start.
- Q: What path should the entrypoint script check for worktree detection? → A: Environment variable `WORKSPACE_DIR` with default `/workspace`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Container Worktree Mount Validation (Priority: P1)

A developer mounts a git worktree directory into the container for AI-assisted development. The container startup process detects whether the mounted directory is a worktree and validates that the parent git repository metadata is accessible. If the git directory is inaccessible, the developer receives a clear warning explaining the issue and how to fix it.

**Why this priority**: Without mount validation, developers silently lose git functionality (commits, status, branch detection) when mounting only the worktree directory. This is the most impactful failure mode since it breaks the core development workflow.

**Independent Test**: Can be tested by mounting a worktree directory into the container and verifying the validation message appears when the parent repository is not accessible.

**Acceptance Scenarios**:

1. **Given** a worktree directory mounted into the container with the parent repository also accessible, **When** the container starts, **Then** git operations (status, commit, log) work correctly.
2. **Given** only a worktree directory mounted into the container (parent git directory inaccessible), **When** the container starts, **Then** a clear warning message is displayed explaining that the git metadata is not accessible and recommending to mount the repository root instead.
3. **Given** a standard git repository (not a worktree) mounted into the container, **When** the container starts, **Then** no worktree-related warnings are shown and git operations work normally.

---

### User Story 2 - AI Agent Worktree Operations (Priority: P2)

A developer working in a git worktree uses AI development tools (such as commit assistants, code review agents, or context-aware coding tools) within the container. These tools correctly detect the repository, identify the current branch, and perform git operations (commits, diffs, status checks) without any special configuration.

**Why this priority**: AI agents are the primary interaction model in this container. If they cannot detect the repository or commit to the correct branch in a worktree, the development workflow is broken.

**Independent Test**: Can be tested by running AI-assisted git operations (auto-commit, branch detection) in a properly mounted worktree environment.

**Acceptance Scenarios**:

1. **Given** a developer in a worktree checkout, **When** they use the AI agent to check git status, **Then** the correct status for the worktree's branch is shown.
2. **Given** a developer in a worktree, **When** the AI agent creates a commit, **Then** the commit is made on the worktree's branch (not the main repository's checked-out branch).
3. **Given** a developer in a worktree with a detached HEAD, **When** the AI agent queries the branch, **Then** the detached state is correctly reported.

---

### User Story 3 - Cross-Worktree Awareness (Priority: P3)

A developer working in one worktree wants visibility into other active worktrees associated with the same repository. They can see which other branches have active worktrees, helping them understand the full picture of parallel work in progress.

**Why this priority**: This enhances developer awareness but is not essential for core functionality. Developers can work effectively without this information.

**Independent Test**: Can be tested by listing active worktrees from within any worktree and verifying the list matches actual worktree state.

**Acceptance Scenarios**:

1. **Given** a repository with multiple active worktrees, **When** the developer requests a list of worktrees, **Then** all active worktrees are displayed with their branch names and paths.
2. **Given** a repository with a locked worktree, **When** the developer views worktree status, **Then** the locked status is indicated.

---

### Edge Cases

- When the parent repository's `.git` directory is deleted or moved after the worktree was created, the system treats this identically to inaccessible metadata: prints a stderr warning and continues startup (non-blocking).
- How does the system handle a worktree that points to a pruned (deleted) branch?
- What happens when a worktree is on a detached HEAD state?
- How does the system behave when the worktree directory is on a different filesystem (e.g., tmpfs, named volume) than the parent repository?
- What happens when multiple worktrees point to the same branch (git prevents this, but what if metadata is stale)?
- How does the system handle nested git repositories (submodules) within a worktree?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect whether the directory at `$WORKSPACE_DIR` (default: `/workspace`) is a git worktree (`.git` file) or a standard repository (`.git` directory) on every container startup (not cached between restarts).
- **FR-002**: System MUST validate that the git metadata directory referenced by a worktree's `.git` file is accessible within the container.
- **FR-003**: System MUST print a clear, actionable warning to stderr when a worktree is detected but its git metadata is inaccessible, including the expected path and recommended mount configuration.
- **FR-004**: System MUST allow AI development tools to perform git operations (status, commit, diff, log) correctly in a properly mounted worktree environment.
- **FR-005**: System MUST correctly report the worktree's current branch (not the main repository's HEAD) when queried.
- **FR-006**: System MUST ensure commits made in a worktree are recorded on the worktree's branch.
- **FR-007**: System MUST handle the detached HEAD state in worktrees without errors, reporting the state accurately.
- **FR-008**: System MUST support listing all active worktrees associated with the repository.
- **FR-009**: System MUST NOT produce false repository boundary detection (e.g., treating the worktree root as a separate repository).
- **FR-010**: System MUST gracefully degrade when the main repository is inaccessible: print a warning to stderr and continue container startup (non-blocking) rather than exiting with an error.

### Key Entities

- **Worktree**: A separate working directory linked to a shared git repository, identified by a `.git` file (rather than directory) containing a path reference to the main repository's worktree metadata.
- **Main Repository**: The original git repository containing the full `.git` directory and worktree metadata under `.git/worktrees/`.
- **Git Metadata Path**: The path stored in the worktree's `.git` file, pointing to the specific worktree's metadata within the main repository's `.git/worktrees/<name>` structure.
- **Mount Configuration**: The volume mount settings that determine which host directories are accessible inside the container.
- **WORKSPACE_DIR**: Environment variable specifying the workspace path for worktree detection (default: `/workspace`). Allows override for non-standard mount configurations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of git operations (status, commit, diff, log, branch) succeed in a properly mounted worktree environment without additional user configuration.
- **SC-002**: Container startup validation detects and reports inaccessible git metadata within 2 seconds of container start.
- **SC-003**: Warning messages for misconfigured worktree mounts include the specific mount command needed to fix the issue, reducing developer troubleshooting to under 1 minute.
- **SC-004**: Developers can switch between worktree and standard repository workflows without changing container configuration (zero configuration overhead for supported mount patterns).
- **SC-005**: AI development tools correctly identify the current branch in 100% of worktree scenarios (including detached HEAD).

## Assumptions

- Developers are familiar with git worktree concepts and may already use them in their workflow.
- The container image has git installed (dependency on 001-container-base-image).
- AI development tools (Claude Code, Aider) natively support git worktrees without patches (validated in spike findings).
- The primary failure mode is incorrect container volume mounting, not tool incompatibility.
- Submodule interactions with worktrees are out of scope for this feature.
- Bare repository support is out of scope for this feature.
- The container entrypoint script is the appropriate place for mount validation logic.

## Dependencies

- Requires: 001-container-base-image (git installed in container)
- Requires: 005-terminal-ai-agent (tool selection determines which AI agents need worktree compatibility)

## Out of Scope

- Automatic worktree creation by the container or tools.
- Worktree-specific configuration management (each worktree uses the same container configuration).
- Bare repository support (different workflow pattern).
- Submodule interactions within worktrees (complex edge case deferred).
- Worktree management commands (add, remove, prune) - these are standard git operations available to the user directly.
