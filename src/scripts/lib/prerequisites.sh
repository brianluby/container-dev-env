#!/usr/bin/env bash
set -euo pipefail
# prerequisites.sh — Platform and tool prerequisite checks
# Source this file after common.sh

# ─── Platform Checks ─────────────────────────────────────────────────────────

# Check that we're running on macOS
check_macos() {
  if ! is_macos; then
    log_error "This tool requires macOS. Detected: $(uname -s)"
    return 1
  fi
  log_success "macOS detected"
  return 0
}

# Check for Apple Silicon processor
check_apple_silicon() {
  if ! is_apple_silicon; then
    log_error "Apple Silicon (M1+) required for optimal Whisper performance. Detected: $(uname -m)"
    return 1
  fi
  log_success "Apple Silicon detected ($(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'arm64'))"
  return 0
}

# ─── Voice Tool Detection ────────────────────────────────────────────────────

# Check if Superwhisper is installed
check_superwhisper_installed() {
  if [[ -d "/Applications/Superwhisper.app" ]] || [[ -d "${HOME}/Applications/Superwhisper.app" ]]; then
    log_success "Superwhisper is installed"
    return 0
  fi
  log_error "Superwhisper not found in /Applications or ~/Applications"
  log_info "Install from: https://superwhisper.com"
  return 1
}

# Check if VoiceInk is installed
check_voiceink_installed() {
  if [[ -d "/Applications/VoiceInk.app" ]] || [[ -d "${HOME}/Applications/VoiceInk.app" ]]; then
    log_success "VoiceInk is installed"
    return 0
  fi
  log_error "VoiceInk not found in /Applications or ~/Applications"
  log_info "Install from: https://github.com/Whisper-Apps/VoiceInk or Mac App Store"
  return 1
}

# Check if the selected voice tool is installed
check_tool_installed() {
  local tool="${1:-superwhisper}"
  case "$tool" in
    superwhisper)
      check_superwhisper_installed
      ;;
    voiceink)
      check_voiceink_installed
      ;;
    *)
      log_error "Unknown tool: $tool"
      return 1
      ;;
  esac
}

# Check if the selected voice tool is currently running
check_tool_running() {
  local tool="${1:-superwhisper}"
  local process_name

  case "$tool" in
    superwhisper)
      process_name="Superwhisper"
      ;;
    voiceink)
      process_name="VoiceInk"
      ;;
    *)
      log_error "Unknown tool: $tool"
      return 1
      ;;
  esac

  if pgrep -x "$process_name" >/dev/null 2>&1; then
    log_success "$process_name is running"
    return 0
  fi
  log_warn "$process_name is not currently running"
  return 1
}

# ─── Permissions Checks ──────────────────────────────────────────────────────

# Check microphone permission status
# Note: Full verification requires the tool to actually request access.
# This check verifies the TCC database has an entry.
check_mic_permission() {
  local tool="${1:-superwhisper}"
  local bundle_id

  case "$tool" in
    superwhisper)
      bundle_id="com.superduper.superwhisper"
      ;;
    voiceink)
      bundle_id="com.VoiceInk.VoiceInk"
      ;;
    *)
      log_error "Unknown tool: $tool"
      return 1
      ;;
  esac

  # Check TCC database for microphone permission
  local tcc_result
  tcc_result=$(sqlite3 "${HOME}/Library/Application Support/com.apple.TCC/TCC.db" \
    "SELECT auth_value FROM access WHERE service='kTCCServiceMicrophone' AND client='$bundle_id'" 2>/dev/null || echo "")

  if [[ "$tcc_result" == "2" ]]; then
    log_success "Microphone permission granted for $tool"
    return 0
  elif [[ -z "$tcc_result" ]]; then
    log_warn "Microphone permission not yet requested for $tool"
    log_info "Launch $tool and grant microphone access when prompted"
    return 1
  else
    log_error "Microphone permission denied for $tool"
    log_info "Grant access in: System Settings → Privacy & Security → Microphone"
    return 1
  fi
}

# ─── Ollama Checks (for local_llm cleanup tier) ──────────────────────────────

# Check if Ollama is installed
check_ollama_installed() {
  if command_exists ollama; then
    log_success "Ollama is installed ($(ollama --version 2>/dev/null || echo 'version unknown'))"
    return 0
  fi
  log_error "Ollama not found"
  log_info "Install from: https://ollama.ai"
  return 1
}

# Check if Ollama server is running and accessible
check_ollama_running() {
  if curl -s --max-time 2 "http://localhost:11434/api/tags" >/dev/null 2>&1; then
    log_success "Ollama server is running"
    return 0
  fi
  log_error "Ollama server not responding on localhost:11434"
  log_info "Start with: ollama serve"
  return 1
}

# Check if a specific Ollama model is available
check_ollama_model() {
  local model="${1:-phi3:mini}"

  local models_json
  models_json=$(curl -s --max-time 5 "http://localhost:11434/api/tags" 2>/dev/null || echo "")

  if [[ -z "$models_json" ]]; then
    log_error "Cannot query Ollama models (server not responding)"
    return 1
  fi

  if echo "$models_json" | grep -q "\"$model\""; then
    log_success "Ollama model '$model' is available"
    return 0
  fi
  log_error "Ollama model '$model' not found"
  log_info "Pull with: ollama pull $model"
  return 1
}

# ─── Cloud API Checks (for cloud cleanup tier) ───────────────────────────────

# Check if the API key environment variable is set
check_cloud_api_key() {
  local env_var="${1:-}"

  if [[ -z "$env_var" ]]; then
    log_error "No API key environment variable configured"
    return 1
  fi

  if [[ -n "${!env_var:-}" ]]; then
    log_success "API key environment variable '$env_var' is set"
    return 0
  fi
  log_error "Environment variable '$env_var' is not set"
  return 1
}

# ─── Composite Checks ────────────────────────────────────────────────────────

# Run all prerequisite checks for initial setup
# Returns: number of failed checks
run_all_prerequisites() {
  local tool="${1:-superwhisper}"
  local cleanup_tier="${2:-rules}"
  local failures=0

  log_info "Checking prerequisites for tool=$tool, cleanup_tier=$cleanup_tier"
  echo ""

  check_macos || ((failures++))
  check_apple_silicon || ((failures++))
  check_tool_installed "$tool" || ((failures++))
  check_mic_permission "$tool" || ((failures++))

  if [[ "$cleanup_tier" == "local_llm" ]]; then
    check_ollama_installed || ((failures++))
    check_ollama_running || ((failures++))
  fi

  if [[ "$cleanup_tier" == "cloud" ]]; then
    local api_key_env="${3:-}"
    check_cloud_api_key "$api_key_env" || ((failures++))
  fi

  echo ""
  if ((failures == 0)); then
    log_success "All prerequisites met"
  else
    log_error "$failures prerequisite(s) not met"
  fi

  return "$failures"
}
