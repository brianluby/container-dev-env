# Feature Specification: AI IDE Extensions

**Feature Branch**: `009-ai-ide-extensions`
**Created**: 2026-01-23
**Status**: Draft
**Input**: User description: "AI-powered code completion and chat extensions for containerized IDE using Continue (primary) and Cline (secondary), with multi-provider LLM support, MCP integration, and environment variable-based API key management"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inline Code Completions (Priority: P1)

A developer working in the containerized IDE types code in Python, TypeScript, Rust, or Go and receives AI-generated code suggestions as ghost text. The developer presses Tab to accept a suggestion or continues typing to dismiss it. Completions are contextually aware of the current file and nearby code.

**Why this priority**: Inline completions are the most frequently used AI coding feature, providing continuous productivity gains with minimal workflow disruption. This is the foundation of AI-assisted development.

**Independent Test**: Can be fully tested by opening a source file, typing a partial function, and verifying that relevant ghost text completions appear. Delivers immediate productivity value without requiring any other AI feature.

**Acceptance Scenarios**:

1. **Given** OpenVSCode-Server running with Continue extension activated, **When** I type a Python function signature, **Then** I see contextually relevant completion suggestions as ghost text within 5 seconds.
2. **Given** Continue extension with a configured LLM provider, **When** I press Tab on a ghost text suggestion, **Then** the suggestion is inserted into my code at the cursor position.
3. **Given** Continue extension active, **When** I type code in a TypeScript, Rust, or Go file, **Then** I receive language-appropriate completions that respect the file's syntax and conventions.
4. **Given** Continue extension active, **When** I dismiss a suggestion by continuing to type, **Then** the ghost text disappears and does not interfere with my editing.

---

### User Story 2 - Chat-Based Code Assistance (Priority: P1)

A developer opens the chat panel within the IDE, asks questions about their codebase, requests explanations of code snippets, or asks for help writing new functionality. The AI responds with helpful, accurate, and contextually relevant answers.

**Why this priority**: Chat assistance is the second-most-used AI coding feature, handling tasks that inline completions cannot — explaining complex code, debugging help, and generating code from natural language descriptions.

**Independent Test**: Can be fully tested by opening the chat panel, asking a question about a code file in the workspace, and verifying a relevant response is returned. Delivers value independently of inline completions.

**Acceptance Scenarios**:

1. **Given** Continue chat panel is open and a file is active in the editor, **When** I ask "explain this function", **Then** I receive an accurate explanation of the active function.
2. **Given** Continue chat panel, **When** I describe new functionality in natural language (e.g., "write a function to parse CSV files"), **Then** I receive a working code implementation I can insert into my file.
3. **Given** Continue chat panel, **When** I paste a code snippet and ask "what's wrong with this code?", **Then** I receive helpful debugging suggestions identifying potential issues.

---

### User Story 3 - API Key Configuration and Provider Setup (Priority: P1)

A developer configures their AI extensions by providing API keys through environment variables. The extensions automatically detect the keys and authenticate to the LLM provider without requiring manual setup steps in the UI.

**Why this priority**: Without working authentication, no AI features function. This is a prerequisite for all other capabilities and must work seamlessly through the existing secret injection mechanism.

**Independent Test**: Can be tested by setting the API key environment variable, starting the containerized IDE, and verifying the extension activates and authenticates without user prompts.

**Acceptance Scenarios**:

1. **Given** ANTHROPIC_API_KEY is set as an environment variable via secret injection, **When** the IDE container starts and Continue extension loads, **Then** the extension authenticates automatically and shows a connected status.
2. **Given** an API key environment variable is missing, **When** the extension loads, **Then** a clear error message is displayed in the Output panel indicating which key is needed and how to configure it.
3. **Given** an invalid API key is provided, **When** the extension attempts to authenticate, **Then** a user-friendly error message is shown without exposing the key value in logs or UI.

---

### User Story 4 - Multi-Provider LLM Support (Priority: P2)

A developer configures multiple LLM providers (Anthropic, OpenAI, local Ollama) and can switch between them based on task requirements, cost considerations, or privacy needs. If one provider is unavailable, the developer can quickly switch to an alternative.

**Why this priority**: Provider flexibility prevents vendor lock-in, enables cost optimization, and provides resilience against API outages. It also enables local-only operation for sensitive code.

**Independent Test**: Can be tested by configuring two different providers, making requests to each, and verifying both return valid responses.

**Acceptance Scenarios**:

1. **Given** both Anthropic and OpenAI providers are configured, **When** I switch between providers in the extension settings, **Then** completions and chat continue working with the newly selected provider.
2. **Given** a local Ollama instance is running, **When** I configure Continue to use it, **Then** completions work without any external API calls.
3. **Given** the primary provider's API is unreachable, **When** I switch to the secondary provider, **Then** AI features resume working within a few seconds.

---

### User Story 5 - MCP Integration for Extended Context (Priority: P2)

AI extensions use MCP (Model Context Protocol) servers to access workspace files and git context, providing better informed completions and responses by understanding the full project structure.

**Why this priority**: MCP integration significantly improves the quality of AI responses by giving the model access to relevant project context beyond the current file, making the AI more useful for real-world multi-file projects.

**Independent Test**: Can be tested by configuring a filesystem MCP server, opening the chat panel, and asking a question that requires knowledge of files not currently open in the editor.

**Acceptance Scenarios**:

1. **Given** filesystem MCP server is configured pointing to /workspace, **When** I ask the AI about a file I haven't opened, **Then** the AI can read and reference that file's contents in its response.
2. **Given** git MCP server is configured, **When** I ask "what changed in the last commit?", **Then** the AI provides an accurate summary of recent changes.
3. **Given** MCP server is configured, **When** the MCP server process crashes, **Then** the extension shows a non-fatal error and core AI features (completions, chat) continue working without MCP context.

---

### User Story 6 - Agentic Multi-Step Tasks with Human Approval (Priority: P3)

A developer uses Cline for complex tasks requiring multiple file edits, command execution, or code generation across several files. Cline proposes changes in a plan/act workflow and requires explicit human approval before modifying files or running commands.

**Why this priority**: Agentic capabilities handle the long-tail of complex coding tasks that completions and chat cannot. The human-in-the-loop approval ensures safety while enabling powerful multi-step operations.

**Independent Test**: Can be tested by giving Cline a multi-file task, reviewing its proposed plan, and approving or rejecting individual steps.

**Acceptance Scenarios**:

1. **Given** Cline extension is active, **When** I describe a multi-file refactoring task, **Then** Cline proposes a plan showing which files will be modified.
2. **Given** Cline proposes file modifications, **When** the diff is shown for approval, **Then** I can approve or reject each change individually before it's applied.
3. **Given** Cline proposes running a terminal command, **When** the command is shown for approval, **Then** I must explicitly approve before the command executes.
4. **Given** I reject a proposed change, **When** Cline receives the rejection, **Then** it acknowledges the rejection and may propose an alternative approach.

---

### User Story 7 - Extension Installation and Activation (Priority: P1)

Both AI extensions (Continue and Cline) install automatically from the Open VSX registry during container setup and activate without errors in the OpenVSCode-Server environment. No host-side software or manual installation steps are required.

**Why this priority**: Automatic installation ensures the AI development environment is ready immediately when the container starts, critical for the containerized workflow to be competitive with local IDE setups.

**Independent Test**: Can be tested by building a fresh container and verifying both extensions appear in the extensions list and activate without errors in the Output panel.

**Acceptance Scenarios**:

1. **Given** a fresh IDE container build, **When** the container starts, **Then** Continue extension is installed and activated without errors.
2. **Given** a fresh IDE container build, **When** the container starts, **Then** Cline extension is installed and activated without errors.
3. **Given** both extensions are installed, **When** I check the Extensions panel, **Then** both show as enabled with no compatibility warnings.
4. **Given** extensions are installed in a volume, **When** the container is rebuilt, **Then** extensions persist and do not require re-installation.

---

### Edge Cases

- When the API key environment variable is empty or contains whitespace, the system shows a clear error indicating the key is missing/invalid without exposing the value.
- When the LLM provider API returns a 429 (rate limit) response, the system shows a non-blocking error notification; the user can retry manually.
- When the LLM provider API times out (>30 seconds), the system shows a non-blocking error notification; the user can retry manually.
- When both Continue and Cline attempt to use the same MCP server simultaneously, each extension manages its own MCP server subprocess independently.
- When the container runs with less than 512MB of available memory while both extensions are active, extensions degrade gracefully without crashing the IDE.
- When the workspace contains very large files (>1MB) that the MCP server attempts to read, the MCP server handles them without crashing (may truncate or skip).
- When network egress is blocked and no local model is configured, all LLM-dependent features are unavailable; a non-blocking error notification indicates connectivity issues.
- When an extension update on Open VSX introduces a breaking change, pinned versions in the manifest prevent automatic updates.
- When the API key is rotated while the extension is running, the extension uses the new key on the next API call (re-reads env var or requires extension reload).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST install Continue and Cline extensions from the Open VSX registry during container initialization.
- **FR-002**: System MUST activate both extensions in OpenVSCode-Server without errors or host-side dependencies.
- **FR-003**: System MUST provide inline code completions (ghost text) for Python, TypeScript, Rust, and Go files.
- **FR-004**: System MUST provide a chat interface for code questions, explanations, and natural language code generation.
- **FR-005**: System MUST accept LLM provider API keys via environment variables, never requiring manual entry in the UI.
- **FR-006**: System MUST support at least three LLM providers: Anthropic, OpenAI, and Ollama (local).
- **FR-007**: System MUST integrate with MCP servers for filesystem and git context access.
- **FR-008**: System MUST scope MCP filesystem access to the /workspace directory only.
- **FR-009**: System MUST require explicit human approval before Cline performs file writes or command execution.
- **FR-010**: System MUST disable extension telemetry by default.
- **FR-011**: System MUST persist extension configurations and installed extensions across container rebuilds via volumes.
- **FR-012**: System MUST display a clear, actionable error message when an API key is missing, invalid, or expired — without exposing the key value.
- **FR-013**: System MUST allow provider switching without extension reinstallation or container restart.
- **FR-014**: System MUST function entirely within the container without any host-side installations.
- **FR-015**: System MUST use file-based configuration (YAML for Continue, JSON for Cline) referencing environment variable secrets.
- **FR-016**: System MUST show a non-blocking error notification when an LLM API call fails (timeout, rate limit, or network error), allowing the user to retry manually without IDE disruption.
- **FR-017**: System MUST pin extension versions to specific tested versions in the installation manifest; updates require manual review and manifest change.
- **FR-018**: System MUST configure a faster/cheaper model for tab autocomplete and a more capable model for chat interactions, optimizing for latency and cost on completions while preserving quality for conversations.
- **FR-019**: System MUST provide user-scoped default configuration (global API keys, model preferences) with optional workspace-level overrides for per-project customization (e.g., different model or local-only provider for sensitive projects).

### Key Entities

- **AI Extension**: An IDE plugin providing AI-powered coding features (completions, chat, code generation). Key attributes: name, version, registry source, activation status, configured provider.
- **LLM Provider**: An external or local service providing language model inference. Key attributes: name, API endpoint, authentication method, supported models, cost characteristics.
- **MCP Server**: A subprocess providing structured tool access (filesystem, git) to AI extensions via the Model Context Protocol. Key attributes: name, command, arguments, scope/permissions.
- **Extension Configuration**: File-based settings defining provider credentials, model selection, MCP server definitions, and behavioral preferences. Key attributes: format (YAML/JSON), location, secret references.
- **API Key**: A secret credential authenticating an extension to an LLM provider. Key attributes: provider, injection method (environment variable), scope.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Both extensions activate successfully on 100% of fresh container builds without manual intervention.
- **SC-002**: Inline code completions appear within 5 seconds of typing in all four supported languages (Python, TypeScript, Rust, Go).
- **SC-003**: Chat responses are returned within 10 seconds for typical code questions (under 500 tokens of context).
- **SC-004**: Developers can switch between at least 2 configured LLM providers without restarting the IDE.
- **SC-005**: MCP filesystem tools correctly read and reference files within /workspace scope when requested.
- **SC-006**: Cline never modifies files or executes commands without explicit developer approval being shown and accepted.
- **SC-007**: API key configuration via environment variables works on first container start with no additional manual setup steps.
- **SC-008**: Extensions persist across container rebuilds — a rebuild does not require re-installation or reconfiguration.
- **SC-009**: No API keys appear in extension logs, Output panel, or telemetry transmissions.
- **SC-010**: Both extensions operate within the container's 512MB memory constraint without causing instability.

## Assumptions

- OpenVSCode-Server (008) is fully operational and supports extension installation from Open VSX.
- The secret injection mechanism (003) is functional and can provide environment variables to the container.
- Network egress from the container to external LLM APIs (api.anthropic.com, api.openai.com) is permitted.
- Developers have at least one valid API key for a supported LLM provider.
- Continue and Cline extensions remain available on the Open VSX registry.
- The volume architecture (004) supports persisting extension data across rebuilds.
- Node.js is available in the container for npx-based MCP server execution.
- Token costs for typical development usage are acceptable ($20-100/month per developer).
- Both Apache 2.0-licensed extensions remain actively maintained.

## Clarifications

### Session 2026-01-23

- Q: When an LLM provider API call fails (timeout, rate limit, or network error), what should the extension do? → A: Show a non-blocking error notification immediately; user can retry manually.
- Q: Should extension versions be pinned or always install latest? → A: Pin to specific tested versions; update manually after review.
- Q: Should tab autocomplete use a different model than chat? → A: Yes, use a faster/cheaper model for autocomplete and a more capable model for chat.
- Q: Should configs be workspace-scoped or user-scoped? → A: User-scoped defaults with optional workspace-level overrides.

## Dependencies

- **008-prd-containerized-ide**: Provides the OpenVSCode-Server IDE platform.
- **003-prd-secret-injection**: Provides the API key environment variable injection mechanism.
- **004-volume-architecture**: Provides persistent storage for extension data and configuration.
- **001-container-base-image**: Provides Node.js runtime required for MCP servers.
