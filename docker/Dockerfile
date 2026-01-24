# =============================================================================
# Development Container - Volume Architecture
# Feature: 004-volume-architecture
# =============================================================================
# Multi-stage Dockerfile for development containers with optimized volume mounts
# Supports: macOS (VirtioFS), Linux (native), arm64 + amd64
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Base image with system dependencies
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS base

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    ca-certificates \
    curl \
    wget \
    git \
    # Build tools
    build-essential \
    # Python runtime
    python3 \
    python3-pip \
    python3-venv \
    # Shell and utilities
    bash \
    sudo \
    # Process management
    procps \
    # JSON processing
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS (22.x) via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Chezmoi for dotfile management (pinned for reproducibility)
ARG CHEZMOI_VERSION=v2.47.1
ARG CHEZMOI_SHA256_AMD64=2e13820f7c93f522823070538425e72ad2b6186322c70e4188efb2da38166f7c
ARG CHEZMOI_SHA256_ARM64=bf1d042f62f8d80b238f20d135b5e413981089f429668ff7039128ee32b957a6
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
      amd64) CHECKSUM="${CHEZMOI_SHA256_AMD64}" ;; \
      arm64) CHECKSUM="${CHEZMOI_SHA256_ARM64}" ;; \
      *)     echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    CHEZMOI_VER=$(echo "${CHEZMOI_VERSION}" | sed 's/^v//'); \
    TARBALL="chezmoi_${CHEZMOI_VER}_linux_${ARCH}.tar.gz"; \
    curl -fsSL "https://github.com/twpayne/chezmoi/releases/download/${CHEZMOI_VERSION}/${TARBALL}" \
      -o "/tmp/${TARBALL}"; \
    echo "${CHECKSUM}  /tmp/${TARBALL}" | sha256sum -c -; \
    tar -xzf "/tmp/${TARBALL}" -C /usr/local/bin chezmoi; \
    chmod +x /usr/local/bin/chezmoi; \
    rm -f "/tmp/${TARBALL}"

# Install age for encrypted dotfile support
ARG AGE_VERSION=v1.1.1
ARG AGE_SHA256_AMD64=cf16cbb108fc56e2064b00ba2b65d9fb1b8d7002ca5e38260ee1cc34f6aaa8f9
ARG AGE_SHA256_ARM64=f0dbf4364f5ba44e37ad85af9fdd3716bd410018ce344d317b174d206b03e6fc
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
      amd64) CHECKSUM="${AGE_SHA256_AMD64}" ;; \
      arm64) CHECKSUM="${AGE_SHA256_ARM64}" ;; \
      *)     echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    TARBALL="age-${AGE_VERSION}-linux-${ARCH}.tar.gz"; \
    curl -fsSL "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/${TARBALL}" \
      -o "/tmp/${TARBALL}"; \
    echo "${CHECKSUM}  /tmp/${TARBALL}" | sha256sum -c -; \
    tar -xzf "/tmp/${TARBALL}" -C /usr/local/bin --strip-components=1 age/age age/age-keygen; \
    chmod +x /usr/local/bin/age /usr/local/bin/age-keygen; \
    rm -f "/tmp/${TARBALL}"

# -----------------------------------------------------------------------------
# Stage 2: Development image with non-root user
# -----------------------------------------------------------------------------
FROM base AS development

# Build arguments for user configuration
# Default UID/GID can be overridden at runtime via LOCAL_UID/LOCAL_GID
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# Create non-root user with sudo access
# UID/GID 1000 is standard for first user on Linux
# macOS uses 501 - handled by entrypoint.sh at runtime
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Create standard directories that will be volume mount points
# These are created here so they have correct ownership if volumes are not mounted
RUN mkdir -p /workspace \
    && mkdir -p /home/${USERNAME}/.npm \
    && mkdir -p /home/${USERNAME}/.cache/pip \
    && mkdir -p /home/${USERNAME}/.cargo/registry \
    && chown -R ${USERNAME}:${USERNAME} /workspace \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# Copy entrypoint script
COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

# Health check script (for container health validation)
COPY --chmod=755 scripts/health-check.sh /usr/local/bin/health-check.sh

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Switch to non-root user
USER ${USERNAME}

# Set working directory
WORKDIR /workspace

# Default environment variables
ENV HOME=/home/${USERNAME}
ENV USER=${USERNAME}

# Entrypoint handles UID mapping and volume validation
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command - interactive bash shell
CMD ["/bin/bash", "-l"]

# -----------------------------------------------------------------------------
# Stage 3: MCP (Model Context Protocol) server installation
# Feature: 012-mcp-integration
# -----------------------------------------------------------------------------
FROM development AS mcp

# Build argument for optional Playwright Chromium browser installation
ARG INSTALL_PLAYWRIGHT_BROWSER=false

# Switch to root for system-level installations
USER root

# T004: Install Node.js 22.x LTS via NodeSource apt repository
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# T006: Install python3-yaml for YAML generation and pip for Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-yaml \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# T005: Configure NPM_CONFIG_PREFIX for non-root global installs
ENV NPM_CONFIG_PREFIX=/home/dev/.npm-global
ENV PATH="${NPM_CONFIG_PREFIX}/bin:${PATH}"

# Create the npm-global directory with correct ownership
RUN mkdir -p /home/dev/.npm-global \
    && chown -R dev:dev /home/dev/.npm-global

# Switch to non-root user for npm installations
USER dev

# T007: Install core MCP packages with pinned versions
# All versions pinned per Constitution Principle V (Reproducibility)
RUN npm install -g \
    @modelcontextprotocol/server-filesystem@2026.1.14 \
    @modelcontextprotocol/server-memory@2026.1.14 \
    @modelcontextprotocol/server-sequential-thinking@2026.1.14 \
    @upstash/context7-mcp@2.1.0

# T008: Install optional MCP packages
RUN npm install -g \
    @modelcontextprotocol/server-github@2026.1.14 \
    @playwright/mcp@0.0.28

# Switch back to root for pip install and file operations
USER root

# T009: Install Python-based git MCP server
RUN pip install --no-cache-dir --break-system-packages mcp-server-git

# Optional: Install Playwright Chromium browser if requested
RUN if [ "${INSTALL_PLAYWRIGHT_BROWSER}" = "true" ]; then \
        npx --yes playwright install --with-deps chromium; \
    fi

# T020: Create memory volume mount directory
RUN mkdir -p /home/dev/.local/share/mcp-memory \
    && chown -R dev:dev /home/dev/.local/share/mcp-memory

# T019: Copy MCP configuration files
COPY --chown=dev:dev src/mcp/ /home/dev/.mcp/

# Switch back to non-root user
USER dev

# Set working directory
WORKDIR /workspace

# Entrypoint handles UID mapping and volume validation
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command - interactive bash shell
CMD ["/bin/bash", "-l"]
