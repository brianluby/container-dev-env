#!/usr/bin/env bash
set -euo pipefail

# new-adr.sh — Create a new Architecture Decision Record
#
# Usage: new-adr.sh [--docs-dir DIR] "Title of the Decision"
#
# Creates a new ADR file with auto-incremented number and kebab-case filename.
# Uses the _template.md in the decisions directory as the base.
#
# Exit codes:
#   0 - Success
#   1 - Runtime error (missing template, write failure)
#   2 - Usage error (missing arguments)

print_usage() {
    echo "Usage: $(basename "$0") [--docs-dir DIR] \"Title of Decision\"" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --docs-dir DIR   Path to decisions directory (default: docs/decisions)" >&2
}

# Parse arguments
DOCS_DIR=""
TITLE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --docs-dir)
            DOCS_DIR="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            TITLE="$1"
            shift
            ;;
    esac
done

# Default docs directory if not specified
if [[ -z "${DOCS_DIR}" ]]; then
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    DOCS_DIR="${REPO_ROOT}/docs/decisions"
fi

# Validate title argument
if [[ -z "${TITLE}" ]]; then
    echo "Error: Title argument is required" >&2
    print_usage
    exit 2
fi

# Validate template exists
TEMPLATE="${DOCS_DIR}/_template.md"
if [[ ! -f "${TEMPLATE}" ]]; then
    echo "Error: Template not found at ${TEMPLATE}" >&2
    exit 1
fi

# Convert title to kebab-case
# Lowercase, replace non-alphanumeric with hyphens, collapse multiple hyphens, trim edges
kebab_title="$(echo "${TITLE}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')"

# Determine next ADR number
# Find highest existing number, increment by 1
highest=0
for file in "${DOCS_DIR}"/[0-9][0-9][0-9]-*.md; do
    if [[ -f "${file}" ]]; then
        num="$(basename "${file}" | grep -oE '^[0-9]+' | sed 's/^0*//' )"
        if [[ -n "${num}" ]] && [[ "${num}" -gt "${highest}" ]]; then
            highest="${num}"
        fi
    fi
done
next_num=$((highest + 1))
padded_num="$(printf '%03d' "${next_num}")"

# Generate filename
FILENAME="${padded_num}-${kebab_title}.md"
FILEPATH="${DOCS_DIR}/${FILENAME}"

# Get current date
TODAY="$(date +%Y-%m-%d)"

# Copy template and substitute placeholders
sed \
    -e "s/ADR-NNN/ADR-${padded_num}/g" \
    -e "s/\[Short Noun Phrase Title\]/${TITLE}/g" \
    -e "s/YYYY-MM-DD/${TODAY}/g" \
    -e "s/\[Proposed | Accepted | Deprecated | Superseded by ADR-XXX\]/Proposed/g" \
    "${TEMPLATE}" > "${FILEPATH}"

echo "Created: ${FILEPATH}"
