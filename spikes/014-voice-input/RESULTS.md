# Spike Results: 014 - Voice Input

**PRD**: prds/014-prd-voice-input.md
**Status**: Complete
**Date**: 2026-01-21

## Summary

This spike evaluated voice input solutions for the containerized development environment, focusing on developer-specific dictation for AI coding agents. Six tools were researched against the PRD requirements.

## Key Findings

### Market Landscape (2025-2026)

The voice-to-text market for developers has matured significantly:
- **All tools** now run locally on Apple Silicon with excellent performance
- **Developer-focused tools** (Wispr Flow, Voibe) have emerged specifically for coding workflows
- **LLM post-processing** is differentiating but not always necessary
- **IDE integration** varies significantly between tools

### Winner: Wispr Flow (Recommended)

**Wispr Flow** best meets the PRD requirements for the following reasons:

1. **Developer Focus**: Built specifically for coding workflows with Cursor, VS Code, Windsurf integration
2. **Code Awareness**: Recognizes syntax, variable names, technical terms (500+ patterns/second)
3. **Cross-Platform**: Works on macOS, Windows, and iOS
4. **Privacy Options**: Zero Data Retention mode available
5. **Free Tier**: 2,000 words/week for evaluation
6. **Low Learning Curve**: Works immediately, no complex setup

**Trade-off**: Subscription model ($15/month) vs one-time purchase alternatives.

### Runner-Up: Voibe

**Voibe** is an excellent alternative for Apple Silicon-only environments:

1. **File Path Recognition**: Automatically recognizes and formats file paths, folder names
2. **Developer-Built**: Created by a developer for AI coding workflows
3. **100% Local**: No cloud processing whatsoever
4. **Deep IDE Integration**: Works with Cursor, VS Code, Windsurf
5. **Lifetime Option**: One-time purchase available

**Trade-off**: Apple Silicon only (no Intel Mac support).

### For Hands-Free Coding: Talon + Cursorless

For users with accessibility needs or who want complete hands-free development:

1. **Full Voice Coding**: Complete keyboard/mouse replacement
2. **Cursorless**: Structural code editing with voice
3. **Free**: No cost (Patreon for beta features)
4. **Cross-Platform**: macOS, Windows, Linux

**Trade-off**: Significant learning investment (weeks to months).

### Not Recommended for Primary Use

| Tool | Reason |
|------|--------|
| **Superwhisper** | Mixed reviews on code terminology handling; competitors have caught up |
| **MacWhisper** | No code awareness; better for transcription than dictation |
| **whisper.cpp** | Requires significant integration work; better as foundation for custom tools |

## Usage Patterns Evaluation

### Pattern 1: Host-Side Dictation → Container IDE (Recommended)

```
[Microphone] → [Wispr Flow/Voibe on Host] → [Clipboard] → [Container IDE]
```

**Verdict**: Works well. Voice input on macOS host, paste into code-server or VS Code in container.

**Workflow**:
1. Install Wispr Flow or Voibe on macOS host
2. Configure keyboard shortcut (e.g., Option+Space)
3. Dictate prompt for Claude Code or code for editor
4. Text automatically available in any app (including container IDE via clipboard)

### Pattern 2: Web-Based Voice Input

```
[Microphone] → [Browser Web Speech API] → [code-server IDE]
```

**Verdict**: Not recommended. Browser speech APIs are cloud-based (privacy concern) and less accurate for technical content.

### Pattern 3: Full Voice Coding (Talon)

```
[Microphone] → [Talon] → [Commands/Text] → [VS Code + Cursorless]
```

**Verdict**: Best for accessibility needs. Requires significant time investment but enables complete hands-free development.

## Recommended Architecture

### For This Project (container-dev-env)

```
┌─────────────────────────────────────────────────────────┐
│                      macOS Host                         │
│  ┌─────────────────┐     ┌───────────────────────────┐  │
│  │   Wispr Flow    │────>│ System Clipboard          │  │
│  │   (Voice Input) │     │ (Shared with container)   │  │
│  └─────────────────┘     └───────────────────────────┘  │
│         │                           │                    │
│         ▼                           ▼                    │
│  ┌─────────────────┐     ┌───────────────────────────┐  │
│  │ Claude Code CLI │     │ Docker Container          │  │
│  │ (Terminal)      │     │ ┌───────────────────────┐ │  │
│  └─────────────────┘     │ │ code-server / VS Code │ │  │
│                          │ │ (receives pasted text)│ │  │
│                          │ └───────────────────────┘ │  │
│                          └───────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Workflow Steps

1. **Activate voice input**: Press shortcut (e.g., `Cmd+Shift+Space`)
2. **Dictate**: "Create a FastAPI endpoint that returns user profile data with ID validation"
3. **Voice tool processes**: Formats technical terms, adds context
4. **Text appears**: In focused application (terminal for Claude Code, editor for code)
5. **Continue workflow**: Submit to AI agent or edit as needed

## Implementation Recommendations

### Phase 1: Evaluation (Immediate)

1. Install **Wispr Flow** (free tier: 2,000 words/week)
2. Configure keyboard shortcut for quick activation
3. Test with Claude Code prompts and code-server
4. Run accuracy tests using `tests/accuracy-test-methodology.md`

### Phase 2: Adoption

Based on evaluation results:
- If Wispr Flow meets needs: Subscribe to Pro ($15/month)
- If Apple Silicon exclusive is OK: Try Voibe (lifetime option)
- If hands-free needed: Begin Talon learning journey

### Phase 3: Optimization

1. Create custom vocabulary for project-specific terms
2. Document voice dictation best practices for team
3. Consider LLM post-processing pipeline (if not using Superwhisper)

## Accuracy Testing

See `tests/accuracy-test-methodology.md` for detailed test procedures.

### Quick Test Script

```bash
# Technical terms to test voice input accuracy
echo "Test phrases for voice input evaluation:"
echo "1. Create a FastAPI endpoint that returns JSON"
echo "2. Import NumPy and Pandas for data analysis"
echo "3. Configure the PostgreSQL connection string"
echo "4. Use async await with TypeScript fetch API"
echo "5. The React useState hook initializes empty array"
```

## Cost Analysis

### Annual Cost Comparison

| Tool | Year 1 | Year 2+ | 3-Year Total |
|------|--------|---------|--------------|
| Wispr Flow Pro | $144 | $144 | $432 |
| Superwhisper Pro | $85 | $85 | $255 |
| Superwhisper Lifetime | $249 | $0 | $249 |
| MacWhisper Lifetime | $80 | $0 | $80 |
| Voibe Lifetime | ~$99 | $0 | ~$99 |
| Talon | $0 | $0 | $0 |

**Recommendation**: For consistent use, Wispr Flow Pro or a lifetime option (Voibe, Superwhisper) provides best value.

## Open Questions

1. **Clipboard latency**: Need to measure clipboard sync time between host and container
2. **Wispr Flow Linux**: Windows support exists; Linux would eliminate host dependency
3. **Custom vocabulary**: How much improvement from project-specific training?
4. **LLM post-processing**: Worth adding to non-Superwhisper tools?

## Files Created

```
spikes/014-voice-input/
├── research/
│   └── tool-research.md        # Detailed tool analysis
├── tests/
│   └── accuracy-test-methodology.md  # Test procedures
├── docs/
│   └── tool-comparison.md      # Comparison matrices
└── RESULTS.md                  # This file
```

## Next Steps

1. [ ] Install Wispr Flow and run accuracy tests
2. [ ] Test clipboard workflow with code-server container
3. [ ] Evaluate Voibe as alternative for Apple Silicon
4. [ ] Document voice dictation workflow for team
5. [ ] Consider Talon evaluation for accessibility needs

## References

- [Wispr Flow](https://wisprflow.ai/)
- [Voibe](https://www.getvoibe.com/)
- [Superwhisper](https://superwhisper.com/)
- [Talon Voice](https://talonvoice.com/)
- [Cursorless](https://www.cursorless.org/)
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
- [Voice Coding Review (samwize)](https://samwize.com/2025/11/10/review-of-whispr-flow-superwhisper-macwhisper-for-vibe-coding/)
- [Hands-Free Coding with Talon (Josh Comeau)](https://www.joshwcomeau.com/blog/hands-free-coding/)
- [Wispr Flow Review 2026](https://vibecoding.app/blog/wispr-flow-review)
