# OpenCode AI Agent Installation Stage
#
# This Dockerfile stage downloads, verifies, and installs the OpenCode binary.
# It is intended to be included in the main container image build as an additional stage.
#
# Usage:
#   Include this as a stage in the parent Dockerfile or use COPY --from to extract the binary.
#
# Required build args:
#   OPENCODE_VERSION       — Release tag (e.g., v0.1.0)
#   OPENCODE_SHA256_AMD64  — SHA256 checksum for linux/amd64 binary
#   OPENCODE_SHA256_ARM64  — SHA256 checksum for linux/arm64 binary
#
# Provides:
#   /usr/local/bin/opencode — Verified, executable binary

ARG OPENCODE_VERSION=v0.1.0
# NOTE: The following SHA256 values are placeholders only.
# Obtain the real checksums from the corresponding OpenCode GitHub release, e.g.:
#   curl -fsSL "https://github.com/opencode-ai/opencode/releases/download/${OPENCODE_VERSION}/opencode-linux-amd64" | sha256sum
#   curl -fsSL "https://github.com/opencode-ai/opencode/releases/download/${OPENCODE_VERSION}/opencode-linux-arm64" | sha256sum
# Then set OPENCODE_SHA256_AMD64 / OPENCODE_SHA256_ARM64 via build args or update the defaults below.
ARG OPENCODE_SHA256_AMD64=placeholder_amd64_sha256
ARG OPENCODE_SHA256_ARM64=placeholder_arm64_sha256

FROM debian:bookworm-slim AS opencode-install

ARG OPENCODE_VERSION
ARG OPENCODE_SHA256_AMD64
ARG OPENCODE_SHA256_ARM64
ARG TARGETARCH

RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*; \
    case "${TARGETARCH}" in \
      amd64) SHA="${OPENCODE_SHA256_AMD64}" ;; \
      arm64) SHA="${OPENCODE_SHA256_ARM64}" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/opencode-ai/opencode/releases/download/${OPENCODE_VERSION}/opencode-linux-${TARGETARCH}" \
      -o /usr/local/bin/opencode; \
    echo "${SHA}  /usr/local/bin/opencode" | sha256sum -c -; \
    chmod +x /usr/local/bin/opencode

# Session directory with correct permissions
RUN mkdir -p /root/.local/share/opencode/sessions && \
    chmod 0700 /root/.local/share/opencode/sessions
