# CLI Interface Contract: Voice Input

**Generated**: 2026-01-23

## Overview

The voice input system is primarily GUI-based (Superwhisper/VoiceInk), but configuration and management scripts expose a CLI interface for setup, vocabulary management, and cleanup integration.

## Scripts

### install.sh

**Purpose**: Install and configure the voice input tool.

```bash
# Usage
./src/scripts/install.sh [--tool superwhisper|voiceink] [--model large-v3|medium|small]

# Exit codes
# 0 - Success
# 1 - Missing prerequisites (macOS version, architecture)
# 2 - Installation failed
# 3 - Permission setup failed
```

**Behavior**:
- Checks macOS version (>=14) and architecture (arm64)
- Installs selected tool (default: superwhisper)
- Downloads specified Whisper model
- Prompts for required macOS permissions
- Creates default configuration files
- Outputs: JSON status to stdout, errors to stderr

### configure.sh

**Purpose**: Interactive configuration wizard for voice input settings.

```bash
# Usage
./src/scripts/configure.sh [--non-interactive] [--config path/to/settings.yaml]

# Exit codes
# 0 - Configuration saved
# 1 - Invalid configuration
# 2 - File write error
```

**Behavior**:
- Reads existing config or creates defaults
- In interactive mode: prompts for shortcut, mode, cleanup tier
- In non-interactive mode: validates provided config file
- Writes configuration to ~/.config/voice-input/
- Outputs: Configuration summary to stdout

### cleanup-proxy.sh

**Purpose**: Bridge between voice tool output and AI cleanup pipeline.

```bash
# Usage
echo "raw transcription text" | ./src/scripts/cleanup-proxy.sh [--tier rules|local_llm|cloud]

# Exit codes
# 0 - Cleanup successful, cleaned text on stdout
# 1 - Cleanup failed, raw text on stdout (graceful fallback)
# 2 - Invalid tier specified
# 3 - Provider unavailable (Ollama not running, API key missing)
```

**Behavior**:
- Reads raw transcription from stdin
- Applies specified cleanup tier
- Falls back to raw text on any error (never blocks workflow)
- Outputs: Cleaned text to stdout, diagnostics to stderr
- Environment variables:
  - `VOICE_CLEANUP_TIER`: Override default tier
  - `ANTHROPIC_API_KEY`: Required for cloud tier
  - `OLLAMA_HOST`: Custom Ollama endpoint (default: localhost:11434)

## Configuration File Contracts

### settings.yaml

```yaml
# Schema
activation_shortcut: string     # Key combo (e.g., "RightCommand", "Option+Space")
activation_mode: enum           # push_to_talk | toggle
silence_timeout_ms: integer     # 500-5000, default 1500
max_recording_duration_s: integer  # 30-600, default 300
whisper_model: enum             # tiny|base|small|medium|large-v3|turbo
cleanup_tier: enum              # none|rules|local_llm|cloud
output_method: enum             # clipboard (only option in v1)
language: string                # ISO 639-1, default "en"
visual_feedback: boolean        # default true
custom_vocab_paths: list[string]  # Paths to vocabulary files
```

### vocabulary.yaml

```yaml
# Schema
terms:
  - term: string                # Required, the canonical term
    spoken_forms: list[string]  # Required, at least one
    display_form: string        # Required, how it appears in output
    category: enum              # function_name|variable_name|technology|project_name|domain_term|custom
    project: string             # Optional, default "global"
    enabled: boolean            # Optional, default true
```

### Cleanup Settings (in settings.yaml)

Cleanup configuration is part of settings.yaml, not a separate file:

```yaml
# Additional cleanup-related fields in settings.yaml
cleanup_tier: enum                    # none|rules|local_llm|cloud
cleanup_local_llm_model: string       # For tier=local_llm, model name (e.g., "phi3:mini")
cleanup_cloud_provider: enum          # For tier=cloud, provider (claude|openai)
cleanup_cloud_api_key_env: string     # For tier=cloud, env var name with API key
```

## Integration Points

### Superwhisper URL Scheme

Superwhisper supports URL scheme for automation:
- `superwhisper://start` - Start recording
- `superwhisper://stop` - Stop recording
- `superwhisper://cancel` - Cancel current session

### Clipboard Integration

The voice tool writes transcription to the system clipboard via:
- `pbcopy` (macOS native)
- NSPasteboard API (if using Swift utility)

### Ollama API (Tier 2 Cleanup)

```
POST http://localhost:11434/api/generate
Content-Type: application/json

{
  "model": "phi3:mini",
  "prompt": "<cleanup prompt with raw text>",
  "stream": false
}
```

### Claude API (Tier 3 Cleanup)

```
POST https://api.anthropic.com/v1/messages
Content-Type: application/json
x-api-key: $ANTHROPIC_API_KEY
anthropic-version: 2023-06-01

{
  "model": "claude-3-5-haiku-20241022",
  "max_tokens": 1024,
  "messages": [{"role": "user", "content": "<cleanup prompt>"}]
}
```
