#!/usr/bin/env bash
# config-validator.sh — Validate voice-input settings.yaml against schema
# Source this file after common.sh

# ─── Settings Validation ─────────────────────────────────────────────────────

# Validate that settings.yaml exists and contains required fields
# Returns 0 if valid, 1 if invalid (with errors printed to stderr)
validate_settings() {
  local settings_file="${1:-$VOICE_INPUT_SETTINGS}"

  if [[ ! -f "$settings_file" ]]; then
    log_error "Settings file not found: $settings_file"
    return 1
  fi

  local errors=0

  # Required fields
  local required_fields=("tool" "whisper_model" "activation_shortcut" "activation_mode"
    "offline_only" "cleanup_tier" "custom_vocab_paths" "silence_timeout_ms" "language")

  for field in "${required_fields[@]}"; do
    local value
    value=$(yaml_get "$field" "$settings_file")
    if [[ -z "$value" ]]; then
      log_error "Missing required field: $field"
      ((errors++))
    fi
  done

  if ((errors > 0)); then
    return 1
  fi

  # Enum validation
  local tool
  tool=$(yaml_get "tool" "$settings_file")
  if ! is_valid_value "$tool" "${VALID_TOOLS[@]}"; then
    log_error "Invalid tool: '$tool'. Must be one of: ${VALID_TOOLS[*]}"
    ((errors++))
  fi

  local model
  model=$(yaml_get "whisper_model" "$settings_file")
  if ! is_valid_value "$model" "${VALID_MODELS[@]}"; then
    log_error "Invalid whisper_model: '$model'. Must be one of: ${VALID_MODELS[*]}"
    ((errors++))
  fi

  local mode
  mode=$(yaml_get "activation_mode" "$settings_file")
  if ! is_valid_value "$mode" "${VALID_ACTIVATION_MODES[@]}"; then
    log_error "Invalid activation_mode: '$mode'. Must be one of: ${VALID_ACTIVATION_MODES[*]}"
    ((errors++))
  fi

  local tier
  tier=$(yaml_get "cleanup_tier" "$settings_file")
  if ! is_valid_value "$tier" "${VALID_CLEANUP_TIERS[@]}"; then
    log_error "Invalid cleanup_tier: '$tier'. Must be one of: ${VALID_CLEANUP_TIERS[*]}"
    ((errors++))
  fi

  # Range validation
  local silence_ms
  silence_ms=$(yaml_get "silence_timeout_ms" "$settings_file")
  if [[ -n "$silence_ms" ]] && { ((silence_ms < 500)) || ((silence_ms > 5000)); }; then
    log_error "silence_timeout_ms must be between 500 and 5000, got: $silence_ms"
    ((errors++))
  fi

  local max_duration
  max_duration=$(yaml_get "max_recording_duration_s" "$settings_file")
  if [[ -n "$max_duration" ]] && { ((max_duration < 10)) || ((max_duration > 600)); }; then
    log_error "max_recording_duration_s must be between 10 and 600, got: $max_duration"
    ((errors++))
  fi

  # Language format validation (ISO 639-1: two lowercase letters)
  local lang
  lang=$(yaml_get "language" "$settings_file")
  if [[ -n "$lang" ]] && ! [[ "$lang" =~ ^[a-z]{2}$ ]]; then
    log_error "language must be ISO 639-1 format (two lowercase letters), got: '$lang'"
    ((errors++))
  fi

  # Cross-field validation
  validate_cross_field_rules "$settings_file" || ((errors++))

  if ((errors > 0)); then
    log_error "Settings validation failed with $errors error(s)"
    return 1
  fi

  return 0
}

# ─── Cross-Field Rules ────────────────────────────────────────────────────────

validate_cross_field_rules() {
  local settings_file="$1"
  local errors=0

  local offline_only
  offline_only=$(yaml_get "offline_only" "$settings_file")
  local cleanup_tier
  cleanup_tier=$(yaml_get "cleanup_tier" "$settings_file")

  # Rule: If offline_only=true, cleanup_tier must not be "cloud"
  if [[ "$offline_only" == "true" ]] && [[ "$cleanup_tier" == "cloud" ]]; then
    log_error "cleanup_tier cannot be 'cloud' when offline_only is true"
    ((errors++))
  fi

  # Rule: If cleanup_tier=cloud, provider and API key env must be set
  if [[ "$cleanup_tier" == "cloud" ]]; then
    local provider
    provider=$(yaml_get "cleanup_cloud_provider" "$settings_file")
    if [[ -z "$provider" ]]; then
      log_error "cleanup_cloud_provider is required when cleanup_tier=cloud"
      ((errors++))
    fi

    local api_key_env
    api_key_env=$(yaml_get "cleanup_cloud_api_key_env" "$settings_file")
    if [[ -z "$api_key_env" ]]; then
      log_error "cleanup_cloud_api_key_env is required when cleanup_tier=cloud"
      ((errors++))
    fi
  fi

  # Rule: If cleanup_tier=local_llm, validate model is specified
  if [[ "$cleanup_tier" == "local_llm" ]]; then
    local llm_model
    llm_model=$(yaml_get "cleanup_local_llm_model" "$settings_file")
    if [[ -z "$llm_model" ]]; then
      log_warn "cleanup_local_llm_model not set, defaulting to phi3:mini"
    fi
  fi

  # Rule: activation_shortcut must not be empty
  local shortcut
  shortcut=$(yaml_get "activation_shortcut" "$settings_file")
  if [[ -z "$shortcut" ]]; then
    log_error "activation_shortcut cannot be empty"
    ((errors++))
  fi

  return $((errors > 0 ? 1 : 0))
}

# ─── Shortcut Validation ─────────────────────────────────────────────────────

# Validate activation shortcut identifier format
validate_shortcut() {
  local shortcut="$1"
  local valid_keys=("RightCommand" "LeftCommand" "RightOption" "LeftOption"
    "RightControl" "LeftControl" "RightShift" "LeftShift" "Fn" "CapsLock")

  # Single key check
  if is_valid_value "$shortcut" "${valid_keys[@]}"; then
    return 0
  fi

  # Combo format: Modifier+Key (e.g., Ctrl+Shift+Space)
  if [[ "$shortcut" =~ ^[A-Za-z]+([\+][A-Za-z]+)+$ ]]; then
    return 0
  fi

  log_error "Invalid shortcut: '$shortcut'. Use a key name (RightCommand, Fn, etc.) or a combo (Ctrl+Shift+Space)"
  return 1
}
