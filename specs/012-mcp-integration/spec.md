# Feature Specification: MCP Integration for AI Agent Capabilities

**Feature Branch**: `012-mcp-integration`
**Created**: 2026-01-23
**Status**: Draft
**Input**: User description: "MCP integration providing AI agents with access to documentation, filesystem, memory, and external services within a containerized development environment"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - AI Agent Accesses Project Files (Priority: P1)

A developer working inside the containerized environment starts an AI coding assistant (Claude Code, Cline, or Continue). The AI agent automatically has access to project files through the filesystem MCP server. The agent can read, search, and list files within the designated workspace directory to understand the codebase and make changes.

**Why this priority**: File access is the most fundamental capability an AI coding agent needs. Without it, the agent cannot read or modify code, making all other features irrelevant.

**Independent Test**: Can be fully tested by starting an AI tool inside the container and requesting it to read a file from the workspace. Delivers immediate value by enabling code understanding and modification.

**Acceptance Scenarios**:

1. **Given** the container is running with MCP configured, **When** the developer starts an AI assistant, **Then** the filesystem MCP server is available and the agent can list files in the workspace.
2. **Given** the filesystem MCP is active, **When** the AI agent requests a file within the allowed workspace directory, **Then** the file contents are returned successfully.
3. **Given** the filesystem MCP is active, **When** the AI agent requests a file outside the allowed directories, **Then** the request is denied with a clear permission error.
4. **Given** the filesystem MCP is active, **When** the AI agent attempts path traversal (e.g., `../../etc/passwd`), **Then** the request is blocked and does not resolve beyond the workspace boundary.

---

### User Story 2 - AI Agent Retrieves Current Documentation (Priority: P1)

A developer asks the AI agent a question about a library (e.g., "How do I use React Router v7?"). Instead of relying on potentially outdated training data, the AI agent uses the Context7 MCP server to retrieve current, accurate documentation for the library in question.

**Why this priority**: AI agents frequently produce outdated API usage. Access to current documentation dramatically improves code suggestion accuracy and is a core differentiator for the development environment.

**Independent Test**: Can be tested by asking the AI agent about a recently-updated library API and verifying the response uses current documentation rather than outdated training data.

**Acceptance Scenarios**:

1. **Given** the Context7 MCP is configured with valid credentials, **When** the AI agent queries documentation for a specific library, **Then** current documentation is returned.
2. **Given** the Context7 MCP is configured, **When** the external documentation service is unavailable, **Then** the agent receives a clear error and can continue working with its built-in knowledge.
3. **Given** no Context7 credentials are configured, **When** the container starts, **Then** a clear warning is shown indicating documentation lookup is unavailable, without blocking other functionality.

---

### User Story 3 - Secure Credential Configuration (Priority: P1)

A developer sets up their containerized environment and needs to provide API keys for MCP servers that access external services. They configure credentials through environment variables, which are injected securely at container startup. Credentials are never stored in configuration files that could be committed to version control.

**Why this priority**: Credential security is non-negotiable. Leaked API keys can lead to unauthorized access and financial liability. This must be solved correctly from the start.

**Independent Test**: Can be tested by configuring environment variables and verifying MCP servers authenticate correctly, while confirming no credentials appear in config files or logs.

**Acceptance Scenarios**:

1. **Given** API credentials are set as environment variables, **When** MCP servers start, **Then** they authenticate successfully with external services.
2. **Given** the configuration file uses variable substitution syntax (e.g., `${API_KEY}`), **When** the config is loaded, **Then** environment variable values are substituted at runtime.
3. **Given** an environment variable referenced in config is missing, **When** the MCP server attempts to start, **Then** a clear warning is logged indicating the missing credential, without exposing the variable name pattern to external services.
4. **Given** the MCP configuration, **When** reviewing log output, **Then** no API keys, tokens, or credential values appear in any log entries.

---

### User Story 4 - AI Agent Uses Memory Across Sessions (Priority: P2)

A developer works on a project over multiple sessions. The AI agent uses the Memory MCP server to retain context about the project—such as coding conventions, architecture decisions, and previous interactions—across container restarts.

**Why this priority**: Memory persistence significantly improves the AI experience over time, but the environment is still useful without it. This builds on the foundational file and documentation access.

**Independent Test**: Can be tested by having the AI agent store a piece of information, restarting the container, and verifying the information is retrievable in the new session.

**Acceptance Scenarios**:

1. **Given** the Memory MCP server is configured with its JSON knowledge graph stored in a Docker volume (`~/.local/share/mcp-memory/`), **When** the AI agent stores context information, **Then** the information persists across container restarts.
2. **Given** stored memory exists, **When** the AI agent starts a new session, **Then** previously stored context is accessible.
3. **Given** the Memory MCP storage is unavailable, **When** the AI agent attempts to store context, **Then** the operation fails gracefully without disrupting the current workflow.

---

### User Story 5 - MCP Configuration Management (Priority: P2)

A developer wants to customize which MCP servers are active in their environment. They edit the project-level source configuration (`.mcp/config.json`) to enable or disable individual servers, and add new MCP servers by providing the appropriate configuration entries.

**Why this priority**: Different projects have different needs. The ability to tailor the MCP server set prevents unnecessary resource usage and allows project-specific extensions.

**Independent Test**: Can be tested by toggling a server's enabled flag in the configuration and verifying the AI tool no longer offers that server's capabilities.

**Acceptance Scenarios**:

1. **Given** a server is set to `enabled: false` in the configuration, **When** the AI tool starts, **Then** that server is not available.
2. **Given** a developer adds a new MCP server entry to the configuration, **When** the AI tool restarts, **Then** the new server is available.
3. **Given** a configuration file with invalid JSON, **When** the system attempts to load it, **Then** a clear error message identifies the problem and no MCP servers start in a broken state.

---

### User Story 6 - Optional Servers Available On-Demand (Priority: P3)

A developer needs access to GitHub issues or browser automation for their current task. They enable the appropriate pre-installed optional MCP server in the source configuration, and after config regeneration, the server becomes available to AI tools immediately.

**Why this priority**: Optional servers add significant value for specific workflows but are not needed by all users. On-demand availability balances functionality with container image size.

**Independent Test**: Can be tested by enabling a previously-disabled optional server and verifying it becomes functional after a brief initialization period.

**Acceptance Scenarios**:

1. **Given** an optional server (e.g., GitHub MCP) is enabled in the source config with valid credentials, **When** config is regenerated and the AI tool restarts, **Then** the server is immediately available without downloads or installation.
2. **Given** an optional server requires network access for its API calls (not installation), **When** network is unavailable, **Then** the failure is reported clearly without affecting other MCP servers.

---

### Edge Cases

- What happens when the configuration file is missing entirely? The system should use sensible defaults (core servers enabled) or clearly indicate that configuration is required.
- How does the system handle multiple AI tools accessing the same MCP server simultaneously? Each AI tool should get its own server process instance to avoid conflicts.
- What happens when a pre-installed MCP server package is corrupted or missing from the container image? A clear diagnostic error should be produced at container startup.
- How does the system behave when the workspace directory itself doesn't exist or is empty? The filesystem MCP should start successfully but return empty results for listing operations.
- What happens when an environment variable contains special characters (quotes, newlines)? The substitution mechanism must handle these correctly without breaking the configuration.

## Clarifications

### Session 2026-01-23

- Q: Should MCP configuration be shared across tools or per-tool? → A: Single source config file, generated into each tool's native format at container startup.
- Q: Should the system manage MCP server lifecycle beyond startup? → A: Startup-only; container ensures correct config and pre-installed dependencies, AI tools manage server processes.
- Q: What storage backend should the memory MCP server use? → A: File-based JSON knowledge graph in a Docker volume (`~/.local/share/mcp-memory/`).
- Q: How should optional MCP servers be made available on-demand? → A: Pre-install all optional server packages in the image, disabled by default in config; enabling requires only a config change.
- Q: Where should the MCP source configuration file live? → A: Project workspace (`.mcp/config.json`), version-controllable and project-specific.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide MCP server runtime capability within the container, supporting stdio transport.
- **FR-002**: System MUST include a filesystem MCP server that restricts operations to explicitly allowed directories only.
- **FR-003**: System MUST enforce a directory allowlist, blocking all file operations targeting paths outside the allowed set (including path traversal and symlink escape attempts).
- **FR-004**: System MUST include a documentation MCP server (Context7) that provides current library documentation to AI agents.
- **FR-005**: System MUST load MCP server configuration from a project-level source file (`.mcp/config.json` in the workspace) with support for environment variable substitution using `${VARIABLE_NAME}` syntax. At container startup, this source config is generated into each AI tool's native configuration format.
- **FR-006**: System MUST never store credentials (API keys, tokens) in configuration files; all credentials MUST be injected via environment variables.
- **FR-007**: System MUST work with Claude Code, Cline, Continue, and other tools that implement the Model Context Protocol.
- **FR-008**: System MUST provide clear error messages when an MCP server fails to start, including the reason for failure.
- **FR-009**: System MUST include documentation for adding custom MCP servers to the environment.
- **FR-010**: System MUST ensure that API keys and credential values never appear in log output.
- **FR-011**: System SHOULD include a persistent memory MCP server (`@modelcontextprotocol/server-memory`) that stores a JSON knowledge graph in a Docker volume (`~/.local/share/mcp-memory/`), retaining context across container sessions.
- **FR-012**: System SHOULD support enabling and disabling individual MCP servers via configuration.
- **FR-013**: System SHOULD pre-install all supported optional MCP server packages in the container image (disabled by default in config). Enabling a server requires only a configuration change, with no runtime downloads or image rebuilds.
- **FR-014**: System SHOULD validate MCP server configuration and dependency availability at container startup, reporting health status. Runtime server process lifecycle is managed by the AI tools themselves.
- **FR-015**: System SHOULD include pre-configured optional servers (Git, GitHub, Playwright) available for activation.
- **FR-016**: System SHOULD include a sequential-thinking MCP server (`@modelcontextprotocol/server-sequential-thinking`) to support multi-step reasoning and reflective problem-solving by AI agents.

### Key Entities

- **MCP Server**: A service that implements the Model Context Protocol, providing specific capabilities (file access, documentation lookup, memory, etc.) to AI tools via stdio communication.
- **MCP Source Configuration**: A project-level JSON file (`.mcp/config.json` in the workspace) defining which servers are available, their startup commands, arguments, environment variables, and enabled/disabled status. This is the canonical source of truth, translated into each AI tool's native config format at container startup. Version-controllable per project.
- **Allowed Directory**: A filesystem path that the filesystem MCP server is permitted to access. All paths are resolved to absolute form and checked against this list before any operation.
- **Credential**: An API key or token required by an MCP server to authenticate with an external service. Always provided via environment variables, never in configuration files.
- **AI Tool**: A client application (Claude Code, Cline, Continue) that connects to MCP servers to extend its capabilities.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: AI agents can read and list files within the workspace immediately upon container startup, without additional manual configuration.
- **SC-002**: AI agents retrieve current library documentation for at least 90% of queries about popular libraries (those tracked by the documentation service).
- **SC-003**: 100% of credential references in configuration use environment variable substitution—no plaintext credentials exist in any configuration file.
- **SC-004**: All configured MCP servers are available to AI tools within 30 seconds of container startup for pre-installed servers.
- **SC-005**: Filesystem access attempts outside allowed directories are blocked 100% of the time, including path traversal and symlink escape vectors.
- **SC-006**: A developer can add a new custom MCP server by editing one configuration file and restarting their AI tool, without modifying the container image.
- **SC-007**: The system works correctly with at least 3 different MCP-compatible AI tools (Claude Code, Cline, Continue).
- **SC-008**: MCP server failures do not prevent the AI tool from starting or functioning with remaining available servers.

## Assumptions

- The MCP protocol specification remains stable and backward-compatible during the implementation timeframe.
- Major AI tools (Claude Code, Cline, Continue) continue to support the MCP standard.
- MCP servers using stdio transport function correctly in containerized environments without modification.
- Node.js and npm/npx are available in the container for MCP server execution.
- Network egress is permitted from the container for MCP servers that require external API access (documentation, GitHub).
- The container base image (from PRD 001) and secret injection mechanism (from PRD 003) are available as foundations.

## Dependencies

- **001-container-base-image**: Provides the container runtime environment where MCP servers execute.
- **003-secret-injection**: Provides the mechanism for injecting credentials as environment variables.
- **005-terminal-ai-agent**: AI tools that consume MCP server capabilities.
- **006-agentic-assistant**: Additional AI tools that consume MCP server capabilities.

## Constraints

- MCP servers must use stdio transport (no network ports or HTTP servers within the container).
- All MCP server packages (core and optional, pre-installed) should not significantly increase container image size (target: under 150MB additional combined).
- Configuration must support multiple AI tools reading the same configuration without conflicts.
- The feature must not require host-side setup or GUI interaction to configure.
- The container is responsible for configuration generation and dependency installation only; MCP server process lifecycle (spawn, restart, teardown) is delegated to the AI tools that invoke them.
