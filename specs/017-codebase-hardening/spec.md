# Feature Specification: Codebase Hardening

**Feature Branch**: `017-codebase-hardening`
**Created**: 2026-01-23
**Status**: Draft
**Input**: User description: "Consolidated improvement backlog covering security hardening, CI/CD fixes, and architecture improvements identified across 5 independent code reviews"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Agent Command Execution (Priority: P1)

As a developer using the agent wrapper, I need commands to be executed safely so that malicious or malformed task descriptions cannot inject arbitrary shell commands into my container environment.

**Why this priority**: This is the highest-risk vulnerability (100% reviewer consensus). An attacker can achieve container-root code execution through crafted task descriptions containing shell metacharacters.

**Independent Test**: Can be fully tested by submitting task descriptions with hostile shell metacharacters (`;`, `$()`, backticks) and verifying no unintended commands execute.

**Acceptance Scenarios**:

1. **Given** the agent receives a task description containing `; rm -rf /`, **When** the agent processes the task, **Then** only the intended command runs and the injected command is treated as literal text
2. **Given** the agent receives a task with embedded subshell syntax `$(whoami)`, **When** the task is executed, **Then** the subshell is not evaluated and the text is passed literally to the AI provider
3. **Given** the agent receives a task with backticks `` `id` ``, **When** the task is processed, **Then** the backtick content is not executed as a command

---

### User Story 2 - Safe JSON Logging and Session Management (Priority: P1)

As a developer reviewing agent session logs, I need log entries to always produce valid JSON regardless of the content being logged, so that downstream tools and parsers can reliably process session data.

**Why this priority**: JSON injection corrupts log integrity and can crash downstream parsers. Flagged by 4 of 5 reviewers.

**Independent Test**: Can be tested by generating log entries with special characters (`"`, `\`, newlines) in user-controlled fields and validating the output with a JSON parser.

**Acceptance Scenarios**:

1. **Given** a task description containing double quotes and backslashes, **When** a log entry is created, **Then** the resulting JSON is valid and parseable
2. **Given** a session target field containing newline characters, **When** session data is written, **Then** the JSON structure remains intact with newlines properly escaped

---

### User Story 3 - Verified Software Downloads (Priority: P2)

As a developer building the container image, I need all external software downloads to be cryptographically verified so that a compromised upstream source cannot inject malicious code into my development environment.

**Why this priority**: Supply-chain attacks are a growing threat vector. Unverified downloads from multiple sources (NodeSource, Chezmoi, OpenCode, VSIX extensions) create significant risk surface.

**Independent Test**: Can be tested by building the container image and verifying that all download steps include checksum or GPG verification, and that builds fail if checksums don't match.

**Acceptance Scenarios**:

1. **Given** the container build downloads packages via APT (e.g., NodeSource), **When** the packages are installed, **Then** APT's built-in GPG signature verification ensures package integrity; for direct binary downloads (Chezmoi, age, OpenCode), SHA256 checksums from the in-repo manifest are verified
2. **Given** a downloaded binary has a mismatched checksum, **When** verification runs, **Then** the build fails immediately with a clear error message
3. **Given** VSIX extensions are downloaded for IDE setup, **When** the download completes, **Then** each extension's checksum is verified against an in-repo manifest

---

### User Story 4 - Safe Secrets Loading (Priority: P2)

As a developer with secrets configured in my environment, I need the secrets loader to safely parse secret values without executing any embedded shell syntax, so that a tampered secrets file cannot achieve code execution at shell startup.

**Why this priority**: The current `source`-based approach executes arbitrary shell in secrets files, allowing code execution if the file is tampered.

**Independent Test**: Can be tested by creating a secrets file containing command substitutions and backticks, then verifying none execute during loading.

**Acceptance Scenarios**:

1. **Given** a secrets file contains a value with `$(malicious-command)`, **When** secrets are loaded, **Then** the line is rejected with a `[WARN]` message and the variable is NOT exported
2. **Given** a secrets file has world-readable permissions (0644), **When** the loader attempts to read it, **Then** loading fails with a permission error before parsing any content
3. **Given** a secrets file contains a line with an invalid key format (e.g., starting with a digit), **When** secrets are loaded, **Then** that line is skipped and a warning is issued

---

### User Story 5 - Localhost-Only Agent Port Binding (Priority: P2)

As a developer running the agent in server mode, I need the agent port to be bound to localhost only so that other machines on my network cannot access the agent service.

**Why this priority**: Exposing the agent on all interfaces creates an unauthenticated network service accessible to the local network.

**Independent Test**: Can be tested by starting the agent in server mode and verifying the port is only listening on 127.0.0.1, not 0.0.0.0.

**Acceptance Scenarios**:

1. **Given** the agent server starts with default configuration, **When** I check the listening interfaces, **Then** the port is bound only to 127.0.0.1
2. **Given** the agent server mode is enabled without a password configured, **When** the server attempts to start, **Then** it fails with a clear error requiring authentication configuration

---

### User Story 6 - Reliable CI Pipeline Triggers (Priority: P2)

As a developer submitting pull requests, I need CI workflows to trigger for all relevant file changes so that code changes in primary source directories are always validated before merge.

**Why this priority**: Current path filters miss changes under `docker/**`, `src/**`, `templates/**`, meaning PRs can bypass CI validation.

**Independent Test**: Can be tested by modifying files in each source directory and verifying the appropriate CI workflow triggers.

**Acceptance Scenarios**:

1. **Given** a PR modifies files under `docker/`, **When** the PR is submitted, **Then** the container build workflow triggers
2. **Given** a PR modifies files under `src/agent/`, **When** the PR is submitted, **Then** the build workflow triggers
3. **Given** all third-party GitHub Actions in workflows, **When** I inspect their version references, **Then** each is pinned to a specific commit SHA (not a branch or tag)

---

### User Story 7 - Safe Secrets Editing (Priority: P3)

As a developer editing secrets through the provided tooling, I need secret values containing special characters to be stored and retrieved without corruption.

**Why this priority**: Value corruption during edit operations loses credentials and causes hard-to-debug failures.

**Independent Test**: Can be tested by storing and retrieving secret values containing `/`, `+`, `=`, `&`, `|`, `\` characters and verifying round-trip integrity.

**Acceptance Scenarios**:

1. **Given** I update a secret value containing `&` and `|` characters, **When** I retrieve the secret, **Then** the value matches exactly what was stored
2. **Given** I store a secret value starting with `-n`, **When** I retrieve it, **Then** the value is preserved literally without being interpreted as an echo flag

---

### User Story 8 - Consistent Shell Strict Mode (Priority: P3)

As a developer maintaining the shell scripts in this project, I need all scripts to use consistent error handling so that unset variables and pipeline failures are caught early rather than causing silent data corruption.

**Why this priority**: Inconsistent strict mode across scripts creates unpredictable failure behavior and makes debugging difficult.

**Independent Test**: Can be tested by running ShellCheck across all script directories and verifying each script uses `set -euo pipefail` or documents an intentional exception.

**Acceptance Scenarios**:

1. **Given** any committed `.sh` file or executable with a bash shebang in the repository, **When** I check its header, **Then** it contains `set -euo pipefail` or a documented reason for an alternative
2. **Given** a script references an unset variable, **When** the script runs, **Then** it fails immediately with an informative error rather than continuing with an empty value

---

### User Story 9 - Canonical Container Documentation (Priority: P3)

As a new developer joining the project, I need clear documentation about which container image to use for each use case so that I don't accidentally build from the wrong Dockerfile or misconfigure my environment.

**Why this priority**: Multiple Dockerfiles without clear ownership create confusion and architectural drift.

**Independent Test**: Can be tested by having a new developer read the documentation and correctly identify which container to use for their specific use case (base dev, devcontainer, agent, IDE, memory server).

**Acceptance Scenarios**:

1. **Given** I am setting up the development environment, **When** I read the project documentation, **Then** I can identify the canonical Dockerfile for each use case within the first page
2. **Given** the project has multiple Dockerfiles, **When** I check the architecture decision records, **Then** there is a clear ADR explaining the purpose of each image

---

### Edge Cases

- What happens when a task description contains null bytes or non-UTF-8 characters?
- How does the secrets loader handle extremely long values (>64KB)?
- What happens when multiple CI workflows trigger simultaneously for the same PR?
- How does the system behave when the secrets file is a symlink to a world-readable location?
- What happens when a secrets value contains the `=` delimiter character within the value itself?
- How does the agent behave when the configured port is already in use?

## Clarifications

### Session 2026-01-23

- Q: Should the secrets loader reject any `$` in values (strict) or only command substitution patterns? → A: Reject only command substitution patterns (`$()`, `${}`, backticks) but allow bare `$` in values
- Q: How should download checksums be stored in the repository? → A: Single manifest file at repo root (e.g., `checksums.sha256`) listing all binaries and their SHA256 hashes
- Q: What output channel and format should error/warning diagnostics use? → A: Prefixed plaintext to stderr (e.g., `[ERROR] component: message`) following Unix conventions
- Q: What is the scope of "all shell scripts" for strict mode (FR-012)? → A: Only committed `.sh` files and executables with a bash shebang; excludes Chezmoi templates and Dockerfile RUN blocks
- Q: How should the secrets parser handle values containing `=` (the delimiter)? → A: Split on first `=` only; everything after first `=` is the value (standard `.env` behavior)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The agent command execution MUST NOT use `eval` or any mechanism that interprets shell metacharacters in user-provided task descriptions
- **FR-002**: All JSON construction for logging and session management MUST properly escape user-controlled fields (quotes, backslashes, newlines, control characters)
- **FR-003**: All external binary downloads during container build MUST be verified against cryptographic checksums (SHA256 minimum) stored in a single centralized manifest file at repository root (e.g., `checksums.sha256`)
- **FR-004**: The secrets loader MUST parse secret files using safe line-by-line reading without executing any embedded shell syntax
- **FR-005**: The secrets loader MUST reject files with insecure permissions (group-writable or world-readable)
- **FR-006**: Secret key names MUST match the pattern `^[A-Z_][A-Z0-9_]*$`; non-matching lines MUST be skipped with a warning
- **FR-007**: The agent server port MUST bind only to the loopback interface (127.0.0.1) by default
- **FR-008**: Server mode MUST require authentication credentials to be configured before accepting connections
- **FR-009**: All third-party GitHub Actions MUST be pinned to specific commit SHAs
- **FR-010**: CI workflow path filters MUST include all primary source directories (`docker/**`, `src/**`, `templates/**`, `scripts/**`, `Dockerfile`, `pyproject.toml`, `uv.lock`, `Makefile`)
- **FR-011**: The secrets editor MUST preserve values containing special characters (`/`, `+`, `=`, `&`, `|`, `\`) through store/retrieve cycles without corruption
- **FR-012**: All committed `.sh` files and executables with a bash shebang MUST use `set -euo pipefail` or include a header comment documenting why an exception is made (excludes Chezmoi Go templates and Dockerfile `RUN` blocks)
- **FR-013**: The project MUST include an Architecture Decision Record documenting the canonical container image for each use case
- **FR-014**: Lines in secrets files containing command substitution patterns (`$()`, `${}`, or backticks) in values MUST be rejected with a clear warning; bare `$` characters in values are permitted
- **FR-015**: Dependabot (or equivalent) MUST be configured to monitor GitHub Actions and base image updates
- **FR-016**: All error and warning diagnostics MUST be written to stderr using the prefix format `[ERROR] component: message` or `[WARN] component: message`
- **FR-017**: The secrets parser MUST split lines on the first `=` character only; all subsequent `=` characters are part of the value (standard `.env` behavior)

### Key Entities

- **Agent Task**: A user-provided description of work for the AI agent to perform; contains arbitrary text that must be treated as untrusted input
- **Secret Entry**: A key-value pair (KEY=VALUE format) representing a credential or sensitive configuration value
- **Session Log**: A JSON-structured record of agent activity including timestamps, targets, and task details
- **Container Image**: A Docker image built from one of several Dockerfiles, each serving a specific use case in the development environment
- **CI Workflow**: A GitHub Actions configuration defining automated checks triggered by repository events

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero command injection vulnerabilities exist in the agent execution path, verified by hostile-input test suite passing 100% of cases
- **SC-002**: All generated JSON files pass validation for inputs containing any combination of special characters
- **SC-003**: Container builds fail immediately when any downloaded binary's checksum does not match the in-repo manifest
- **SC-004**: Secrets files containing embedded commands produce zero unintended command executions during loading
- **SC-005**: Agent server port scanning from non-localhost addresses returns zero open ports on the agent service port
- **SC-006**: PRs modifying any file in primary source directories trigger the appropriate CI workflow 100% of the time
- **SC-007**: Secret values containing all tested special characters survive store/retrieve cycles with zero data loss
- **SC-008**: All shell scripts pass static analysis with zero errors
- **SC-009**: A new developer can identify the correct container image for their use case from documentation within 2 minutes

## Assumptions

- The project uses Bash 5.x as the primary scripting language for all shell scripts
- `jq` is available in the container image for safe JSON construction
- The existing BATS test framework is used for shell script unit testing
- Dependabot is available for the GitHub repository (GitHub-hosted, not self-hosted)
- The agent's AI provider (OpenCode) accepts task descriptions as plain text arguments
- Docker Compose V2 is the target compose version (no `version:` field needed)
- The `dev` username is the intended canonical user across all container images
- ShellCheck is already available in CI (referenced in existing workflows)

## Scope Boundaries

### In Scope

- Fixing all P0 (Critical) security vulnerabilities: SEC-001, SEC-002
- Fixing all P1 (High) security and CI issues: SEC-003 through SEC-006, CI-001, CI-002
- Addressing P2 architecture items: ARCH-001, ARCH-002
- Adding tests for all security fixes

### Out of Scope

- ARCH-003 (Passwordless sudo restriction) — requires deeper architectural discussion about entrypoint design
- ARCH-004 (User identity naming drift) — requires coordination across all images and may break existing setups
- PERF-001 (Session lookup optimization) — performance improvement, not a security fix
- SEC-007 (Base image digest pinning) — beneficial but requires ongoing maintenance tooling
- MAINT-001 (Docker Compose version field) — trivial fix that can be addressed independently
- MAINT-002 (Memory system ingestion guards) — separate feature scope
- DOC-001, DOC-002 — documentation-only fixes that can be addressed independently

## Dependencies

- Existing BATS test infrastructure must be functional
- `jq` must be available or added to the container base image
- Access to GitHub repository settings for Dependabot configuration
- Knowledge of current checksum values for all downloaded binaries
