# =============================================================================
# Spike 011: MCP Integration Test Image
# Purpose: Test MCP server installation and configuration in containers
# =============================================================================

# Use the project's base image as foundation
FROM debian:bookworm-20250113-slim

# Build arguments
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG TARGETARCH

# Environment configuration
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# Phase 1: System dependencies
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
    # Build tools (for native npm packages)
    make \
    build-essential \
    python3 \
    # Sudo for privilege escalation
    sudo \
    # Locale support
    locales \
    && rm -rf /var/lib/apt/lists/*

# Configure UTF-8 locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# =============================================================================
# Phase 2: Install Node.js LTS (22.x) - Required for MCP servers
# =============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Phase 3: Create non-root user
# =============================================================================
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# Create directories for npm global packages and MCP configuration
RUN mkdir -p /home/${USERNAME}/.npm-global \
             /home/${USERNAME}/.local/bin \
             /home/${USERNAME}/.config/claude-code \
             /home/${USERNAME}/.mcp \
             /workspace && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} /workspace

# Configure npm global prefix
ENV NPM_CONFIG_PREFIX=/home/${USERNAME}/.npm-global
ENV PATH=/home/${USERNAME}/.local/bin:/home/${USERNAME}/.npm-global/bin:$PATH

# =============================================================================
# Phase 4: Install MCP Servers (as non-root user)
# =============================================================================
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install MCP servers globally via npm
# These are the core servers identified in the PRD
RUN npm install -g \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-memory \
    @modelcontextprotocol/server-sequential-thinking \
    @upstash/context7-mcp

# =============================================================================
# Phase 5: MCP Configuration
# =============================================================================
# Copy MCP configuration template
COPY --chown=${USERNAME}:${USERNAME} config/mcp-config.json /home/${USERNAME}/.mcp/config.json

# Copy health check and test scripts
COPY --chown=${USERNAME}:${USERNAME} scripts/ /home/${USERNAME}/scripts/
RUN chmod +x /home/${USERNAME}/scripts/*.sh

# =============================================================================
# Phase 6: Shell configuration
# =============================================================================
RUN echo '\n\
# MCP Integration Spike - Bash Configuration\n\
export HISTSIZE=1000\n\
export HISTCONTROL=ignoredups:erasedups\n\
PS1='"'"'\[\033[01;32m\]\u@mcp-test\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '"'"'\n\
alias ll='"'"'ls -alF'"'"'\n\
alias la='"'"'ls -A'"'"'\n\
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:$PATH"\n\
export NPM_CONFIG_PREFIX="$HOME/.npm-global"\n\
' >> /home/${USERNAME}/.bashrc

# =============================================================================
# Final configuration
# =============================================================================
WORKDIR /workspace
ENV SHELL=/bin/bash

# Health check for MCP server availability
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/home/dev/scripts/health-check-mcp.sh"]

CMD ["/bin/bash"]
