# Memory system container layer
# Python 3.12 required: onnxruntime/fastembed lack 3.14 wheels
# Multi-arch: arm64 + amd64 (pre-built wheels available)
FROM python:3.12-slim-bookworm

# Security: run as non-root user
# UID/GID 1000 matches typical host user for volume mounts
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

# Install system dependencies for sqlite-vec
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies from lockfile
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install --no-cache-dir uv \
    && uv pip install --system --no-cache . \
    && pip uninstall -y uv

# Copy source code
COPY src/ ./src/

# Install the package
RUN pip install --no-cache-dir --no-deps .

# Health check script
COPY src/docker/healthcheck.py /usr/local/bin/healthcheck.py
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python /usr/local/bin/healthcheck.py || exit 1

# Switch to non-root user
USER ${USERNAME}

# Default environment variables
ENV MEMORY_DB_PATH="/home/${USERNAME}/.local/share/ai-memory/projects"
ENV MEMORY_LOG_LEVEL="INFO"
ENV MEMORY_SOURCE_TOOL="unknown"

# Entry point
COPY src/docker/memory-entrypoint.sh /usr/local/bin/memory-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/memory-entrypoint.sh"]
