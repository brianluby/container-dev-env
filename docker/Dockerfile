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
FROM debian:bookworm-slim@sha256:98f4b71de414932439ac6ac690d7060df1f27161073c5036a7553723881bffbe AS base

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

# Install Node.js LTS (22.x) via NodeSource without using curl | bash
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gnupg; \
    NODE_MAJOR=22; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends nodejs; \
    rm -rf /var/lib/apt/lists/*

# Install Chezmoi for dotfile management (pinned for reproducibility)
ARG CHEZMOI_VERSION=v2.69.3
ARG CHEZMOI_SHA256_AMD64=9b9bf911efed8aba28bd6f5df1e780a6123dc3fb177004c1ca36ec2b9eca7628
ARG CHEZMOI_SHA256_ARM64=0aef9ef75ee33cffb483a82c474b495d428e0f7941ab7898263c3519006e0662
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
ARG AGE_VERSION=v1.3.1
ARG AGE_SHA256_AMD64=bdc69c09cbdd6cf8b1f333d372a1f58247b3a33146406333e30c0f26e8f51377
ARG AGE_SHA256_ARM64=c6878a324421b69e3e20b00ba17c04bc5c6dab0030cfe55bf8f68fa8d9e9093a
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

# Note: Node.js 22.x LTS is already installed in the base stage

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
    @playwright/mcp@0.0.58

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
