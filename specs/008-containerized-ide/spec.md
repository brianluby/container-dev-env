# Feature Specification: Containerized IDE

**Feature Branch**: `008-containerized-ide`
**Created**: 2026-01-22
**Status**: Draft
**Input**: User description: "Browser-accessible VS Code-compatible IDE running entirely in Docker, using OpenVSCode-Server with token authentication, Open VSX extensions, and volume-based persistence."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browser-Based Code Editing (Priority: P1)

A developer opens a web browser on any device (laptop, tablet, thin client) and navigates to `localhost:3000`. Without installing any software on their host machine, they get a full VS Code-compatible editor with syntax highlighting, IntelliSense, file navigation, and integrated terminal. They can immediately start writing and editing code in their project workspace.

**Why this priority**: This is the foundational capability. Without browser-based editing, no other IDE features matter. It directly enables the "develop from anywhere" value proposition and eliminates host-side IDE installation requirements.

**Independent Test**: Can be tested by starting the container and accessing `localhost:3000` in a browser, verifying the editor loads and basic editing works.

**Acceptance Scenarios**:

1. **Given** a running IDE container with workspace volume mounted, **When** a developer navigates to the IDE URL in any modern browser, **Then** a full code editor loads with syntax highlighting, file explorer, and terminal within 30 seconds (cold start).
2. **Given** the browser-based editor is loaded, **When** the developer opens a source file (Python, TypeScript, Rust, Go), **Then** syntax highlighting is applied correctly for the file's language.
3. **Given** the browser-based editor is loaded, **When** the developer opens the integrated terminal, **Then** they get a bash shell session running inside the container environment with access to all development tools.
4. **Given** a developer on an arm64 (Apple Silicon) machine, **When** they build and run the container, **Then** the IDE works identically to amd64 environments.
5. **Given** the IDE is running, **When** the developer makes edits and saves, **Then** changes are persisted to the workspace volume and visible to the host filesystem.

---

### User Story 2 - Extension-Powered Language Support (Priority: P2)

A developer needs language-specific tooling (code completion, linting, debugging) for their project. They install extensions from the Open VSX registry, and these extensions provide IntelliSense, error checking, and debugging. Extensions persist across container restarts via a dedicated volume mount, and projects can declare recommended extensions in a manifest file for automatic installation.

**Why this priority**: Raw editing without language intelligence is insufficient for productive development. Extensions transform the editor into a full IDE experience, and persistence prevents re-downloading on every restart.

**Independent Test**: Can be tested by installing a language extension (e.g., Python support) and verifying auto-completion, linting, and debugging work, then restarting the container and confirming the extension is still active.

**Acceptance Scenarios**:

1. **Given** the IDE is running, **When** a developer installs a language extension from Open VSX (e.g., Python, TypeScript, Rust), **Then** the extension activates and provides IntelliSense for that language.
2. **Given** extensions are installed on the extensions volume, **When** the container is restarted, **Then** previously installed extensions remain available without reinstallation.
3. **Given** a project with an extensions manifest file listing recommended extensions, **When** the container starts, **Then** all recommended extensions are automatically installed if not already present.
4. **Given** a debugging extension (e.g., debugpy) is installed, **When** the developer sets breakpoints and starts a debug session, **Then** the debugger stops at breakpoints and shows variable state via the Debug Adapter Protocol.
5. **Given** a required extension is not available in Open VSX, **When** the developer has a VSIX file, **Then** they can sideload the extension manually.

---

### User Story 3 - Git Integration and Version Control (Priority: P2)

A developer working in the containerized IDE performs version control operations through the IDE's graphical interface. They view diffs, stage changes, commit, switch branches, and view history without needing the terminal for common git operations.

**Why this priority**: Version control is essential for any development workflow. Graphical git integration reduces friction and errors compared to terminal-only workflows.

**Independent Test**: Can be tested by making file changes in the workspace and verifying the IDE shows diffs, allows staging, and creates commits correctly.

**Acceptance Scenarios**:

1. **Given** a project with git initialized in the workspace, **When** the developer modifies files, **Then** the IDE shows changed files with visual diff indicators in the source control panel.
2. **Given** modified files in the workspace, **When** the developer stages and commits through the IDE UI, **Then** the commit is created on the correct branch with the developer's git identity.
3. **Given** a repository with multiple branches, **When** the developer switches branches via the IDE, **Then** the workspace updates to reflect the new branch's contents.
4. **Given** a file with merge conflicts, **When** the developer opens it, **Then** the IDE shows conflict markers with accept/reject options.

---

### User Story 4 - Token-Based Authentication (Priority: P2)

A developer accesses the containerized IDE with a connection token that prevents unauthorized access. The token is provided via environment variable at container startup, and the IDE rejects all connections that do not present a valid token.

**Why this priority**: Without authentication, anyone with network access to the container can read/modify source code and execute arbitrary commands in the terminal. Token auth is the minimum viable security boundary.

**Independent Test**: Can be tested by attempting to access the IDE URL without a valid token and verifying access is denied with HTTP 401.

**Acceptance Scenarios**:

1. **Given** the IDE is configured with a connection token, **When** a browser connects without the token, **Then** access is denied and a clear authentication prompt is displayed.
2. **Given** the IDE is configured with a connection token, **When** a browser provides the correct token, **Then** full access to the IDE is granted.
3. **Given** the token is set via environment variable, **When** the container starts, **Then** the token is not visible in the Dockerfile, image layers, or server logs.
4. **Given** multiple connection attempts with invalid tokens, **When** requests arrive, **Then** they are all rejected and the failed attempts are logged with timestamps.

---

### User Story 5 - Persistent Workspace Configuration (Priority: P3)

A developer customizes their IDE settings (editor preferences, keybindings, theme, workspace settings) and expects these to persist across container rebuilds. The workspace volume and extensions volume store all mutable state so that container image updates do not reset the developer's environment.

**Why this priority**: Without persistence, developers must reconfigure on every container restart, creating friction. Volume-based persistence separates configuration from the container lifecycle.

**Independent Test**: Can be tested by changing IDE settings, restarting the container, and verifying settings are preserved.

**Acceptance Scenarios**:

1. **Given** a developer has customized editor settings (font size, theme, tab width), **When** the container is restarted, **Then** all settings are preserved.
2. **Given** the IDE stores configuration on the extensions volume, **When** the container image is rebuilt, **Then** user configuration is not lost.
3. **Given** the workspace volume is mounted, **When** the developer creates files or modifies projects, **Then** changes are available on the host filesystem via the volume mount.

---

### User Story 6 - Resource-Efficient Operation (Priority: P3)

A developer runs the containerized IDE on a machine with limited resources. The IDE operates within the configured memory limit (512MB), starting quickly and responding without lag during typical editing, even with a language server active.

**Why this priority**: Resource efficiency determines whether the IDE is practical alongside other containers and tools. An IDE that consumes excessive resources is unusable in a development stack.

**Independent Test**: Can be tested by monitoring resource usage via `docker stats` during typical editing and verifying it stays within the 512MB container limit.

**Acceptance Scenarios**:

1. **Given** the IDE container is running idle, **When** no editor activity is occurring, **Then** memory consumption stays below 50MB.
2. **Given** active editing with one language server running, **When** the developer is coding, **Then** the IDE remains responsive with memory usage below 500MB.
3. **Given** the container has a 512MB memory limit, **When** resource pressure approaches the limit, **Then** the IDE degrades gracefully (e.g., disables background indexing) rather than crashing.
4. **Given** a cold container start, **When** the developer starts the container, **Then** the IDE is accessible within 30 seconds.

---

### Edge Cases

- What happens when the browser loses WebSocket connectivity while editing? (Browser should display a clear reconnection status indicator; unsaved changes preserved in browser memory)
- How does the system handle the browser tab being closed with unsaved changes? (Standard browser beforeunload prompt warns about unsaved changes)
- What happens when the container is stopped while the IDE has active terminal sessions? (Terminal state is lost; new terminals can be opened on restart without IDE restart)
- What happens when the mounted workspace volume becomes unavailable or corrupted? (IDE should fail fast with a clear error rather than silently corrupting data)
- What happens when an extension is not available in Open VSX? (Developer can sideload via VSIX file; manifest install logs a warning and continues)
- What happens when the Open VSX registry is unreachable? (Extension install skipped with warning; cached extensions on volume still work)
- How does the system handle concurrent access from multiple browser tabs? (Same session shared across tabs; no multi-user isolation)
- What happens if the connection token is invalid or expired? (Clear HTTP 401 response with re-authentication instructions)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a code editor accessible via standard web browser (Chrome, Firefox, Safari, Edge) without any host-side software installation.
- **FR-002**: System MUST provide syntax highlighting for common programming languages (at minimum: Python, TypeScript/JavaScript, Rust, Go, HTML/CSS, JSON, YAML, Markdown, Bash).
- **FR-003**: System MUST provide code completion and IntelliSense when appropriate language extensions are installed from Open VSX.
- **FR-004**: System MUST provide an integrated terminal that executes commands within the container environment via PTY proxy.
- **FR-005**: System MUST provide a file explorer for navigating the project workspace volume.
- **FR-006**: System MUST support installation of extensions from the Open VSX registry and via local VSIX sideloading.
- **FR-007**: System MUST persist installed extensions across container restarts via a dedicated extensions volume.
- **FR-008**: System MUST support declarative extension management through a manifest file (extensions.json) listing recommended extensions for automatic installation on container start.
- **FR-009**: System MUST provide integrated git support (view diffs, stage changes, commit, switch branches) through the graphical interface.
- **FR-010**: System MUST require a connection token for all WebSocket connections, rejecting unauthenticated requests with HTTP 401.
- **FR-011**: System MUST run on both arm64 (Apple Silicon) and amd64 architectures via multi-arch container manifest.
- **FR-012**: System MUST respect the configured container memory limit (512MB) without crashing, gracefully degrading performance when constrained.
- **FR-013**: System MUST persist workspace configuration (editor settings, keybindings) across container restarts via volume mounts.
- **FR-014**: System MUST provide file search functionality across the project workspace.
- **FR-015**: System MUST support the Debug Adapter Protocol for interactive debugging when appropriate extensions are installed.
- **FR-016**: System MUST run as a non-root user (UID 1000) within the container.
- **FR-017**: System MUST expose only a single network port (3000) for all IDE communication (HTTP and WebSocket).
- **FR-018**: System MUST bind to localhost (127.0.0.1) by default, requiring explicit configuration for non-loopback binding.
- **FR-019**: System MUST inject the connection token via environment variable, never hardcoding it in the image or configuration files.
- **FR-020**: System MUST log failed authentication attempts with timestamps for security auditing.

### Key Entities

- **IDE Container**: The Docker container running the web-based code editor server, exposing a single HTTP/WebSocket port for browser access.
- **Workspace Volume**: A Docker named volume mounted at `/home/workspace`, containing the developer's source code. Persists across container restarts and is accessible from the host.
- **Extensions Volume**: A Docker named volume mounted at the server's extensions directory, storing installed extensions so they persist across container restarts.
- **Extension Manifest**: A JSON file (extensions.json) listing recommended extension IDs from Open VSX, used by the entrypoint script to install missing extensions on container start.
- **Connection Token**: A cryptographically random string (minimum 32 characters) injected via environment variable, required for WebSocket upgrade authentication.
- **Session**: An active browser-to-server WebSocket connection representing a developer's editing state (open files, cursor positions, terminal sessions).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developer can go from `docker compose up` to actively editing code in under 30 seconds cold start, under 5 seconds warm start.
- **SC-002**: IDE idle memory consumption (no extensions active, no files open) remains below 50MB.
- **SC-003**: IDE with one language server active maintains memory usage below 500MB.
- **SC-004**: Container image size remains below 1GB.
- **SC-005**: 100% of declared extensions (Python, TypeScript, Rust) install and activate successfully from Open VSX.
- **SC-006**: Extensions and settings persist across 100% of container restarts with zero manual intervention.
- **SC-007**: Container runs identically on arm64 and amd64 architectures with no platform-specific workarounds.
- **SC-008**: Unauthorized access attempts (missing or invalid token) are blocked 100% of the time.
- **SC-009**: Connection token never appears in server logs, Dockerfile, or image layers.
- **SC-010**: Container runs as non-root (UID 1000) with no privileged capabilities.

## Assumptions

- Developers have access to a modern web browser (Chrome, Firefox, Safari, Edge — latest 2 major versions).
- Docker or compatible container runtime is installed on the host machine.
- Network connectivity between browser and container is available (localhost for local development).
- The Open VSX registry provides equivalents for the most commonly used VS Code extensions for target languages (Python, TypeScript, Rust).
- Workspace files are mounted via Docker named volumes, providing real-time file synchronization between host and container.
- The container has at least 512MB of RAM allocated.
- HTTPS/TLS termination for secure remote access is handled by an external reverse proxy, not the IDE container itself.
- The connection token is generated externally (by the developer or tooling) and provided as an environment variable.
- The base container image (001-container-base) provides git, Python 3.14+, and Node.js 22.x.

## Dependencies

- **Requires**: 001-container-base-image (base container with Debian Bookworm-slim, development tools)
- **Requires**: 004-volume-architecture (workspace and extensions volume mounting strategy)
- **Blocks**: 009-ai-ide-extensions (AI coding assistants need the IDE platform selected)
- **Blocks**: 010-project-context-files (project context files depend on IDE choice)

## Out of Scope

- Native desktop application mode (IDE must be containerized and browser-accessible)
- HTTPS/TLS termination within the container (handled by external reverse proxy)
- Multi-user session isolation within a single container
- Live collaboration / pair programming features
- GPU passthrough for ML workloads
- X11/GUI application forwarding
- Microsoft VS Code Marketplace access (Open VSX only)
- Custom theme creation (standard themes from extensions are sufficient)
- OAuth or SSO authentication (token auth only for single-user)

## Security Considerations

- Connection token is the sole authentication mechanism — compromise grants full container access (shell, filesystem, environment variables)
- Extensions run with the same privileges as the server process — only install trusted extensions from the curated manifest
- Environment variables containing secrets are accessible to all processes in the container, including extensions
- No encryption at rest for workspace volume (acceptable for local development; requires separate assessment for remote access)
- No TLS for localhost communication (acceptable for local; HTTPS required via reverse proxy for remote access per S-4)
- Token passed as URL query parameter on initial connection — visible in browser history (acceptable for localhost; requires cookie-based auth for remote)
