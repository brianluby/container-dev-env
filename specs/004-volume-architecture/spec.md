# Feature Specification: Volume Architecture for Development Containers

**Feature Branch**: `004-volume-architecture`
**Created**: 2026-01-20
**Status**: Draft
**Input**: PRD 004-prd-volume-architecture.md - Hybrid volume architecture with bind mounts and named volumes

## Clarifications

### Session 2026-01-20

- Q: How should UID/permission conflicts between host and container be resolved? → A: Dynamic UID detection at container start
- Q: What should happen if a named volume is missing or corrupted at startup? → A: Log warning and create fresh volume, continue startup
- Q: What should happen when workspace bind mount path doesn't exist on host? → A: Fail fast with clear error message
- Q: What debugging signals should be available for troubleshooting volume issues? → A: Entrypoint logs volume mount status, UID mapping, and warnings at startup
- Q: How should concurrent access to the same named volume by multiple containers be handled? → A: Document as unsupported, single-container only

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Source Code Editing from Host (Priority: P1)

A developer needs to edit source code using their preferred IDE on the host machine while the container runs the development environment. Changes made on the host must be immediately visible in the container, and vice versa.

**Why this priority**: This is the fundamental development workflow - without bidirectional file access, the container is unusable for active development.

**Independent Test**: Can be tested by editing a file on the host and verifying it appears in the container within 1 second, then editing in the container and verifying it appears on the host.

**Acceptance Scenarios**:

1. **Given** a container with workspace mounted, **When** I edit a file on the host, **Then** the change is visible in the container within 1 second
2. **Given** a container with workspace mounted, **When** I create a file in the container, **Then** the file is visible on the host immediately
3. **Given** a file edited in the container, **When** I check file permissions on the host, **Then** my host user can read and write the file

---

### User Story 2 - Persistent Development Environment (Priority: P1)

A developer expects their shell history, configuration, and installed tools to persist across container restarts. Stopping and starting the container should feel like resuming work, not starting fresh.

**Why this priority**: Without persistence, developers waste time reconfiguring their environment after every restart, breaking the mental model of a stable workspace.

**Independent Test**: Can be tested by customizing shell history and config, restarting the container, and verifying all customizations remain.

**Acceptance Scenarios**:

1. **Given** I have run commands in the container, **When** I restart the container, **Then** my shell history is preserved
2. **Given** I have modified my dotfiles in the container, **When** I restart the container, **Then** my dotfile changes persist
3. **Given** I have installed a tool in my home directory, **When** I restart the container, **Then** the tool is still available

---

### User Story 3 - Fast Dependency Installation (Priority: P1)

A developer running npm install, pip install, or cargo build needs operations to complete quickly. Dependency installation should not be noticeably slower than running on a native machine.

**Why this priority**: Slow dependency installation is the primary complaint about containerized development on macOS - it must be addressed for adoption.

**Independent Test**: Can be tested by timing npm install with 50+ packages and verifying it completes within 10 seconds.

**Acceptance Scenarios**:

1. **Given** a project with 50+ npm dependencies, **When** I run npm install, **Then** it completes within 10 seconds
2. **Given** cached dependencies exist, **When** I run npm install again, **Then** it completes within 2 seconds
3. **Given** a project with pip dependencies, **When** I run pip install, **Then** cached packages are reused across sessions

---

### User Story 4 - Clean Temporary Storage (Priority: P2)

A developer wants temporary files and build intermediates to be automatically cleaned up on container restart. The /tmp directory should start fresh to avoid stale file issues.

**Why this priority**: Ephemeral storage prevents accumulation of stale files and ensures reproducible builds, but is less critical than persistence.

**Independent Test**: Can be tested by creating files in /tmp, restarting the container, and verifying /tmp is empty.

**Acceptance Scenarios**:

1. **Given** files created in /tmp, **When** I restart the container, **Then** /tmp is empty
2. **Given** a running container, **When** I write large temporary files, **Then** they do not consume persistent storage
3. **Given** build tools using /tmp, **When** I run a build, **Then** intermediate files are automatically cleaned on restart

---

### User Story 5 - Safe Pruning and Recovery (Priority: P2)

A developer running docker system prune to reclaim disk space must not lose their source code. The volume architecture must protect critical data from accidental deletion.

**Why this priority**: Data safety is critical, but this is a less frequent operation than daily development tasks.

**Independent Test**: Can be tested by running docker system prune and verifying source code and essential configuration remain intact.

**Acceptance Scenarios**:

1. **Given** source code in the workspace, **When** I run docker system prune, **Then** my source code is not deleted
2. **Given** named volumes for caches, **When** I run docker system prune, **Then** I am warned before cache deletion
3. **Given** home directory in a named volume, **When** I run docker volume prune, **Then** I must explicitly confirm deletion

---

### User Story 6 - New Developer Onboarding (Priority: P3)

A new developer joining a project needs to understand what data persists and what resets. Documentation must be clear enough to avoid data loss surprises within the first day.

**Why this priority**: Good documentation is important but less urgent than core functionality.

**Independent Test**: Can be tested by having a new user read the documentation and correctly predict persistence behavior for 5 scenarios.

**Acceptance Scenarios**:

1. **Given** the volume documentation, **When** a new developer reads it, **Then** they understand the persistence model in under 5 minutes
2. **Given** the docker-compose configuration, **When** a developer reads it, **Then** the volume purpose is clear from comments
3. **Given** questions about data persistence, **When** a developer checks the documentation, **Then** they find answers for common scenarios

---

### Edge Cases

- What happens when the host disk is full during a large npm install?
- How are permission conflicts handled when host UID differs from container UID? → Dynamic UID detection at container start
- What happens if a developer manually deletes a named volume that is still referenced? → Log warning, create fresh volume, continue startup
- How does the system behave when bind mount paths don't exist on the host? → Fail fast with clear error message
- What happens when two containers try to use the same named volume simultaneously? → Unsupported; document as single-container only

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST mount workspace directory as a bind mount for host access
- **FR-002**: System MUST persist home directory contents across container restarts
- **FR-003**: System MUST persist package manager caches (npm, pip) for performance
- **FR-004**: System MUST use ephemeral storage for /tmp that resets on restart
- **FR-005**: System MUST detect host UID dynamically and adjust container user permissions at startup
- **FR-006**: System MUST allow files created in container to be readable/writable by host user
- **FR-007**: System MUST protect source code from docker system prune
- **FR-008**: System MUST work with VS Code devcontainer configurations
- **FR-009**: System MUST work with docker-compose configurations
- **FR-010**: System MUST document which paths persist and which reset
- **FR-011**: System MUST support concurrent file access from host and container
- **FR-012**: System MUST log warning and create fresh volume when named volumes are missing, continuing startup without blocking
- **FR-013**: System MUST fail fast with clear error message when workspace bind mount path does not exist on host
- **FR-014**: System MUST log volume mount status, detected UID, and any warnings at container startup for debugging

### Key Entities

- **Workspace Volume**: Bind-mounted directory containing source code. Bidirectional sync between host and container. Protected from pruning.
- **Home Volume**: Named volume containing user configuration, shell history, and local tools. Persists across restarts, survives image updates.
- **Cache Volume**: Named volume(s) for package manager caches. Improves performance, can be safely pruned without data loss.
- **Ephemeral Storage**: tmpfs mount for temporary files. Fast, memory-backed, automatically cleared on restart.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: File changes sync between host and container within 1 second
- **SC-002**: npm install with 50+ packages completes in under 10 seconds (vs 60+ seconds on bind mount)
- **SC-003**: Container startup with permission fix completes in under 3 seconds
- **SC-004**: Source code survives docker system prune in 100% of cases
- **SC-005**: New developers understand persistence model within 5 minutes of reading documentation
- **SC-006**: Volume configuration in docker-compose.yml is under 15 lines
- **SC-007**: Shell history and dotfiles persist across 100% of container restarts
- **SC-008**: Temporary files in /tmp are cleared on 100% of container restarts

## Assumptions

- Host user UID is detected dynamically at container start (supports macOS UID 501, Linux UID 1000+)
- Docker Desktop is used on macOS (VirtioFS or gRPC-FUSE for bind mounts)
- Developers use docker-compose or VS Code devcontainers (not raw docker run)
- Source code directories exist on host before container starts
- Named volumes are local Docker volumes (not network-attached)
- Container runs as non-root user (dev with dynamic UID) for security
- Named volumes are single-container only; concurrent multi-container access is unsupported
