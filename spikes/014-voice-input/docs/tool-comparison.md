# Voice Input Tool Comparison Matrix

## Quick Reference

| Feature | Superwhisper | Wispr Flow | MacWhisper | Voibe | Talon | whisper.cpp |
|---------|-------------|------------|------------|-------|-------|-------------|
| **Price** | $49-249 | Free-$15/mo | $30-80 | ~$29-99 | Free | Free (MIT) |
| **Platform** | macOS | Mac/Win/iOS | macOS | macOS (M1+) | All | All |
| **Local Processing** | Yes | Yes | Yes | Yes | Yes | Yes |
| **LLM Post-Processing** | Yes | No | No | No | No | DIY |
| **IDE Integration** | Clipboard | Deep | Clipboard | Deep | Full | DIY |
| **Developer Focus** | Medium | High | Low | High | High | DIY |
| **Learning Curve** | Medium | Low | Low | Low | High | High |
| **Code Awareness** | Moderate | High | Low | High | Full | DIY |

## Detailed Comparison

### Pricing Breakdown

| Tool | Free Tier | Monthly | Annual | Lifetime |
|------|-----------|---------|--------|----------|
| Superwhisper | Limited | $8.49 | $84.99 | $249 |
| Wispr Flow | 2k words/wk | $15 | $144 | N/A |
| MacWhisper | Limited | $8.99 | $29.99 | $79.99 |
| Voibe | Trial | Yes | Yes | Yes |
| Talon | Full | N/A | N/A | Free |
| whisper.cpp | Full | N/A | N/A | Free (OSS) |

### Platform Support

| Tool | macOS Intel | macOS Apple Silicon | Windows | Linux | iOS |
|------|-------------|---------------------|---------|-------|-----|
| Superwhisper | Yes | Yes | No | No | Yes |
| Wispr Flow | Yes | Yes | Yes | No | Yes |
| MacWhisper | Slow | Yes | No | No | No |
| Voibe | No | Yes | No | No | No |
| Talon | Yes | Yes | Yes | Yes | No |
| whisper.cpp | Yes | Yes (fast) | Yes | Yes | Via port |

### Developer Features

| Feature | Superwhisper | Wispr Flow | MacWhisper | Voibe | Talon |
|---------|-------------|------------|------------|-------|-------|
| IDE Plugin | No | Yes | No | Yes | Yes |
| Code Syntax Aware | Moderate | Yes | No | Yes | Full |
| Variable Name Handling | Mixed reviews | Good | No | Excellent | Full |
| File Path Recognition | No | Limited | No | Yes | Yes |
| Custom Vocabulary | Via prompts | Built-in | No | Built-in | Yes |
| Voice Commands | No | Limited | No | No | Full |

### Privacy & Offline

| Tool | Fully Offline | Data Retention | Audio Upload |
|------|---------------|----------------|--------------|
| Superwhisper | Yes | None | Never |
| Wispr Flow | Optional | Zero mode | Optional |
| MacWhisper | Yes | None | Never |
| Voibe | Yes | None | Never |
| Talon | Yes | None | Never |
| whisper.cpp | Yes | None | Never |

### Integration with AI Coding Agents

| Use Case | Best Tool | Notes |
|----------|-----------|-------|
| Claude Code prompts | Wispr Flow, Voibe | Developer-aware formatting |
| Cursor/Windsurf IDE | Wispr Flow | Direct plugin integration |
| VS Code general | Voibe, Wispr Flow | Good context awareness |
| code-server (web) | Any (clipboard) | All work via paste |
| Full voice coding | Talon + Cursorless | Complete hands-free |

### Accuracy Indicators (from reviews)

| Tool | General Accuracy | Technical Terms | Code Formatting |
|------|-----------------|-----------------|-----------------|
| Superwhisper | High | Mixed (inconsistent) | Via LLM prompt |
| Wispr Flow | High | Excellent | Good built-in |
| MacWhisper | High | Moderate | None |
| Voibe | High | Excellent | Good built-in |
| Talon | High | Excellent | Full control |
| whisper.cpp | High | Model-dependent | None |

## Evaluation Against PRD Requirements

### Must Have Requirements

| Requirement | Superwhisper | Wispr Flow | MacWhisper | Voibe | Talon | whisper.cpp |
|-------------|-------------|------------|------------|-------|-------|-------------|
| High accuracy | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Works with AI agents | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Low latency | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| Technical vocabulary | ⚠️ | ✅ | ❌ | ✅ | ✅ | ⚠️ |
| macOS support | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Privacy (local) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### Should Have Requirements

| Requirement | Superwhisper | Wispr Flow | MacWhisper | Voibe | Talon | whisper.cpp |
|-------------|-------------|------------|------------|-------|-------|-------------|
| Code-aware formatting | ⚠️ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Multi-language | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Custom vocabulary | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Keyboard shortcut | ✅ | ✅ | ✅ | ✅ | ✅ | DIY |
| IDE integration | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| LLM post-processing | ✅ | ❌ | ❌ | ❌ | ❌ | DIY |

### Could Have Requirements

| Requirement | Superwhisper | Wispr Flow | MacWhisper | Voibe | Talon | whisper.cpp |
|-------------|-------------|------------|------------|-------|-------|-------------|
| Linux support | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Voice commands | ❌ | ⚠️ | ❌ | ❌ | ✅ | ❌ |
| Cursorless | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |

Legend: ✅ = Yes, ⚠️ = Partial/Mixed, ❌ = No, DIY = Requires custom work

## Recommendation Summary

### For Quick Adoption (Low Learning Curve)

1. **Wispr Flow** - Best IDE integration, developer-focused, good free tier
2. **Voibe** - Excellent for Apple Silicon, file path awareness, developer-built
3. **Superwhisper** - LLM post-processing, but mixed code term handling

### For Maximum Control

1. **Talon + Cursorless** - Full hands-free coding, but significant learning investment
2. **whisper.cpp** - Build custom solution, most flexible, requires development

### For Budget-Conscious

1. **Talon** - Free, most powerful
2. **whisper.cpp** - Free, open source
3. **Wispr Flow Free** - 2,000 words/week sufficient for testing

### For Container/Linux Use

1. **Talon** - Native Linux support
2. **whisper.cpp** - Cross-platform
3. Others require host-side macOS with clipboard workflow
