#!/usr/bin/env bash
# init-context.sh — Bootstrap script for creating project context files
#
# Usage: init-context.sh [OPTIONS]
#
# Options:
#   --full        Use comprehensive template (9 sections)
#   --minimal     Use minimal template (4 sections)
#   --output FILE Write to FILE instead of ./AGENTS.md
#   --force       Overwrite existing file without prompt
#   --help        Show usage information
#
# Exit Codes:
#   0  Success (file created or overwritten)
#   1  File already exists (use --force to overwrite)
#   2  Invalid arguments or missing required input

set -euo pipefail

# Resolve script location for finding templates
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/../templates"

# Defaults
TEMPLATE=""
OUTPUT_FILE="./AGENTS.md"
FORCE=false

usage() {
  cat <<'EOF'
Usage: init-context.sh [OPTIONS]

Create an AGENTS.md project context file from a template.

Options:
  --full        Use comprehensive template (9 sections)
  --minimal     Use minimal template (4 sections)
  --output FILE Write to FILE instead of ./AGENTS.md
  --force       Overwrite existing file without prompt
  --help        Show usage information

Exit Codes:
  0  Success (file created or overwritten)
  1  File already exists (use --force to overwrite)
  2  Invalid arguments

Examples:
  init-context.sh --minimal
  init-context.sh --full --output docs/AGENTS.md
  init-context.sh --minimal --force
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full)
        TEMPLATE="full"
        shift
        ;;
      --minimal)
        TEMPLATE="minimal"
        shift
        ;;
      --output)
        if [[ $# -lt 2 ]]; then
          echo "Error: --output requires a file path argument" >&2
          exit 2
        fi
        OUTPUT_FILE="$2"
        shift 2
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option: $1" >&2
        echo "Run with --help for usage information." >&2
        exit 2
        ;;
    esac
  done
}

prompt_template_choice() {
  echo "Which template would you like to use?"
  echo "  1) full    - Comprehensive template (9 sections)"
  echo "  2) minimal - Minimal template (4 sections)"
  echo ""
  printf "Enter choice (1 or 2): "

  local choice
  read -r choice

  case "$choice" in
    1|full)
      TEMPLATE="full"
      ;;
    2|minimal)
      TEMPLATE="minimal"
      ;;
    *)
      echo "Error: Invalid choice. Please enter 1 or 2." >&2
      exit 2
      ;;
  esac
}

resolve_template_path() {
  local template_file
  case "$TEMPLATE" in
    full)
      template_file="${TEMPLATES_DIR}/AGENTS.md.full"
      ;;
    minimal)
      template_file="${TEMPLATES_DIR}/AGENTS.md.minimal"
      ;;
    *)
      echo "Error: Unknown template type: ${TEMPLATE}" >&2
      exit 2
      ;;
  esac

  if [[ ! -f "$template_file" ]]; then
    echo "Error: Template file not found: ${template_file}" >&2
    exit 2
  fi

  echo "$template_file"
}

main() {
  parse_args "$@"

  # Interactive mode if no template specified
  if [[ -z "$TEMPLATE" ]]; then
    prompt_template_choice
  fi

  # Check if output file exists
  if [[ -f "$OUTPUT_FILE" && "$FORCE" != true ]]; then
    echo "Error: ${OUTPUT_FILE} already exists. Use --force to overwrite." >&2
    exit 1
  fi

  # Resolve and validate template
  local template_path
  template_path="$(resolve_template_path)"

  # Create output directory if needed
  local output_dir
  output_dir="$(dirname "$OUTPUT_FILE")"
  if [[ ! -d "$output_dir" ]]; then
    mkdir -p "$output_dir"
  fi

  # Write template to output
  cp "$template_path" "$OUTPUT_FILE"

  echo "Created ${OUTPUT_FILE} from ${TEMPLATE} template."
  echo "Edit the file to fill in your project details."
}

main "$@"
