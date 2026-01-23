#!/usr/bin/env bash
# bridge-secrets.sh — Bridge OS environment variables to ~/.continue/.env
# Called at container startup to populate Continue's secrets file
# Per Contract 3: skip missing optional keys, error if no keys at all
set -euo pipefail

CONTINUE_DIR="${HOME}/.continue"
ENV_FILE="${CONTINUE_DIR}/.env"

mkdir -p "${CONTINUE_DIR}"

KEY_COUNT=0
ENV_CONTENT=""

# Bridge each supported key if set and non-empty (trim whitespace)
for VAR_NAME in ANTHROPIC_API_KEY OPENAI_API_KEY MISTRAL_API_KEY; do
    VALUE="${!VAR_NAME:-}"
    # Skip unset, empty, or whitespace-only values
    TRIMMED=$(echo "${VALUE}" | tr -d '[:space:]')
    if [[ -n "${TRIMMED}" ]]; then
        ENV_CONTENT="${ENV_CONTENT}${VAR_NAME}=${VALUE}\n"
        KEY_COUNT=$((KEY_COUNT + 1))
    fi
done

if [[ "${KEY_COUNT}" -eq 0 ]]; then
    echo "[bridge-secrets] ERROR: No API keys found in environment." >&2
    echo "[bridge-secrets] Set at least one of: ANTHROPIC_API_KEY, OPENAI_API_KEY, MISTRAL_API_KEY" >&2
    exit 1
fi

# Write .env file with restrictive permissions
printf '%b' "${ENV_CONTENT}" > "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

echo "[bridge-secrets] Bridged ${KEY_COUNT} API key(s) to ${ENV_FILE}"
