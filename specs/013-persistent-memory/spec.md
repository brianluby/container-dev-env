# Feature Specification: Persistent Memory for AI Agent Context

**Feature Branch**: `013-persistent-memory`
**Created**: 2026-01-23
**Status**: Draft
**Input**: User description: "Persistent memory system for AI coding agents that retains project context, decisions, and patterns across container sessions using a hybrid approach of human-maintained strategic files and automatic tactical context capture"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - AI Remembers Project Context Across Sessions (Priority: P1)

A developer starts a new coding session in the containerized environment. The AI coding assistant automatically loads previously saved project context—including architecture decisions, coding patterns, and project goals—without the developer needing to re-explain anything. The AI's suggestions align with established project conventions from the very first interaction.

**Why this priority**: This is the core value proposition. Without persistent context, developers waste time repeating project details every session. This story alone delivers the primary benefit of the feature.

**Independent Test**: Can be tested by documenting a project convention (e.g., "we use camelCase for function names"), restarting the container, and verifying the AI follows that convention without being reminded.

**Acceptance Scenarios**:

1. **Given** strategic memory files exist with documented project patterns, **When** a developer starts a new AI session, **Then** the AI has access to those patterns and references them in its responses.
2. **Given** a container restart occurs, **When** the developer starts a new session, **Then** all previously saved strategic context is still available to the AI.
3. **Given** strategic memory documents a specific architecture decision, **When** the AI generates code, **Then** the generated code follows that architecture decision.
4. **Given** strategic memory files exist, **When** a developer uses any supported AI tool (Claude Code, Cline, or Continue), **Then** the same strategic context is available regardless of which tool is used.

---

### User Story 2 - Developer Maintains Strategic Context (Priority: P1)

A developer creates and edits structured memory files that describe their project's goals, architecture, technology choices, and current work status. These files are human-readable, version-controlled, and serve as the authoritative source of strategic project context for all AI tools.

**Why this priority**: The strategic memory files are the foundation that all other memory features build upon. They must be usable independently of any automatic memory system, providing value even in the simplest configuration.

**Independent Test**: Can be tested by creating a memory file with project architecture details, then asking the AI a question about the project architecture and verifying it uses the documented information.

**Acceptance Scenarios**:

1. **Given** a new project workspace, **When** a developer initializes the memory system, **Then** template files are created with clear placeholder guidance for each category.
2. **Given** existing memory files, **When** a developer edits a file to update project patterns, **Then** the next AI session reflects the updated patterns.
3. **Given** memory files in the workspace, **When** the developer commits them to version control, **Then** team members who clone the project receive the same strategic context.
4. **Given** a memory file with invalid formatting, **When** the AI attempts to read it, **Then** it reads what it can and does not crash or produce errors visible to the user.

---

### User Story 3 - Automatic Session Context Capture (Priority: P2)

During a coding session, the AI automatically captures relevant context—such as code patterns discussed, decisions made, and recent changes—without the developer needing to manually save anything. This tactical context is available in subsequent sessions to provide continuity.

**Why this priority**: Automatic capture reduces the maintenance burden on developers. However, the system provides value without it (via strategic memory files alone), making this an enhancement rather than a core requirement.

**Independent Test**: Can be tested by having a coding session where specific patterns are discussed, starting a new session, and verifying the AI can recall those recent patterns through semantic search.

**Acceptance Scenarios**:

1. **Given** an active coding session, **When** the AI processes developer requests, **Then** relevant context is captured automatically without explicit developer action.
2. **Given** previously captured session context, **When** the developer starts a new session and asks a related question, **Then** the AI retrieves relevant captured context to inform its response.
3. **Given** the automatic capture system is unavailable, **When** the developer starts a session, **Then** the strategic memory files are still loaded and the AI functions normally.

---

### User Story 4 - Semantic Search for Relevant Context (Priority: P2)

When an AI agent needs context for a coding task, it can search across captured tactical memory using meaning-based queries rather than exact keyword matches. This ensures the most relevant past context is surfaced even when the developer phrases things differently than before.

**Why this priority**: Semantic search dramatically improves the usefulness of captured context by finding relevant information even with different terminology. However, keyword-based access to strategic memory files provides baseline functionality.

**Independent Test**: Can be tested by storing context about "authentication flow" and then querying for "login process" and verifying the authentication context is returned.

**Acceptance Scenarios**:

1. **Given** tactical memory contains information about a topic, **When** the AI searches for that topic using different wording, **Then** relevant results are returned based on meaning similarity.
2. **Given** a semantic search, **When** results are returned, **Then** they include a relevance score and are ordered by relevance.
3. **Given** a semantic search with no relevant matches, **When** results are returned, **Then** an empty result set is provided rather than irrelevant content.

---

### User Story 5 - Memory Isolation Per Project (Priority: P2)

Each project workspace has its own isolated memory. A developer working on multiple projects has separate strategic context and tactical memory for each, preventing cross-contamination of patterns and decisions between unrelated projects.

**Why this priority**: Project isolation prevents confusing AI behavior when developers work on multiple projects. It's important for correctness but the system can deliver value for single-project users without it.

**Independent Test**: Can be tested by setting up memory in two different project workspaces and verifying that each AI session only accesses memory from its own project.

**Acceptance Scenarios**:

1. **Given** two project workspaces with different memory, **When** the developer works in project A, **Then** only project A's memory is accessible to the AI.
2. **Given** a project workspace, **When** the memory system initializes, **Then** memory storage paths are scoped to the project directory.

---

### User Story 6 - Memory Size Management (Priority: P3)

Over time, captured tactical memory grows. The system automatically manages storage size through retention policies, ensuring that old, irrelevant context is pruned while important recent context is preserved.

**Why this priority**: Storage management is only relevant for long-running projects with significant accumulated context. The system works without it initially, but needs it for long-term sustainability.

**Independent Test**: Can be tested by configuring a short retention period, generating a large amount of captured context, and verifying that entries beyond the retention period are removed.

**Acceptance Scenarios**:

1. **Given** a configured retention period, **When** tactical memory entries exceed that age, **Then** they are automatically removed.
2. **Given** memory pruning occurs, **When** checking storage, **Then** disk usage is reduced to reflect removed entries.
3. **Given** no explicit retention configuration, **When** the system runs, **Then** a reasonable default retention period is applied (assumed: 30 days).

---

### Edge Cases

- What happens when the persistent storage volume is not mounted? The system should produce a clear error with setup instructions rather than silently losing memory.
- How does the system handle a corrupted memory database? It should start fresh (tactical memory only) rather than blocking AI functionality, while preserving the strategic memory files.
- What happens when strategic memory files exceed the recommended size? The system should warn the developer at 500KB total and still function correctly. The hard limit for version-control friendliness is 1MB (SC-007).
- How does the system behave when two AI tools attempt to write to tactical memory simultaneously? The storage layer should handle concurrent writes safely without data corruption.
- What happens when a developer moves a project to a new machine without the tactical memory? Strategic memory (in version control) should be available immediately; tactical memory starts fresh.
- What happens when memory contains accidentally captured sensitive information? The developer should be able to inspect and delete specific memory entries.

## Clarifications

### Session 2026-01-23

- Q: What storage backend should tactical memory use? → A: SQLite with sqlite-vec extension (embedded vector search, WAL mode for concurrent writes, no external service required).
- Q: Should tactical memory be encrypted at rest? → A: No; rely on Docker volume permissions and local-only access. No encryption needed for local-only developer tool data.
- Q: What is the acceptable container startup time overhead for the memory system? → A: Under 2 seconds added to container startup.
- Q: What is the absolute storage size cap for tactical memory? → A: 500MB hard cap; triggers oldest-first pruning when exceeded, in addition to time-based retention.
- Q: Where do embeddings for semantic search come from? → A: Local lightweight model (BAAI/bge-small-en-v1.5 via FastEmbed, ~50MB quantized) bundled in the container image; fully offline-capable. 384-dimensional output vectors.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST persist all memory data across container restarts using volume-backed storage.
- **FR-002**: System MUST scope memory to individual project workspaces, preventing cross-project contamination. (Core scoping implemented in Foundational phase via project ID hashing; US5 adds explicit multi-workspace verification and edge case handling.)
- **FR-003**: System MUST store strategic context in human-readable, editable files that can be version-controlled.
- **FR-004**: System MUST provide template files with clear category guidance when initializing strategic memory for a new project.
- **FR-005**: System MUST make strategic memory accessible to Claude Code, Cline, Continue, OpenCode, and other AI tools via a tool-agnostic MCP server (client-side configuration files are generated once per tool but the server requires no tool-specific code).
- **FR-006**: System MUST load strategic memory at the start of each AI session automatically.
- **FR-007**: System MUST continue functioning if the automatic capture system is unavailable (graceful degradation to strategic memory only).
- **FR-008**: System MUST prevent secrets, API keys, and credentials from being included in version-controlled memory files (through guidance, templates, and documentation).
- **FR-009**: System MUST ensure tactical memory storage is excluded from version control to prevent accidental commits of session data.
- **FR-010**: System SHOULD capture session context automatically without requiring explicit developer action.
- **FR-011**: System SHOULD provide meaning-based search across captured tactical memory, returning results ranked by relevance.
- **FR-012**: System SHOULD organize strategic memory into distinct categories (goals, architecture, patterns, technology, status).
- **FR-013**: System SHOULD automatically manage tactical memory size through configurable retention policies.
- **FR-014**: System SHOULD allow developers to inspect and delete specific entries from tactical memory.
- **FR-015**: System SHOULD support cross-tool memory sharing, where context captured by one AI tool is accessible to others.

### Key Entities

- **Strategic Memory**: Long-term, stable project context maintained by developers in structured files. Contains architecture decisions, coding patterns, project goals, and technology choices. Version-controlled and shared across the team.
- **Tactical Memory**: Short-term, automatically captured session context stored in a SQLite database with the sqlite-vec extension for vector similarity search. Uses WAL mode for safe concurrent writes from multiple AI tools. Contains recent code patterns, session interactions, and working state. Local to the developer's environment, not version-controlled.
- **Memory Category**: A logical grouping of strategic context (e.g., project goals, architecture patterns, technology context, current work, progress). Each category has its own file for easy navigation.
- **Memory Entry**: A discrete unit of captured tactical context, including content, timestamp, source session, embedding vector (384-dimensional, generated by BAAI/bge-small-en-v1.5 via FastEmbed), and relevance metadata for search.
- **Retention Policy**: Rules governing when tactical memory entries are automatically removed. Combines time-based retention (default: 30 days) with a 500MB hard storage cap. When either threshold is exceeded, oldest entries are pruned first. Configurable per project.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers spend zero additional time re-explaining project context at the start of each session (previously ~5 minutes per session). Measured by: AI references strategic memory content in first response without developer prompting.
- **SC-002**: AI-generated code follows documented project patterns at least 80% of the time when patterns are described in strategic memory. Measured by: automated test suite with 10+ pattern-matching scenarios verifying AI output against documented conventions.
- **SC-003**: Relevant context is retrieved from tactical memory within 50 milliseconds for 95% of queries.
- **SC-004**: Strategic memory is accessible to at least 3 different AI tools without tool-specific modifications.
- **SC-005**: All memory persists correctly through at least 10 consecutive container restarts with no data loss.
- **SC-006**: A new project can be initialized with the complete strategic memory template in under 1 minute.
- **SC-007**: Total strategic memory file size remains under 1MB per project to maintain version-control friendliness.
- **SC-008**: Tactical memory automatically prunes entries beyond the retention period, keeping storage bounded.

## Assumptions

- Docker volumes (from the volume architecture feature) persist data correctly across container restarts.
- The MCP infrastructure (from the MCP integration feature) is available for the tactical memory service.
- Developers will review and maintain strategic memory files as part of their normal workflow (similar to maintaining documentation).
- AI tools can read standard files from the workspace directory as part of their context loading.
- Semantic search provides better context retrieval than keyword matching for this use case. BAAI/bge-small-en-v1.5 via FastEmbed (~50MB quantized) bundled in the container image provides offline-capable vector generation.
- Strategic memory files will remain small enough (<1MB total) to be practical in version control.
- The 30-day default retention for tactical memory provides a reasonable balance between context richness and storage management.

## Dependencies

- **001-container-base-image**: Provides the container runtime where memory services execute.
- **004-volume-architecture**: Provides persistent storage volumes for memory data.
- **011-mcp-integration**: Provides MCP infrastructure for the tactical memory service integration.
- **010-project-context-files**: Defines the boundary between static AI instructions (AGENTS.md) and dynamic project state (strategic memory).

## Constraints

- Strategic memory files must be standard readable files (no binary formats) for universal AI tool access.
- Tactical memory must be excluded from version control to prevent accidental commits of session data or sensitive information.
- The memory system initialization (strategic file loading + SQLite/sqlite-vec startup) must add no more than 2 seconds to container startup time.
- Memory must be project-scoped (see FR-002).
- The feature must not require internet access for core functionality (all local storage).
- Tactical memory does not require encryption at rest; Docker volume permissions and local-only access provide sufficient protection for this developer-local data.
