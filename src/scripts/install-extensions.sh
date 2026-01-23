#!/usr/bin/env bash
# install-extensions.sh — Download and install pinned VSIX extensions
# Called during Docker build to pre-install IDE extensions
set -euo pipefail

CONTINUE_VERSION="1.2.14"
CLINE_VERSION="3.51.0"

CONTINUE_URL="https://open-vsx.org/api/Continue/continue/${CONTINUE_VERSION}/file/Continue.continue-${CONTINUE_VERSION}.vsix"
CLINE_URL="https://open-vsx.org/api/saoudrizwan/claude-dev/${CLINE_VERSION}/file/saoudrizwan.claude-dev-${CLINE_VERSION}.vsix"

VSIX_DIR="/tmp"

echo "[install-extensions] Downloading Continue v${CONTINUE_VERSION}..."
curl -fsSL -o "${VSIX_DIR}/continue.vsix" "${CONTINUE_URL}"

echo "[install-extensions] Downloading Cline v${CLINE_VERSION}..."
curl -fsSL -o "${VSIX_DIR}/cline.vsix" "${CLINE_URL}"

echo "[install-extensions] Installing Continue extension..."
openvscode-server --install-extension "${VSIX_DIR}/continue.vsix"

echo "[install-extensions] Installing Cline extension..."
openvscode-server --install-extension "${VSIX_DIR}/cline.vsix"

echo "[install-extensions] Cleaning up VSIX files..."
rm -f "${VSIX_DIR}/continue.vsix" "${VSIX_DIR}/cline.vsix"

echo "[install-extensions] Extensions installed successfully."
