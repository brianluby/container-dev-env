# Setup Script Interface Contract

## setup-voice-input.sh

**Purpose**: Install and configure the voice input system on a macOS host.

### Usage

```bash
./setup-voice-input.sh [OPTIONS]
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `--tool <name>` | Voice tool to configure (`superwhisper`, `voiceink`) | `superwhisper` |
| `--model <size>` | Whisper model size (`tiny`, `base`, `small`, `medium`, `large-v3`, `turbo`) | `large-v3` |
| `--shortcut <key>` | Push-to-talk key identifier | `RightCommand` |
| `--cleanup-tier <tier>` | Cleanup level (`none`, `rules`, `local_llm`, `cloud`) | `rules` |
| `--offline-only` | Restrict to local-only processing (no network) | enabled |
| `--dry-run` | Show what would be configured without making changes | — |
| `--help` | Show usage information | — |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Missing prerequisite (tool not installed) |
| 3 | Invalid configuration |
| 4 | Platform not supported (not macOS) |

### Prerequisites Checked

1. macOS operating system
2. Apple Silicon (M1+) processor
3. Selected voice tool installed (Superwhisper or VoiceInk)
4. Microphone permission granted to the tool
5. (If cleanup_tier=local_llm) Ollama installed and running
6. (If cleanup_tier=cloud) API key environment variable set

### Outputs

- Creates `~/.config/voice-input/settings.yaml`
- Creates `~/.config/voice-input/vocabulary.yaml` (seed file if not exists)
- Creates `~/.config/voice-input/ai-cleanup-prompt.txt`
- Prints verification status and tool-specific configuration guidance to stdout

---

## verify-voice-input.sh

**Purpose**: Health check to verify voice input system is properly configured.

### Usage

```bash
./verify-voice-input.sh [--json]
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks pass |
| 1 | One or more checks failed |

### Checks Performed

1. Settings file exists and is valid YAML
2. Selected voice tool is installed
3. Voice tool is running (process check)
4. Microphone permissions granted
5. Vocabulary file is valid (if configured)
6. (If cleanup_tier=local_llm) Ollama is accessible and model available
7. (If cleanup_tier=cloud) API key env var is set

### Output Format (--json)

```json
{
  "status": "pass|fail",
  "tool": "superwhisper",
  "tool_installed": true,
  "tool_running": true,
  "mic_permission": true,
  "settings_valid": true,
  "vocabulary_valid": true,
  "cleanup_available": true,
  "checks_passed": 7,
  "checks_total": 7
}
```

---

## update-vocabulary.sh

**Purpose**: Manage custom vocabulary entries.

### Usage

```bash
./update-vocabulary.sh add-term <term> --spoken-forms "<form1>,<form2>" --category <category> [--display-form <display>] [--project <project>]
./update-vocabulary.sh remove-term <term>
./update-vocabulary.sh list [--category <category>] [--project <project>]
./update-vocabulary.sh validate
./update-vocabulary.sh sync
```

### Subcommands

| Command | Description |
|---------|-------------|
| `add-term` | Add a vocabulary term with spoken forms, display form, and category |
| `remove-term` | Remove a term from vocabulary |
| `list` | Display current vocabulary (optionally filtered) |
| `validate` | Check vocabulary file against schema |
| `sync` | Push vocabulary to the voice tool's internal dictionary |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 3 | Validation failure |
| 5 | Vocabulary file not found |
