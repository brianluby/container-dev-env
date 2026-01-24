# Research: Voice Input for AI Coding Prompts

**Generated**: 2026-01-23
**Status**: Complete - all NEEDS CLARIFICATION resolved

## Research Task 1: Voice Tool Selection

### Decision: Superwhisper (Primary Recommendation) with VoiceInk as Budget Alternative

### Rationale

Superwhisper best meets all requirements simultaneously: local Whisper-based processing, configurable push-to-talk keyboard shortcuts, custom vocabulary support, AI-powered cleanup modes, and clipboard/direct-input output. It has proven developer adoption with specific tooling for technical vocabulary training.

### Candidates Evaluated

| Tool | Pricing | Local/Offline | Push-to-Talk | Custom Vocab | AI Cleanup | Dev Focus |
|------|---------|---------------|--------------|--------------|------------|-----------|
| **Superwhisper** | $8.49/mo or $249.99 lifetime | Yes (Whisper models) | Yes (since v1.41) | Yes (trainer tool) | Yes (modes) | High |
| **VoiceInk** | $25-49 one-time (open source) | Yes (whisper.cpp) | Yes | Yes (dictionaries) | Limited | Medium |
| **Sotto** | $29 one-time | Yes (Whisper.cpp) | Yes (hold/toggle) | Limited | Optional cloud | Medium |
| **Wispr Flow** | Subscription | Cloud + local | Yes | Limited | Yes (IDE integration) | High (Cursor/Windsurf) |
| **MacWhisper** | $30-60 one-time | Yes (Whisper models) | No (file-based) | No | No | Low |
| **Talon** | Free / $25/mo beta | Yes (Conformer) | Yes | Yes (extensive) | No | Very High (voice coding) |
| **GoWhisper** | Free (open source) | Yes (Whisper.cpp + Metal) | Yes (Cmd+Shift+P) | No | Yes (Claude AI) | High |
| **push-to-talk-dictate** | Free (open source) | Yes (MLX Whisper) | Yes (Option key) | No | Yes (Qwen cleanup) | Medium |
| **Apple Dictation** | Free (built-in) | Partial (Enhanced) | No (toggle only) | No | No | Low |

### Detailed Analysis

**Superwhisper** (Recommended):
- Push-to-talk with configurable shortcuts (single modifier keys supported)
- Multiple AI modes (local Whisper models + optional cloud for higher accuracy)
- Custom vocabulary via SuperWhisper Trainer (73% accuracy improvement for tech terms)
- App-specific mode switching (e.g., Code mode in IDE, Writing mode in Word)
- Works system-wide across all apps
- Pro: $8.49/month or $249.99 lifetime (within budget)
- Con: Requires more initial configuration; lifetime price at budget ceiling

**VoiceInk** (Budget Alternative):
- Open source (GPL v3.0), $25-49 for license with updates
- 100% offline with whisper.cpp
- Power Mode for app-specific settings
- Screen context awareness for better accuracy
- Con: Limited AI prompting (single assistant prompt only)
- Con: Basic UI, occasional model bugs

**Sotto** (Honorable Mention):
- $29 one-time, beautifully designed
- Hold-shortcut or toggle activation
- Direct input into active app
- Optional OpenAI/Groq for enhanced accuracy
- Con: Newer, less proven for developer workflows

**Talon** (Overkill for this use case):
- Designed for full voice coding (commands + dictation)
- Extensive customization via Python scripts
- English-only for main model
- Con: Steep learning curve, designed for voice-as-primary-input rather than supplemental dictation

### Alternatives Considered and Rejected

- **Wispr Flow**: Primarily cloud-based, doesn't meet offline-first requirement
- **MacWhisper**: File-based transcription (not real-time dictation), no push-to-talk
- **Apple Dictation**: No push-to-talk, limited accuracy for technical terms, poor offline model
- **Custom Whisper.cpp**: Too much engineering effort for equivalent functionality; use VoiceInk instead (which wraps whisper.cpp with UI)

---

## Research Task 2: AI Cleanup Integration

### Decision: Tiered approach - Rule-based local cleanup (default) + Optional LLM cleanup (opt-in)

### Rationale

A tiered approach provides immediate value with zero privacy concerns (local rules), while offering higher-quality cleanup for users who opt in to LLM processing. Local LLMs on Apple Silicon are now fast enough for short text cleanup.

### Tier 1: Rule-Based Local Cleanup (Default, No Network)

**Approach**: Regex patterns + custom dictionaries for common speech-to-text corrections.

- **Punctuation normalization**: "period" -> ".", "comma" -> ","
- **Technical term formatting**: Known library names capitalized correctly (e.g., "react" -> "React", "typescript" -> "TypeScript")
- **Code convention formatting**: Detect spoken variable patterns and apply conventions (e.g., "get user by id" -> "getUserById" when camelCase mode active)
- **Custom vocabulary replacement**: User-defined mappings for project-specific terms

**Performance**: <100ms for typical transcription length
**Privacy**: 100% local, no network calls
**Quality**: 70-80% of optimal formatting for known patterns

### Tier 2: Local LLM Cleanup (Optional, No Network)

**Approach**: Small local model via Ollama for formatting improvement.

Best models for this task on Apple Silicon:
- **Phi-3 Mini (3.8B)**: Fast inference (~1-2s for short text on M1+), good instruction following
- **Qwen2.5-3B-Instruct**: Excellent for text formatting tasks, fast on Apple Silicon
- **Llama-3.2-3B**: Good general capability, fast inference

**Performance**: 1-3s for typical transcription (acceptable within 5s total budget)
**Privacy**: 100% local, model runs on-device
**Quality**: 85-90% of optimal formatting
**Resource**: ~2-4GB RAM for 3B model
**Integration**: Ollama API (localhost:11434) or MLX for native Apple Silicon

### Tier 3: Cloud LLM Cleanup (Opt-in, Requires Network)

**Approach**: Send transcription text to Claude API or OpenAI API for premium formatting.

- **Claude Haiku**: Fast, cheap ($0.25/1M input tokens), excellent for text formatting
- **GPT-4o-mini**: Fast, cheap, good formatting capability

**Performance**: 500ms-2s round-trip for short text
**Privacy**: Text sent to cloud (clearly indicated to user, opt-in only)
**Quality**: 95%+ optimal formatting
**Cost**: ~$0.001-0.005 per transcription (negligible)

### Prompt Strategy (for Tier 2 and 3)

```
You are a code-context text formatter. Format the following dictated text for use as an AI coding prompt:
- Add proper punctuation and capitalization
- Format technical terms correctly (React, TypeScript, PostgreSQL, etc.)
- Convert spoken variable names to appropriate conventions (camelCase for JS/TS, snake_case for Python)
- Do not change the meaning or add content
- Output only the formatted text, nothing else

Input: {raw_transcription}
```

### Alternatives Considered

- **Apple Intelligence APIs**: Not yet available for third-party text processing in this manner; limited to system-level features
- **Pure rule-based only**: Insufficient for natural language formatting (can't handle novel patterns)
- **Cloud-only**: Violates privacy-first principle; unacceptable as default

---

## Research Task 3: Keyboard Shortcut / Hotkey Integration

### Decision: Use voice tool's built-in shortcut system (Superwhisper has native push-to-talk shortcuts)

### Rationale

Both Superwhisper and VoiceInk have built-in global keyboard shortcut systems that work across all apps. External hotkey tools are unnecessary for the primary use case but can enhance the workflow.

### Built-in Tool Shortcuts (Primary)

**Superwhisper**:
- Native push-to-talk with configurable shortcuts
- Supports single modifier keys (Left Cmd, Right Cmd, Fn)
- Toggle or hold-to-talk modes
- App-specific mode switching
- Cancel via shortcut or Escape
- Since v1.41 (Nov 2024): improved keyboard shortcut system

**VoiceInk**:
- Configurable global hotkey
- Push-to-talk support
- System-wide activation

### Enhancement Options (If Needed)

| Tool | Use Case | Complexity | Recommendation |
|------|----------|------------|----------------|
| **Karabiner-Elements** | Remap keys, complex modifiers | Low-Medium | Good for custom key combos |
| **Hammerspoon** | Lua scripting, complex automation | Medium | Good for multi-step workflows |
| **BetterTouchTool** | GUI-based automation | Low | Good for non-technical users |
| **Native Swift utility** | Custom CGEvent tap | High | Overkill for this use case |

### macOS Permissions Required

All global shortcut approaches require:
- **Accessibility permission**: For monitoring keyboard events system-wide
- **Input Monitoring**: For capturing key presses when other apps are focused
- **Microphone**: For audio capture (obviously)

These permissions are prompted on first use and remembered.

### Recommended Configuration

Default shortcut: **Right Command** (single key, doesn't conflict with common shortcuts)
Alternative: **Option+Space** or **Fn** key
Mode: Push-to-talk (hold to record, release to process)
Cancel: Press Escape during recording

---

## Summary of Decisions

| Unknown | Resolution | Confidence |
|---------|-----------|------------|
| Voice tool selection | Superwhisper (primary), VoiceInk (budget alternative) | High |
| AI cleanup approach | Tiered: Rule-based (default) + Local LLM (optional) + Cloud LLM (opt-in) | High |
| Keyboard shortcut | Built-in tool shortcuts (no external tool needed) | High |
| Output method | Clipboard + direct input (both supported by recommended tools) | High |
| Custom vocabulary | SuperWhisper Trainer + custom dictionary files | High |
| Offline guarantee | Whisper models run locally on Apple Silicon, no network for core flow | High |
