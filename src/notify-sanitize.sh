#!/usr/bin/env bash
# notify-sanitize.sh — Content sanitization functions for notify.sh
# Sourced by notify.sh before sending notifications
# See: specs/016-mobile-access/data-model.md ContentSanitizer

# Sanitize notification message content
# Processing order per data-model.md:
#   1. Strip file paths
#   2. Strip API key patterns
#   3. Strip env var assignments
#   4. Strip code pattern lines
#   5. Collapse whitespace
#   6. Truncate to 200 chars
sanitize_message() {
  local msg="${1:-}"

  if [[ -z "${msg}" ]]; then
    echo ""
    return 0
  fi

  # 1. Strip absolute file paths: /path/to/file.ext
  msg="$(echo "${msg}" | sed -E 's|/[a-zA-Z0-9_/.~-]+||g')"

  # 2. Strip API key patterns
  # sk-<alphanumeric>
  msg="$(echo "${msg}" | sed -E 's/sk-[a-zA-Z0-9]+//g')"
  # tk_<alphanumeric>
  msg="$(echo "${msg}" | sed -E 's/tk_[a-z0-9]+//g')"
  # 20+ uppercase chars (likely API keys)
  msg="$(echo "${msg}" | sed -E 's/[A-Z0-9]{20,}//g')"

  # 3. Strip env var assignments: KEY=value
  msg="$(echo "${msg}" | sed -E 's/[A-Z_]+=[^ ]+//g')"

  # 4. Strip code pattern lines (lines containing code indicators)
  # Remove content with curly braces, semicolons, or code keywords
  msg="$(echo "${msg}" | sed -E '/\{/d; /\}/d; /;/d')"
  msg="$(echo "${msg}" | sed -E 's/.*function .*//g')"
  msg="$(echo "${msg}" | sed -E 's/.*class .*//g')"
  msg="$(echo "${msg}" | sed -E 's/.*import .*//g')"

  # 5. Collapse multiple whitespace to single space
  msg="$(echo "${msg}" | tr -s ' ' | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"

  # 6. Truncate to 200 characters
  msg="${msg:0:200}"

  echo "${msg}"
}
