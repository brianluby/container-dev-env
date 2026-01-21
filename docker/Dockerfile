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
    # Shell and utilities
    bash \
    sudo \
    # Process management
    procps \
    # JSON processing
    jq \
    && rm -rf /var/lib/apt/lists/*

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
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

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
