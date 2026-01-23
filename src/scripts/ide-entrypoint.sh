#!/usr/bin/env bash
# IDE container entrypoint
# 1. Validates CONNECTION_TOKEN
# 2. Installs extensions from manifest (if available)
# 3. Launches OpenVSCode-Server as PID 1
set -euo pipefail

OPENVSCODE_BIN="/home/.openvscode-server/bin/openvscode-server"
EXTENSIONS_MANIFEST="/home/workspace/.vscode/extensions.json"
# Fallback to bundled manifest if workspace doesn't have one
BUNDLED_MANIFEST="/home/.openvscode-server/extensions.json"

# Validate CONNECTION_TOKEN
if [[ -z "${CONNECTION_TOKEN:-}" ]]; then
  echo "ERROR: CONNECTION_TOKEN environment variable is not set" >&2
  exit 1
fi

if [[ ${#CONNECTION_TOKEN} -lt 32 ]]; then
  echo "ERROR: CONNECTION_TOKEN must be at least 32 characters (got ${#CONNECTION_TOKEN})" >&2
  exit 1
fi

# Install extensions from manifest (T024)
install_extensions() {
  local manifest_file=""

  if [[ -f "${EXTENSIONS_MANIFEST}" ]]; then
    manifest_file="${EXTENSIONS_MANIFEST}"
  elif [[ -f "${BUNDLED_MANIFEST}" ]]; then
    manifest_file="${BUNDLED_MANIFEST}"
  else
    echo "INFO: No extensions manifest found, skipping auto-install"
    return 0
  fi

  echo "INFO: Installing extensions from ${manifest_file}..."

  # Parse recommendations array from JSON (simple grep-based, no jq dependency)
  local extensions
  extensions=$(grep -oE '"[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+"' "${manifest_file}" | tr -d '"' | sort -u)

  if [[ -z "${extensions}" ]]; then
    echo "INFO: No extensions found in manifest"
    return 0
  fi

  # Get currently installed extensions
  local installed
  installed=$("${OPENVSCODE_BIN}" --list-extensions 2>/dev/null || echo "")

  while IFS= read -r ext_id; do
    # Skip if already installed (idempotent - T028)
    if echo "${installed}" | grep -qi "^${ext_id}$"; then
      echo "INFO: Extension ${ext_id} already installed, skipping"
      continue
    fi

    echo "INFO: Installing extension: ${ext_id}"
    if ! "${OPENVSCODE_BIN}" --install-extension "${ext_id}" 2>&1; then
      # Handle Open VSX unavailability gracefully (T025)
      echo "WARN: Failed to install extension ${ext_id}, continuing startup" >&2
    fi
  done <<< "${extensions}"
}

install_extensions

# Launch OpenVSCode-Server as PID 1
exec "${OPENVSCODE_BIN}" \
  --host 0.0.0.0 \
  --port 3000 \
  --connection-token "${CONNECTION_TOKEN}"
