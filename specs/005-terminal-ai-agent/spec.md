# Feature Specification: Terminal AI Agent

**Feature Branch**: `005-terminal-ai-agent`
**Created**: 2026-01-22
**Status**: Draft
**Input**: User description: "Install and configure a terminal-based AI coding agent in the containerized development environment, enabling code generation, editing, and git integration without leaving the CLI."

## Clarifications

### Session 2026-01-22

- Q: If the developer manually edits a file while the agent has proposed changes to that same file, what should happen on approval? → A: Detect and warn — agent detects the file changed since it was read, alerts the developer, and asks them to re-request.
- Q: How long should the agent wait for an LLM response before timing out, and should it retry? → A: 60-second timeout, 1 retry — retry once on timeout, then fail with error message.
- Q: Should the agent commit to whatever branch is checked out, or enforce branch rules? → A: Current branch — commit to whatever branch is checked out; developer's responsibility.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate Code from Natural Language (Priority: P1)

A developer working in the container opens their terminal and asks the AI agent to write a new function. The agent reads the project context, generates syntactically correct code in the appropriate language, and writes it to the correct file. The developer reviews the proposed changes before they are applied.

**Why this priority**: This is the core value proposition — AI-assisted code generation directly in the terminal without context-switching to a browser or IDE.

**Independent Test**: Can be fully tested by starting the agent, requesting a simple function, and verifying the output is syntactically valid code written to the correct file.

**Acceptance Scenarios**:

1. **Given** a project with existing source files, **When** the developer asks "add a function to parse JSON from a file", **Then** the agent generates syntactically correct code in the project's language and proposes changes for review.
2. **Given** a Python project, **When** the developer requests a new utility function, **Then** the generated code follows the project's existing style and imports.
3. **Given** generated code changes, **When** the developer reviews and approves them, **Then** the changes are written to the appropriate file(s).
4. **Given** generated code changes, **When** the developer rejects them, **Then** no files are modified.

---

### User Story 2 - Auto-Commit Approved Changes (Priority: P2)

After the developer approves code changes, the agent automatically creates a clean git commit with a descriptive message that explains what was changed and why. The commit is atomic — all related changes across multiple files are included in a single commit.

**Why this priority**: Git integration with quality commits is the second-highest value — it eliminates the manual commit step and ensures a clean, reviewable history.

**Independent Test**: Can be tested by approving a code change and verifying a new git commit exists with a descriptive, conventional-format message.

**Acceptance Scenarios**:

1. **Given** the developer approves code changes, **When** the changes are applied, **Then** a git commit is created automatically with a descriptive message.
2. **Given** a multi-file change is approved, **When** the commit is created, **Then** all changed files are included in a single atomic commit.
3. **Given** auto-commit is enabled, **When** the developer inspects the git log, **Then** commit messages follow a conventional format and describe the intent of the change.

---

### User Story 3 - Context-Aware Code Understanding (Priority: P3)

The developer asks the agent a question about their project's structure or asks for a change that requires understanding the existing codebase. The agent reads and searches local files to build context, then responds accurately based on actual project contents.

**Why this priority**: Without codebase awareness, generated code would be generic and disconnected from the project. Context is what makes the agent useful for real work.

**Independent Test**: Can be tested by asking the agent about the project structure or requesting a change that references existing code, and verifying the response is accurate.

**Acceptance Scenarios**:

1. **Given** a multi-file project, **When** the developer asks "what does the main function do?", **Then** the agent reads the relevant file and provides an accurate answer.
2. **Given** a project with existing utilities, **When** the developer asks to "add error handling using the existing error types", **Then** the agent finds and references the actual error types in the project.
3. **Given** a project with more than 1000 files, **When** the developer asks about a specific component, **Then** the agent searches and finds the relevant files without performance degradation.

---

### User Story 4 - Multi-Language Code Generation (Priority: P4)

The developer works across projects in different languages (Python, TypeScript, Rust, Go). The agent generates valid code in whichever language the current project uses, respecting language-specific conventions and idioms.

**Why this priority**: Multi-language support ensures the agent is useful across the developer's full workflow, not limited to a single ecosystem.

**Independent Test**: Can be tested by creating small projects in each language and verifying the agent generates syntactically valid, idiomatic code for each.

**Acceptance Scenarios**:

1. **Given** a Python project, **When** the developer requests code generation, **Then** the output is valid Python following PEP 8 conventions.
2. **Given** a TypeScript project, **When** the developer requests code generation, **Then** the output is valid TypeScript with proper type annotations.
3. **Given** a Rust project, **When** the developer requests code generation, **Then** the output is valid Rust that compiles without errors.
4. **Given** a Go project, **When** the developer requests code generation, **Then** the output is valid Go that passes `go vet`.

---

### User Story 5 - Resume Previous Sessions (Priority: P5)

The developer exits the agent and later returns to continue working on the same task. The agent restores the previous conversation context so the developer can pick up where they left off without re-explaining the problem.

**Why this priority**: Session persistence avoids wasted time re-establishing context and enables multi-session workflows for complex tasks.

**Independent Test**: Can be tested by having a conversation, exiting, restarting the agent, and verifying previous context is available.

**Acceptance Scenarios**:

1. **Given** an active session with conversation history, **When** the developer exits and restarts the agent, **Then** the previous conversation context is available to resume.
2. **Given** multiple previous sessions exist, **When** the developer starts the agent, **Then** they can select which session to resume.

---

### User Story 6 - Track API Usage and Costs (Priority: P6)

After completing a task, the developer can see how many tokens were used and the approximate cost. This helps them manage API spending and make informed decisions about which tasks to delegate to the agent.

**Why this priority**: Cost visibility prevents surprise bills and helps developers budget their AI usage.

**Independent Test**: Can be tested by completing a code generation task and verifying token count and cost estimate are displayed.

**Acceptance Scenarios**:

1. **Given** a completed code generation task, **When** the operation finishes, **Then** the agent displays token usage and approximate cost.
2. **Given** a session with multiple operations, **When** the developer requests a summary, **Then** cumulative usage for the session is shown.

---

### User Story 7 - Execute Shell Commands with Approval (Priority: P7)

The agent determines that running a shell command would help complete the developer's request (e.g., running tests, checking build output). The agent proposes the command and waits for explicit developer approval before executing.

**Why this priority**: Shell integration extends the agent's capabilities beyond code generation, but requires a safety gate.

**Independent Test**: Can be tested by requesting a task that requires a shell command and verifying the agent asks for approval before execution.

**Acceptance Scenarios**:

1. **Given** a task that requires running a command, **When** the agent proposes a shell command, **Then** it waits for explicit developer approval before executing.
2. **Given** the developer denies a proposed command, **When** the agent receives the denial, **Then** the command is not executed and the agent continues with alternative approaches.

---

### Edge Cases

- What happens when the API key environment variable is missing or invalid? The agent displays a clear error message indicating which key is needed and how to configure it.
- What happens when git has uncommitted changes (dirty state) before auto-commit? The agent warns the developer and offers to proceed or abort.
- What happens when the project contains binary files or very large files? The agent skips them gracefully without crashing or performance issues.
- What happens when generated code would introduce a syntax error? The agent validates output before proposing changes to the developer.
- What happens when the configured LLM provider is unreachable (network issues)? The agent fails with a clear connectivity error message.
- What happens when the developer requests undo but no changes have been made? The agent informs the developer that there are no changes to revert.
- What happens when the API key has insufficient credits or quota? The agent fails immediately with a clear message and direction to the provider's dashboard.
- What happens when the developer manually edits a file while the agent has proposed changes to it? The agent detects the file modification (changed since last read), warns the developer of the conflict, and asks them to re-request the change with the updated file contents.
- What happens when the LLM provider is slow to respond? The agent waits up to 60 seconds, retries once on timeout, then fails with a clear timeout error message.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The agent MUST provide a terminal-native interface that requires no browser, GUI, or display server.
- **FR-002**: The agent MUST generate and edit code in existing project files when requested by the developer.
- **FR-003**: The agent MUST create git commits automatically after approved changes, with descriptive messages following conventional commit format, on the currently checked-out branch.
- **FR-004**: The agent MUST support code generation for at least Python, TypeScript, Rust, and Go.
- **FR-005**: The agent MUST read and search local project files to maintain awareness of the codebase context.
- **FR-006**: The agent MUST work within the container environment without requiring additional setup beyond API key configuration.
- **FR-007**: The agent MUST be available under an open source license that permits commercial use without restrictions.
- **FR-008**: The agent MUST accept LLM provider credentials exclusively from environment variables, never prompting for or persisting credentials to disk.
- **FR-009**: The agent MUST persist conversation history within the container so sessions can be resumed after restart.
- **FR-010**: The agent MUST display proposed shell commands and wait for explicit developer approval before execution.
- **FR-011**: The agent MUST support editing multiple files in a single operation, committing all changes atomically.
- **FR-012**: The agent MUST provide a way to revert the most recent set of applied changes.
- **FR-013**: The agent MUST display token usage and approximate cost after each operation.
- **FR-014**: The agent MUST support connecting to multiple LLM providers (at minimum: OpenAI, Anthropic, and local/self-hosted models).
- **FR-015**: The agent MUST be ready to accept input within 3 seconds of invocation.
- **FR-016**: The agent MUST NOT auto-start when the container launches; it must be explicitly invoked by the developer.
- **FR-017**: The agent's binary MUST be integrity-verified during container build to prevent supply chain compromise.
- **FR-018**: The agent MUST detect when a target file has been modified since it was last read, warn the developer of the conflict, and refuse to apply stale changes.
- **FR-019**: The agent MUST timeout LLM requests after 60 seconds, retry once on timeout, and fail with a clear error message if the retry also times out.

### Key Entities

- **Session**: A conversation between the developer and the agent, containing message history, referenced files, and token usage. Sessions persist within the container and can be resumed.
- **Code Change**: A proposed set of file modifications generated by the agent. Has a pending/approved/rejected state. When approved, results in a git commit.
- **Configuration**: User preferences including LLM provider selection, model choice, and behavior settings. Provided via environment variables and a configuration file.
- **Provider**: An external LLM service (or local model) that the agent connects to for inference. Identified by name and authenticated via API key.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The agent is ready to accept developer input within 3 seconds of invocation.
- **SC-002**: Developers can generate syntactically valid code in all 4 supported languages (Python, TypeScript, Rust, Go) on first request.
- **SC-003**: Auto-generated commit messages pass conventional commit format validation.
- **SC-004**: Multi-file changes are committed atomically in a single git commit (never partial).
- **SC-005**: The agent correctly answers questions about projects containing over 1000 files.
- **SC-006**: Session history is available for resumption after agent exit and restart within the same container.
- **SC-007**: Token usage and cost are displayed within 1 second of operation completion.
- **SC-008**: The container image size increases by no more than 50MB from adding the agent.
- **SC-009**: The agent operates on both x86_64 and ARM64 container architectures without modification.
- **SC-010**: Shell commands are never executed without explicit developer approval.

## Assumptions

- Developers have valid API keys for at least one supported LLM provider before using the agent.
- The container has outbound internet access to reach LLM provider APIs.
- Git is already installed and configured in the container from the base image.
- Developers are comfortable with terminal-based interfaces.
- The container filesystem provides sufficient writable storage for session history.
- No default LLM provider is pre-configured; the developer must specify one on first run.
- Session history does not need to persist across container rebuilds (in-container persistence is sufficient for MVP).
- Conversation history is stored as plaintext for MVP (encryption is a future enhancement).

## Dependencies

- **001-container-base**: Provides the base container image with git and filesystem.
- **003-secret-injection**: Provides API key delivery via encrypted environment variables.

## Constraints

- The agent adds no more than 50MB to the container image.
- No additional runtime interpreters (Python, Node.js) are required solely for the agent.
- API keys are never written to disk, logged, or included in git commits.
- The total container image size must remain under 3GB.
- The agent must support linux/amd64 and linux/arm64 architectures.
