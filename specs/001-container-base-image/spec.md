# Feature Specification: Container Base Image

**Feature Branch**: `001-container-base-image`
**Created**: 2026-01-20
**Status**: Draft
**Input**: User description: "prds/001-prd-container-base.md"

## Clarifications

### Session 2026-01-20

- Q: What should the default non-root username be? → A: `dev` (short, common convention for dev containers)
- Q: What bash "sane defaults" should be included? → A: Standard set (colored prompt, command history 1000 lines, aliases ll/la, proper PATH)
- Q: Image security update strategy? → A: Weekly automated CI rebuild with latest base image

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build and Run Development Container (Priority: P1)

A developer wants to create a reproducible development environment that works identically on their local machine (Mac or Linux) and in CI pipelines. They build the container image and run it to perform development tasks with pre-installed tools.

**Why this priority**: This is the core functionality - without a buildable, runnable container, no other features matter. Establishes the foundation for all subsequent development tooling.

**Independent Test**: Can be fully tested by building the Dockerfile and running basic commands inside the container. Delivers immediate value of a working isolated environment.

**Acceptance Scenarios**:

1. **Given** a clean Docker host, **When** I run `docker build -t devcontainer .`, **Then** the build completes without error
2. **Given** the built image, **When** I run `docker run --rm devcontainer whoami`, **Then** output shows `dev`
3. **Given** the built image, **When** I run `docker run --rm devcontainer bash -c "echo test"`, **Then** bash executes successfully with sane defaults

---

### User Story 2 - Use Common Development Tools (Priority: P1)

A developer needs to use common development tools (git, curl, wget, jq, make, build-essential) inside the container without manual installation. They expect these tools to be available immediately upon container start.

**Why this priority**: Development tools are essential for any productive work inside the container. Without them, the container provides no value over a raw OS.

**Independent Test**: Can be tested by running version commands for each tool inside the container. Delivers value of immediate tool availability.

**Acceptance Scenarios**:

1. **Given** the built image, **When** I run `docker run --rm devcontainer git --version`, **Then** git responds with its version
2. **Given** the built image, **When** I run `docker run --rm devcontainer curl --version`, **Then** curl is available
3. **Given** the built image, **When** I run `docker run --rm devcontainer jq --version`, **Then** jq is available
4. **Given** the built image, **When** I run `docker run --rm devcontainer make --version`, **Then** make is available

---

### User Story 3 - Develop with Python and Node.js (Priority: P2)

A developer wants to write and run Python and Node.js applications inside the container. They need modern versions of these runtimes with their package managers (pip/uv for Python, npm for Node.js).

**Why this priority**: Python and Node.js are the most common languages for AI/ML development and web tooling respectively. Supporting them enables the majority of development workflows.

**Independent Test**: Can be tested by running language version checks and installing a simple package. Delivers value of language runtime availability.

**Acceptance Scenarios**:

1. **Given** the built image, **When** I run `docker run --rm devcontainer python3 --version`, **Then** Python 3.14+ responds
2. **Given** the built image, **When** I run `docker run --rm devcontainer pip --version`, **Then** pip is available
3. **Given** the built image, **When** I run `docker run --rm devcontainer node --version`, **Then** Node.js 22.x responds
4. **Given** the built image, **When** I run `docker run --rm devcontainer npm --version`, **Then** npm is available

---

### User Story 4 - Build on Multiple Architectures (Priority: P2)

A developer working on Apple Silicon (arm64) or Intel/AMD (amd64) machines needs the same container to build and run correctly on their hardware. CI pipelines running on different architectures should also work.

**Why this priority**: Multi-architecture support is essential for team collaboration where developers use different hardware. Without it, "works on my machine" problems persist.

**Independent Test**: Can be tested by building on both arm64 and amd64 hosts. Delivers value of cross-platform compatibility.

**Acceptance Scenarios**:

1. **Given** an arm64 host (Apple Silicon), **When** I build the image, **Then** the build completes successfully
2. **Given** an amd64 host (Intel/AMD), **When** I build the image, **Then** the build completes successfully
3. **Given** a multi-arch build command, **When** I use docker buildx for arm64 and amd64, **Then** both architectures build successfully

---

### User Story 5 - Perform Privileged Operations When Needed (Priority: P3)

A developer occasionally needs to install additional packages or perform system administration tasks inside the container. They should be able to use sudo to elevate privileges when necessary.

**Why this priority**: While running as non-root is the default for security, sudo access allows flexibility for edge cases without rebuilding the image.

**Independent Test**: Can be tested by running a sudo command inside the container. Delivers value of administrative flexibility.

**Acceptance Scenarios**:

1. **Given** the built image, **When** I run `docker run --rm devcontainer sudo apt-get update`, **Then** the command executes successfully
2. **Given** the built image, **When** I run `docker run --rm devcontainer sudo whoami`, **Then** output shows "root"

---

### Edge Cases

- What happens when the Docker daemon is not running? Build fails with clear Docker error message.
- What happens when disk space is insufficient? Build fails with out-of-space error from Docker.
- What happens when network is unavailable during build? Build fails at package download step with network error.
- What happens when building on unsupported architecture? Build may fail or use emulation with performance degradation.
- How does the container handle missing locale settings? Pre-configured UTF-8 locale prevents encoding issues.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST produce a working development container from a single Dockerfile
- **FR-002**: Container MUST run as a non-root user by default for security
- **FR-003**: Container user MUST have sudo access for administrative tasks
- **FR-004**: Container MUST include git, curl, wget, jq, make, and build-essential tools
- **FR-005**: Container MUST provide bash shell with sane defaults (colored prompt, command history with 1000 lines, `ll`/`la` aliases, proper PATH)
- **FR-006**: Container MUST support arm64 (Apple Silicon) and amd64 architectures
- **FR-007**: Container MUST use a base image with MIT-compatible licensing
- **FR-008**: Container SHOULD include Python 3.14+ with pip and uv package managers
- **FR-009**: Container SHOULD include Node.js LTS (22.x) with npm package manager
- **FR-010**: Container SHOULD support a health check mechanism for orchestration tools
- **FR-011**: Container COULD include Go toolchain pre-installed
- **FR-012**: Container COULD include Rust toolchain pre-installed
- **FR-013**: Container MUST have UTF-8 locale pre-configured
- **FR-014**: Container image SHOULD be rebuilt weekly via automated CI to incorporate security updates from base image

### Key Entities

- **Container Image**: The built Docker image containing the development environment. Key attributes: base OS (Debian Bookworm-slim), installed tools, default user, architecture support.
- **Developer User**: The non-root user account inside the container. Key attributes: username (`dev`), home directory (`/home/dev`), sudo privileges, shell configuration.
- **Dockerfile**: The build specification that defines how the container is constructed. Key attributes: base image reference, package installations, user setup, environment configuration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can build the container image in under 5 minutes on CI systems
- **SC-002**: Built container image size is under 2GB (compressed)
- **SC-003**: All required development tools are immediately available without additional installation
- **SC-004**: Container works identically on arm64 and amd64 machines
- **SC-005**: Python packages with native extensions (numpy, pandas) install successfully
- **SC-006**: Node packages with native extensions (typescript, eslint) install successfully
- **SC-007**: All container components pass license audit for MIT-compatibility
- **SC-008**: Container starts and responds to commands in under 5 seconds

## Assumptions

- Docker or a compatible container runtime (Podman, etc.) is available on the host machine
- Network access is available during container build for package downloads
- The host machine has sufficient disk space (at least 5GB free) for the build process
- Developers are familiar with basic Docker commands (build, run, exec)
- The base image (Debian Bookworm-slim) will continue to receive security updates
- Weekly CI rebuilds will pull latest base image to incorporate upstream security patches
- Python 3.14+ is required for this feature (exceeds constitution minimum of 3.11+); installed via official Docker image
- Node.js 22.x is the current LTS version; installed via NodeSource repository

## Scope Boundaries

### In Scope

- Single Dockerfile for building the development container
- Core development tools (git, curl, wget, jq, make, build-essential)
- Python and Node.js runtime environments
- Non-root user with sudo access
- Multi-architecture support (arm64, amd64)
- Bash shell configuration
- UTF-8 locale configuration

### Out of Scope

- GUI applications or desktop environment
- IDE or editor installation (covered in separate PRD)
- AI/ML specific tools (covered in separate PRD)
- Dotfile management (covered in 002-prd-dotfile-management)
- Secret injection (covered in 003-prd-secret-injection)
- Volume architecture (covered in 004-prd-volume-architecture)
- Alpine-based minimal variant (future consideration)

## Dependencies

- **Requires**: None - this is the foundation layer
- **Blocks**: 002-prd-dotfile-management, 003-prd-secret-injection, 004-prd-volume-architecture
