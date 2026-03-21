# Container Dev Env - Base Image
# A reproducible, multi-architecture development container
# Spec: specs/001-container-base-image/spec.md

# =============================================================================
# Stage 1: Python Base (Multi-stage for Python 3.14+)
# =============================================================================
# Python 3.14 is not available in Debian Bookworm repos
# Using official Python image as source for binaries
FROM python:3.14-slim-bookworm@sha256:f0540d0436a220db0a576ccfe75631ab072391e43a24b88972ef9833f699095f AS python-base

# =============================================================================
# Stage 2: Final Image
# =============================================================================
# Base image: Debian Bookworm-slim for glibc compatibility
# Pinned to specific date tag for reproducibility (constitution principle V)
FROM debian:bookworm-20260316-slim@sha256:f06537653ac770703bc45b4b113475bd402f451e85223f0f2837acbf89ab020a

# Build arguments for user configuration
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG TARGETARCH

# Environment configuration
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /home/${USERNAME}

# =============================================================================
# Phase 4/US2: Install common development tools
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    ca-certificates \
    curl \
    wget \
    gnupg \
    # Version control
    git \
    # JSON processing
    jq \
    # Build tools
    make \
    build-essential \
    # Sudo for privilege escalation
    sudo \
    # Locale support
    locales \
    # Archive extraction (tar.xz for Node.js)
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Phase 6/Locale: Configure UTF-8 locale
# =============================================================================
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# =============================================================================
# Phase 5/US3: Copy Python from python-base stage
# =============================================================================
COPY --from=python-base /usr/local /usr/local

# Ensure Python shared libraries are found
ENV LD_LIBRARY_PATH=/usr/local/lib

# =============================================================================
# uv package manager — Binary tarball with SHA256 verification
# Feature: 002-supply-chain-hardening (FR-002, FR-003)
# =============================================================================
ARG UV_VERSION=0.10.4
ARG UV_SHA256_AMD64=6b52a47358deea1c5e173278bf46b2b489747a59ae31f2a4362ed5c6c1c269f7
ARG UV_SHA256_ARM64=c84a6e6405715caa6e2f5ef8e5f29a5d0bc558a954e9f1b5c082b9d4708c222e
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
      amd64) UV_ARCH="x86_64"; CHECKSUM="${UV_SHA256_AMD64}" ;; \
      arm64) UV_ARCH="aarch64"; CHECKSUM="${UV_SHA256_ARM64}" ;; \
      *)     echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    TARBALL="uv-${UV_ARCH}-unknown-linux-gnu.tar.gz"; \
    curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${TARBALL}" \
      -o "/tmp/${TARBALL}"; \
    echo "${CHECKSUM}  /tmp/${TARBALL}" | sha256sum -c -; \
    tar -xzf "/tmp/${TARBALL}" -C /usr/local/bin --strip-components=1 \
      "uv-${UV_ARCH}-unknown-linux-gnu/uv" \
      "uv-${UV_ARCH}-unknown-linux-gnu/uvx"; \
    chmod +x /usr/local/bin/uv /usr/local/bin/uvx; \
    rm -f "/tmp/${TARBALL}"; \
    uv --version

# =============================================================================
# Node.js LTS (22.x) — Official tarball with SHA256 verification
# Feature: 002-supply-chain-hardening (FR-001, FR-003)
# =============================================================================
ARG NODEJS_VERSION=v22.22.0
ARG NODEJS_SHA256_AMD64=9aa8e9d2298ab68c600bd6fb86a6c13bce11a4eca1ba9b39d79fa021755d7c37
ARG NODEJS_SHA256_ARM64=1bf1eb9ee63ffc4e5d324c0b9b62cf4a289f44332dfef9607cea1a0d9596ba6f
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
      amd64) NODE_ARCH="x64";  CHECKSUM="${NODEJS_SHA256_AMD64}" ;; \
      arm64) NODE_ARCH="arm64"; CHECKSUM="${NODEJS_SHA256_ARM64}" ;; \
      *)     echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    TARBALL="node-${NODEJS_VERSION}-linux-${NODE_ARCH}.tar.xz"; \
    curl -fsSL "https://nodejs.org/dist/${NODEJS_VERSION}/${TARBALL}" \
      -o "/tmp/${TARBALL}"; \
    echo "${CHECKSUM}  /tmp/${TARBALL}" | sha256sum -c -; \
    tar -xJf "/tmp/${TARBALL}" -C /usr/local --strip-components=1 \
      --exclude='*/CHANGELOG.md' \
      --exclude='*/LICENSE' \
      --exclude='*/README.md'; \
    rm -f "/tmp/${TARBALL}"; \
    node --version; npm --version

# =============================================================================
# Chezmoi Installation for Dotfile Management
# Feature: 002-dotfile-management
# Spec: specs/002-dotfile-management/spec.md
# =============================================================================

# Install Chezmoi (pinned version for reproducibility - Constitution Principle V)
# Checksum verification per Feature 017 (Codebase Hardening)
ARG CHEZMOI_VERSION=v2.69.4
ARG CHEZMOI_SHA256_AMD64=5054cf09cb2993725f525c8bb6ec3ff8625489ecfc061e019c17e737e7c7057b
ARG CHEZMOI_SHA256_ARM64=560fb76182a3da7db7d445953cfa82fefbdc59284c8c673bb22363db9122ee4e
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

# Install age for encrypted dotfile support (FR-010)
# Checksum verification per Feature 017 (Codebase Hardening)
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

# =============================================================================
# Phase 3/US1 & Phase 7/US5: Create non-root user with sudo access
# =============================================================================
# UID/GID 1000 matches typical host user for volume mount compatibility
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
    mkdir -p /home/${USERNAME}/.local/bin /home/${USERNAME}/.cache /home/${USERNAME}/.npm-global && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.local /home/${USERNAME}/.cache /home/${USERNAME}/.npm-global

# =============================================================================
# Configure npm to use user-writable global directory
# =============================================================================
# This allows `npm install -g` to work without sudo
ENV NPM_CONFIG_PREFIX=/home/${USERNAME}/.npm-global
ENV PATH=/home/${USERNAME}/.local/bin:/home/${USERNAME}/.npm-global/bin:$PATH

# =============================================================================
# Phase 3/US1: Configure bash shell with sane defaults
# =============================================================================
# Bash configuration per clarification session:
# - Colored prompt for better UX
# - Command history 1000 lines
# - ll/la aliases (standard developer expectation)
# - Proper PATH including /usr/local/bin
RUN echo '\n\
# Container Dev Env - Bash Configuration\n\
\n\
# History configuration\n\
export HISTSIZE=1000\n\
export HISTFILESIZE=2000\n\
export HISTCONTROL=ignoredups:erasedups\n\
\n\
# Colored prompt\n\
PS1='"'"'\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '"'"'\n\
\n\
# Aliases\n\
alias ll='"'"'ls -alF'"'"'\n\
alias la='"'"'ls -A'"'"'\n\
alias l='"'"'ls -CF'"'"'\n\
\n\
# Enable color support\n\
if [ -x /usr/bin/dircolors ]; then\n\
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"\n\
    alias ls='"'"'ls --color=auto'"'"'\n\
    alias grep='"'"'grep --color=auto'"'"'\n\
fi\n\
\n\
# PATH configuration - includes user-local pip and npm global directories\n\
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:$PATH"\n\
\n\
# npm global prefix configuration\n\
export NPM_CONFIG_PREFIX="$HOME/.npm-global"\n\
' >> /home/${USERNAME}/.bashrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

# =============================================================================
# Phase 8: Health check script
# =============================================================================
COPY --chmod=755 scripts/health-check.sh /usr/local/bin/health-check.sh

# Health check for orchestration tools (FR-010)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/usr/local/bin/health-check.sh"]

# =============================================================================
# Final configuration
# =============================================================================
# Switch to non-root user (FR-002: security best practice)
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Default shell
ENV SHELL=/bin/bash

# Default command
CMD ["/bin/bash"]
