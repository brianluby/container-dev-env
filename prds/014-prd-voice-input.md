# 014-prd-voice-input

## Problem Statement

Typing detailed prompts for AI coding agents is time-consuming and interrupts flow. Voice
input enables developers to dictate code instructions, describe features, and interact with
AI agents hands-free. This is particularly valuable for complex explanations, brainstorming,
and accessibility. The solution must work with the containerized development environment.

**Critical constraint**: Voice input must either run locally on the host (for latency and
privacy) or work via web interface accessible from the container IDE. Processing must be
fast enough for real-time dictation without disrupting coding flow.

## Requirements

### Must Have (M)

- [ ] Voice-to-text transcription with high accuracy
- [ ] Works with AI coding agents (Claude Code, Cline, etc.)
- [ ] Low latency (near real-time transcription)
- [ ] Support for technical vocabulary (code terms, libraries, frameworks)
- [ ] macOS support (primary development platform)
- [ ] Privacy-respecting (local processing preferred)

### Should Have (S)

- [ ] Code-aware formatting (variable names, syntax)
- [ ] Multiple language/accent support
- [ ] Custom vocabulary training
- [ ] Keyboard shortcut activation
- [ ] IDE integration (direct insertion)
- [ ] LLM post-processing for cleanup and formatting

### Could Have (C)

- [ ] Linux support for containerized use
- [ ] Voice commands (not just dictation)
- [ ] Cursorless-style voice navigation
- [ ] Whisper model fine-tuning
- [ ] Noise cancellation
- [ ] Speaker identification

### Won't Have (W)

- [ ] Cloud-only solutions (privacy concern)
- [ ] Solutions requiring always-on microphone
- [ ] Voice-only interfaces (supplement to keyboard, not replacement)
- [ ] Real-time transcription streaming to container (latency issues)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Transcription accuracy | Must | High accuracy for technical content |
| Latency | Must | Fast enough for real-time dictation |
| Local processing | Must | Privacy, works offline |
| macOS support | Must | Primary development platform |
| Code awareness | High | Handles programming terminology |
| Ease of use | High | Simple activation, minimal setup |
| IDE integration | Medium | Can insert directly into editors |
| LLM post-processing | Medium | Cleans up and formats output |
| Price | Medium | Reasonable for individual developer |

## Tool Candidates

| Tool | License | Pros | Cons | Platform | Spike Result |
|------|---------|------|------|----------|--------------|
| Superwhisper | Commercial ($249 lifetime) | LLM post-processing, multiple AI models, offline mode, code-friendly | macOS only, commercial, some UI glitches reported | macOS | Pending |
| Wispr Flow | Commercial (subscription) | IDE integrations (Cursor, Windsurf), voice commands, developer-focused | Subscription model, newer product | macOS | Pending |
| MacWhisper | Commercial ($30-70) | Native macOS, clean UI, good quality | No LLM post-processing | macOS | Pending |
| Voibe | Commercial ($29) | Developer mode, workspace-aware, Apple Silicon optimized | Smaller community | macOS | Pending |
| Talon | Free (Patreon for beta) | Programmable, Cursorless integration, hands-free coding | Steep learning curve, complex setup | macOS, Linux, Windows | Pending |
| Whisper.cpp | MIT | Open source, local, fast on Apple Silicon | No GUI, requires integration work | Cross-platform | Pending |

## Detailed Analysis

### Superwhisper

**Source**: [Superwhisper](https://superwhisper.com/)

AI-powered dictation with LLM post-processing:

- **Models**: Nano, Fast, Pro, Ultra (accuracy vs speed tradeoff)
- **LLM integration**: OpenAI, Anthropic, Deepgram, Groq for cleanup
- **Offline**: Can work without internet using local models
- **Pricing**: $249 lifetime or subscription

Developer notes: Integrates well with AI coding workflows, can generate prompts for Cursor/Claude.

### Wispr Flow

**Source**: [Wispr Flow](https://wisprflow.ai/)

Developer-focused voice dictation:

- **IDE extensions**: Cursor and Windsurf plugins for file tagging, navigation
- **Voice commands**: Navigate code, run commands by voice
- **Flow mode**: Continuous dictation without manual start/stop
- **Developer focus**: Built for coding workflows

### MacWhisper

**Source**: [MacWhisper](https://goodsnooze.gumroad.com/l/macwhisper)

Native macOS Whisper interface:

- **Quality**: Good transcription using Whisper models
- **Native**: macOS native app, clean interface
- **Limitation**: No LLM post-processing (raw transcription only)

### Talon

**Source**: [Talon Voice](https://talonvoice.com/) | [Docs](https://talonvoice.com/docs/)

Programmable voice control for coding:

- **Voice coding**: Full hands-free development capability
- **Cursorless**: Integration for voice-based code navigation
- **Customization**: Highly programmable with Python
- **Eye tracking**: Optional gaze control
- **Learning curve**: Significant investment to learn

Developer notes: Most powerful for hands-free coding, but requires substantial learning investment.

### Whisper.cpp

**Source**: [GitHub - ggerganov/whisper.cpp](https://github.com/ggerganov/whisper.cpp)

Open-source Whisper implementation:

- **Performance**: Optimized for Apple Silicon, very fast
- **Local**: Fully offline, privacy-preserving
- **Flexibility**: Can be integrated into custom tools
- **No GUI**: Requires building integration layer

## Usage Patterns

### Pattern 1: Host-Side Dictation → Container IDE

```
[Microphone] → [Host Dictation App] → [Clipboard/Paste] → [Container IDE]
```

Voice input on host, text output pasted into container-based IDE.

### Pattern 2: Web-Based Voice Input

```
[Microphone] → [Browser Web Speech API] → [code-server IDE]
```

Browser handles voice input, text inserted into web-based IDE.

### Pattern 3: Full Voice Coding (Talon)

```
[Microphone] → [Talon] → [Commands/Text] → [VS Code + Cursorless]
```

Complete voice-based development with navigation and editing.

## Selected Approach

[Filled after spike]

## Acceptance Criteria

- [ ] Given voice dictation, when I speak code instructions, then accurate text is generated
- [ ] Given technical terms, when I speak library names (NumPy, FastAPI), then they're transcribed correctly
- [ ] Given a prompt, when I dictate to AI agent, then the agent receives clear instructions
- [ ] Given offline mode, when I dictate without internet, then transcription still works
- [ ] Given code context, when I mention variable names, then they're formatted correctly
- [ ] Given activation shortcut, when I trigger dictation, then it starts within 1 second
- [ ] Given LLM post-processing, when transcription completes, then output is cleaned and formatted

## Dependencies

- Requires: 008-prd-containerized-ide (IDE to receive dictated text)
- Blocks: none (input enhancement)

## Spike Tasks

### Tool Evaluation

- [ ] Test Superwhisper for coding workflow dictation
- [ ] Test Wispr Flow IDE integration
- [ ] Test MacWhisper for basic transcription
- [ ] Test Voibe developer mode features
- [ ] Evaluate Talon learning curve and Cursorless

### Accuracy Testing

- [ ] Test transcription of code terminology
- [ ] Test with library and framework names
- [ ] Test with variable naming conventions (camelCase, snake_case)
- [ ] Compare accuracy across tools

### Integration Testing

- [ ] Test dictation → code-server workflow
- [ ] Test dictation → Claude Code prompt workflow
- [ ] Test LLM post-processing effectiveness
- [ ] Measure end-to-end latency

### Workflow Design

- [ ] Document recommended voice dictation workflow
- [ ] Create custom vocabulary list for project
- [ ] Design voice command shortcuts (if using Talon)
- [ ] Create training materials for team

## References

- [Superwhisper](https://superwhisper.com/)
- [Wispr Flow](https://wisprflow.ai/)
- [Talon Voice](https://talonvoice.com/)
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- [Cursorless](https://www.cursorless.org/)
- [Voice Coding Review](https://samwize.com/2025/11/10/review-of-whispr-flow-superwhisper-macwhisper-for-vibe-coding/)
- [Hands-Free Coding with Talon](https://www.joshwcomeau.com/blog/hands-free-coding/)
- [Superwhisper Alternatives](https://www.getvoibe.com/blog/superwhisper-alternatives/)
