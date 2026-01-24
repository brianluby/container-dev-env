#!/usr/bin/env bash
# update-vocabulary.sh — Manage custom vocabulary entries
# Usage: ./update-vocabulary.sh <subcommand> [OPTIONS]
# See --help for full usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ─── Constants ────────────────────────────────────────────────────────────────

readonly MAX_TERMS=500
readonly VALID_CATEGORIES=("function_name" "variable_name" "technology" "project_name" "domain_term" "custom")

# ─── Usage ────────────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: update-vocabulary.sh <subcommand> [OPTIONS]

Manage custom vocabulary entries for improved voice recognition accuracy.

Subcommands:
  add-term <term>     Add a vocabulary term
  remove-term <term>  Remove a vocabulary term
  list                Display current vocabulary
  validate            Check vocabulary file against schema
  sync                Push vocabulary to the voice tool

Options for add-term:
  --spoken-forms "<form1>,<form2>"  How the term might be spoken (comma-separated)
  --display-form <display>          How the term appears in output (default: term value)
  --category <category>             Classification (required)
  --project <project>               Project scope (default: global)

Valid categories:
  function_name, variable_name, technology, project_name, domain_term, custom

Examples:
  # Add a function name
  ./update-vocabulary.sh add-term getUserById \
    --spoken-forms "get user by id,get user by ID" \
    --display-form getUserById \
    --category function_name

  # Add a project-specific term
  ./update-vocabulary.sh add-term myService \
    --spoken-forms "my service" \
    --display-form myService \
    --category project_name \
    --project my-app

  # List all terms filtered by category
  ./update-vocabulary.sh list --category technology

  # Validate vocabulary file
  ./update-vocabulary.sh validate

Exit Codes:
  0  Success
  1  General error
  3  Validation failure
  5  Vocabulary file not found
EOF
}

# ─── Vocabulary File Helpers ──────────────────────────────────────────────────

get_vocab_file() {
  echo "$VOICE_INPUT_VOCABULARY"
}

ensure_vocab_file() {
  local vocab_file
  vocab_file=$(get_vocab_file)
  if [[ ! -f "$vocab_file" ]]; then
    log_error "Vocabulary file not found: $vocab_file"
    log_info "Run setup-voice-input.sh first to create it"
    return "$EXIT_VOCAB_NOT_FOUND"
  fi
}

count_terms() {
  local vocab_file
  vocab_file=$(get_vocab_file)
  grep -c "^  - term:" "$vocab_file" 2>/dev/null || echo "0"
}

# ─── Add Term ─────────────────────────────────────────────────────────────────

cmd_add_term() {
  local term="${1:-}"
  shift || true

  if [[ -z "$term" ]]; then
    log_error "Term name is required"
    return "$EXIT_GENERAL_ERROR"
  fi

  local spoken_forms=""
  local display_form="$term"
  local category=""
  local project="global"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --spoken-forms)
        spoken_forms="${2:-}"
        shift 2
        ;;
      --display-form)
        display_form="${2:-}"
        shift 2
        ;;
      --category)
        category="${2:-}"
        shift 2
        ;;
      --project)
        project="${2:-}"
        shift 2
        ;;
      *)
        log_error "Unknown option for add-term: $1"
        return "$EXIT_GENERAL_ERROR"
        ;;
    esac
  done

  # Validate required fields
  if [[ -z "$spoken_forms" ]]; then
    log_error "--spoken-forms is required"
    return "$EXIT_GENERAL_ERROR"
  fi

  if [[ -z "$category" ]]; then
    log_error "--category is required"
    return "$EXIT_GENERAL_ERROR"
  fi

  if ! is_valid_value "$category" "${VALID_CATEGORIES[@]}"; then
    log_error "Invalid category: '$category'. Must be one of: ${VALID_CATEGORIES[*]}"
    return "$EXIT_INVALID_CONFIG"
  fi

  ensure_vocab_file || return $?

  # Check term count limit
  local current_count
  current_count=$(count_terms)
  if ((current_count >= MAX_TERMS)); then
    log_error "Maximum vocabulary size ($MAX_TERMS terms) reached"
    return "$EXIT_GENERAL_ERROR"
  fi

  # Check for duplicate
  local vocab_file
  vocab_file=$(get_vocab_file)
  if grep -q "^  - term: ${term}$" "$vocab_file" 2>/dev/null; then
    log_error "Term '$term' already exists. Remove it first to update."
    return "$EXIT_GENERAL_ERROR"
  fi

  # Build spoken_forms YAML array
  local spoken_yaml="["
  local first=true
  IFS=',' read -ra forms <<< "$spoken_forms"
  for form in "${forms[@]}"; do
    form=$(echo "$form" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    if [[ "$first" == true ]]; then
      spoken_yaml+="\"${form}\""
      first=false
    else
      spoken_yaml+=", \"${form}\""
    fi
  done
  spoken_yaml+="]"

  # Append entry to vocabulary file
  cat >> "$vocab_file" <<EOF

  - term: ${term}
    spoken_forms: ${spoken_yaml}
    display_form: ${display_form}
    category: ${category}
    project: ${project}
    enabled: true
EOF

  log_success "Added term: $term (category: $category, project: $project)"
}

# ─── Remove Term ──────────────────────────────────────────────────────────────

cmd_remove_term() {
  local term="${1:-}"

  if [[ -z "$term" ]]; then
    log_error "Term name is required"
    return "$EXIT_GENERAL_ERROR"
  fi

  ensure_vocab_file || return $?

  local vocab_file
  vocab_file=$(get_vocab_file)

  if ! grep -q "^  - term: ${term}$" "$vocab_file" 2>/dev/null; then
    log_error "Term '$term' not found in vocabulary"
    return "$EXIT_GENERAL_ERROR"
  fi

  # Remove the term block (from "  - term: X" to next "  - term:" or end)
  local temp_file
  temp_file=$(mktemp)

  awk -v term="$term" '
    BEGIN { skip = 0 }
    /^  - term: / {
      if ($0 == "  - term: " term) {
        skip = 1
        next
      } else {
        skip = 0
      }
    }
    skip && /^    / { next }
    skip && /^$/ { skip = 0; next }
    !skip { print }
  ' "$vocab_file" > "$temp_file"

  mv "$temp_file" "$vocab_file"
  log_success "Removed term: $term"
}

# ─── List ─────────────────────────────────────────────────────────────────────

cmd_list() {
  local filter_category=""
  local filter_project=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --category)
        filter_category="${2:-}"
        shift 2
        ;;
      --project)
        filter_project="${2:-}"
        shift 2
        ;;
      *)
        log_error "Unknown option for list: $1"
        return "$EXIT_GENERAL_ERROR"
        ;;
    esac
  done

  ensure_vocab_file || return $?

  local vocab_file
  vocab_file=$(get_vocab_file)

  echo ""
  echo "=== Custom Vocabulary ==="
  echo ""

  local current_term=""
  local current_display=""
  local current_category=""
  local current_project=""
  local current_spoken=""
  local show_term=true
  local term_count=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*term:[[:space:]]*(.*) ]]; then
      # Print previous term if it passed filters
      if [[ -n "$current_term" ]] && [[ "$show_term" == true ]]; then
        printf "  %-25s %-20s %-15s %s\n" "$current_term" "$current_display" "$current_category" "$current_project"
        term_count=$((term_count + 1))
      fi
      current_term="${BASH_REMATCH[1]}"
      current_display=""
      current_category=""
      current_project="global"
      current_spoken=""
      show_term=true
    elif [[ "$line" =~ display_form:[[:space:]]*(.*) ]]; then
      current_display="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ category:[[:space:]]*(.*) ]]; then
      current_category="${BASH_REMATCH[1]}"
      if [[ -n "$filter_category" ]] && [[ "$current_category" != "$filter_category" ]]; then
        show_term=false
      fi
    elif [[ "$line" =~ project:[[:space:]]*(.*) ]]; then
      current_project="${BASH_REMATCH[1]}"
      if [[ -n "$filter_project" ]] && [[ "$current_project" != "$filter_project" ]]; then
        show_term=false
      fi
    fi
  done < "$vocab_file"

  # Print last term
  if [[ -n "$current_term" ]] && [[ "$show_term" == true ]]; then
    printf "  %-25s %-20s %-15s %s\n" "$current_term" "$current_display" "$current_category" "$current_project"
    term_count=$((term_count + 1))
  fi

  echo ""
  echo "Total: $term_count terms"
}

# ─── Validate ─────────────────────────────────────────────────────────────────

cmd_validate() {
  ensure_vocab_file || return $?

  local vocab_file
  vocab_file=$(get_vocab_file)
  local errors=0

  echo ""
  echo "=== Vocabulary Validation ==="
  echo ""

  # Check version field
  if ! grep -q "^version:" "$vocab_file"; then
    log_error "Missing 'version' field"
    errors=$((errors + 1))
  else
    local version
    version=$(grep "^version:" "$vocab_file" | sed 's/version:[[:space:]]*//' | tr -d '"')
    if [[ "$version" != "1" ]]; then
      log_error "Invalid version: '$version' (expected '1')"
      errors=$((errors + 1))
    else
      log_success "Version: $version"
    fi
  fi

  # Check terms array exists
  if ! grep -q "^terms:" "$vocab_file"; then
    log_error "Missing 'terms' field"
    errors=$((errors + 1))
  fi

  # Count terms and check limit
  local term_count
  term_count=$(count_terms)
  if ((term_count > MAX_TERMS)); then
    log_error "Too many terms: $term_count (max $MAX_TERMS)"
    errors=$((errors + 1))
  else
    log_success "Term count: $term_count / $MAX_TERMS"
  fi

  # Validate each term has required fields
  local line_num=0
  local in_term=false
  local has_spoken=false
  local has_display=false
  local has_category=false
  local current_term=""

  while IFS= read -r line; do
    line_num=$((line_num + 1))

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*term:[[:space:]]*(.*) ]]; then
      # Validate previous term
      if [[ "$in_term" == true ]]; then
        if [[ "$has_spoken" == false ]]; then
          log_error "Term '$current_term': missing spoken_forms"
          errors=$((errors + 1))
        fi
        if [[ "$has_display" == false ]]; then
          log_error "Term '$current_term': missing display_form"
          errors=$((errors + 1))
        fi
        if [[ "$has_category" == false ]]; then
          log_error "Term '$current_term': missing category"
          errors=$((errors + 1))
        fi
      fi

      current_term="${BASH_REMATCH[1]}"
      in_term=true
      has_spoken=false
      has_display=false
      has_category=false
    elif [[ "$line" =~ spoken_forms: ]]; then
      has_spoken=true
    elif [[ "$line" =~ display_form: ]]; then
      has_display=true
    elif [[ "$line" =~ category:[[:space:]]*(.*) ]]; then
      has_category=true
      local cat_value="${BASH_REMATCH[1]}"
      if ! is_valid_value "$cat_value" "${VALID_CATEGORIES[@]}"; then
        log_error "Term '$current_term': invalid category '$cat_value'"
        errors=$((errors + 1))
      fi
    fi
  done < "$vocab_file"

  # Validate last term
  if [[ "$in_term" == true ]]; then
    if [[ "$has_spoken" == false ]]; then
      log_error "Term '$current_term': missing spoken_forms"
      errors=$((errors + 1))
    fi
    if [[ "$has_display" == false ]]; then
      log_error "Term '$current_term': missing display_form"
      errors=$((errors + 1))
    fi
    if [[ "$has_category" == false ]]; then
      log_error "Term '$current_term': missing category"
      errors=$((errors + 1))
    fi
  fi

  echo ""
  if ((errors == 0)); then
    log_success "Vocabulary validation passed"
    return 0
  else
    log_error "Vocabulary validation failed with $errors error(s)"
    return "$EXIT_INVALID_CONFIG"
  fi
}

# ─── Sync ─────────────────────────────────────────────────────────────────────

cmd_sync() {
  ensure_vocab_file || return $?

  local settings_file="$VOICE_INPUT_SETTINGS"
  local tool="superwhisper"

  if [[ -f "$settings_file" ]]; then
    tool=$(yaml_get "tool" "$settings_file")
  fi

  echo ""
  echo "=== Vocabulary Sync ==="
  echo ""

  case "$tool" in
    superwhisper)
      sync_superwhisper
      ;;
    voiceink)
      sync_voiceink
      ;;
    *)
      log_error "Unknown tool: $tool"
      return "$EXIT_GENERAL_ERROR"
      ;;
  esac
}

sync_superwhisper() {
  log_info "Syncing vocabulary to Superwhisper..."
  echo ""
  echo "Superwhisper uses its built-in vocabulary training."
  echo "To improve recognition of custom terms:"
  echo ""
  echo "1. Open Superwhisper → Settings → Vocabulary"
  echo "2. Add custom words from your vocabulary.yaml"
  echo "3. Use the 'Train' feature to improve recognition"
  echo ""
  echo "Vocabulary file: $(get_vocab_file)"
  echo ""
  log_info "Manual sync required — Superwhisper does not support programmatic vocabulary import"
}

sync_voiceink() {
  log_info "Syncing vocabulary to VoiceInk..."
  echo ""
  echo "VoiceInk Personal Dictionary location:"
  echo "  ~/Library/Containers/com.VoiceInk.VoiceInk/Data/Library/Application Support/"
  echo ""
  echo "To improve recognition of custom terms:"
  echo ""
  echo "1. Open VoiceInk → Settings → Personal Dictionary"
  echo "2. Add entries from your vocabulary.yaml"
  echo ""
  echo "Vocabulary file: $(get_vocab_file)"
  echo ""
  log_info "Manual sync required — VoiceInk does not support programmatic vocabulary import"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit "$EXIT_GENERAL_ERROR"
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    add-term)
      cmd_add_term "$@"
      ;;
    remove-term)
      cmd_remove_term "$@"
      ;;
    list)
      cmd_list "$@"
      ;;
    validate)
      cmd_validate
      ;;
    sync)
      cmd_sync
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown subcommand: $subcommand"
      usage
      exit "$EXIT_GENERAL_ERROR"
      ;;
  esac
}

main "$@"
