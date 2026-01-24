# Implementation Plan: Voice Input for AI Coding Prompts

**Branch**: `015-voice-input` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-voice-input/spec.md`

## Summary

Implement voice-to-text dictation for developers to speak natural language instructions to AI coding agents. The solution uses a local, privacy-preserving macOS voice tool (VoiceInk or Superwhisper) with push-to-talk activation, custom technical vocabulary, and optional AI-powered cleanup. Output integrates via system clipboard into any text input including containerized IDE environments.

## Technical Context

**Language/Version**: Bash 5.x (setup/configuration scripts), YAML/JSON (tool configuration)
**Primary Dependencies**: Superwhisper ($249.99 lifetime) or VoiceInk ($25-49, open source) for local Whisper-based STT; Ollama (optional, for Tier 2 local LLM cleanup); Claude API (optional, for Tier 3 cloud cleanup)
**Storage**: File-based (custom vocabulary files at `~/.config/voice-input/`, tool-specific config)
**Testing**: Bash integration tests (setup verification), manual acceptance testing (accuracy validation)
**Target Platform**: macOS (Apple Silicon, host machine — NOT containerized)
**Project Type**: Single (configuration + shell scripts)
**Performance Goals**: Activation <1s, text ready <2s after speech ends, 95% general accuracy, 90% technical term accuracy
**Constraints**: Fully offline-capable, no permanent audio storage, push-to-talk only, macOS only
**Scale/Scope**: Single developer workstation, clipboard-based integration with container IDE

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ⚠️ JUSTIFIED VIOLATION | Voice processing MUST run on host for microphone access and latency. See Complexity Tracking. |
| II. Multi-Language Standards | ✅ PASS | Bash scripts follow formatting/linting standards. |
| III. Test-First Development | ✅ PASS | Integration tests verify setup scripts and configuration. |
| IV. Security-First Design | ✅ PASS | Local-only processing, no audio stored, no secrets in config. |
| V. Reproducibility & Portability | ⚠️ PARTIAL | macOS-only by spec constraint. Setup scripts are reproducible. |
| VI. Observability & Debuggability | ✅ PASS | Visual dictation state indicators, script exit codes. |
| VII. Simplicity & Pragmatism | ✅ PASS | Uses proven commercial tool rather than building custom solution. |

**Gate Result**: PASS with justified violations documented below.

## Bash Standards (Constitution II Supplement)

The constitution defines standards for Rust/Python/TypeScript/Go. This feature uses Bash 5.x exclusively. The following standards apply:

- **Lint**: `shellcheck` (all scripts must pass with zero warnings)
- **Format**: `shfmt -i 2 -ci` (2-space indent, case indent)
- **Test**: BATS (Bash Automated Testing System) or plain `test_*.sh` scripts with exit code assertions
- **Error handling**: `set -euo pipefail` in all scripts; explicit error messages to stderr
- **Documentation**: Usage comments in each script header; `--help` flag required

## Requirements Handled by Voice Tool

The following SHOULD requirements from the spec are fulfilled natively by the selected voice tool (Superwhisper/VoiceInk) and do not require custom implementation:

| Requirement | How Handled |
|-------------|-------------|
| FR-011 (multi-language) | Whisper models support 99 languages natively; language configured in tool settings |
| FR-013 (visual indication) | Voice tool provides native recording/processing/complete indicators in menu bar |
| FR-014 (cancellation) | Press Escape or activation shortcut again to cancel; handled by tool's keyboard system |
| Edge: background noise | Whisper model degrades gracefully; user reviews before pasting |
| Edge: app switching | Voice tool captures audio regardless of focused window |
| Edge: accidental activation | Cancel via Escape; push-to-talk requires intentional hold |

## Project Structure

### Documentation (this feature)

```text
specs/015-voice-input/
├── plan.md              # This file
├── research.md          # Phase 0: Tool evaluation and decisions
├── data-model.md        # Phase 1: Configuration entities
├── quickstart.md        # Phase 1: Setup and usage guide
├── contracts/           # Phase 1: Configuration schemas
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/
├── scripts/
│   ├── setup-voice-input.sh      # Installation and configuration script
│   ├── verify-voice-input.sh     # Health check / verification script
│   └── update-vocabulary.sh      # Custom vocabulary management
├── config/
│   ├── vocabulary.yaml           # Custom technical vocabulary definitions
│   ├── ai-cleanup-prompt.txt     # AI cleanup system prompt template
│   └── voice-input.env.example   # Environment variable template
└── chezmoi/
    └── voice-input/              # Chezmoi-managed config templates
        ├── dot_config/
        │   └── voice-input/
        │       └── settings.yaml.tmpl  # VoiceInputSettings config template

tests/
├── integration/
│   ├── test_setup.sh             # Verify installation completes
│   ├── test_vocabulary.sh        # Verify vocabulary loading
│   └── test_clipboard.sh         # Verify clipboard integration
└── unit/
    └── test_config_parsing.sh    # Config file validation
```

**Structure Decision**: Single project with Bash scripts for setup/configuration and Chezmoi templates for dotfile management. This is primarily a configuration/integration feature, not a full application. The voice tool itself is a third-party binary — our implementation provides setup automation, vocabulary management, and integration glue.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Host-side execution (violates Container-First) | Microphone hardware access requires host-level permissions; audio processing latency would be unacceptable via container audio passthrough; macOS security model requires user consent for mic access at the app level | Running inside container would require complex audio device passthrough (PulseAudio/PipeWire forwarding), add 100-500ms latency, and break macOS microphone permission model |
| macOS-only (limits Reproducibility) | Spec constraint: macOS is the required platform; voice input tools are OS-specific; Apple Silicon optimization is critical for local model performance | Cross-platform abstraction would add significant complexity for a developer productivity tool with a single known user platform |
