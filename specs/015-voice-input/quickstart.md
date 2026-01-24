# Quickstart: Voice Input for AI Coding Prompts

**Generated**: 2026-01-23

## Prerequisites

- macOS 14 (Sonoma) or later on Apple Silicon (M1/M2/M3/M4)
- Microphone access (built-in MacBook mic is sufficient)
- ~2GB disk space for Whisper models
- For AI cleanup Tier 2: Ollama installed (`brew install ollama`)
- For AI cleanup Tier 3: Claude/OpenAI API key (optional, opt-in)

## Installation

### Option A: Superwhisper (Recommended)

1. Purchase Superwhisper Pro ($8.49/month or $249.99 lifetime) from [superwhisper.com](https://superwhisper.com)
2. Install from Mac App Store or download directly
3. Grant permissions when prompted:
   - Microphone access
   - Accessibility access
   - Input Monitoring
4. Download the `large-v3` Whisper model (first-time setup, ~3GB download)

### Option B: VoiceInk (Budget Alternative)

1. Purchase VoiceInk ($25-49) from [tryvoiceink.com](https://tryvoiceink.com) or build from [source](https://github.com/Beingpax/VoiceInk)
2. Install and grant permissions (same as above)
3. Download Whisper model of choice

## Configuration

### 1. Keyboard Shortcut Setup

```yaml
# ~/.config/voice-input/settings.yaml
activation_shortcut: "RightCommand"  # Single key, no conflicts
activation_mode: push_to_talk        # Hold to record, release to process
silence_timeout_ms: 1500             # Auto-stop after 1.5s silence
output_method: clipboard             # Copy result to clipboard
```

**In Superwhisper**:
1. Open Preferences > Shortcuts
2. Set "Start/Stop Recording" to Right Command
3. Enable "Push-to-Talk" mode
4. Set "Cancel Recording" to Escape

### 2. AI Cleanup Configuration

```yaml
# ~/.config/voice-input/cleanup.yaml
cleanup_tier: rules          # Default: local rules only (no network)
# cleanup_tier: local_llm   # Optional: use local Ollama model
# cleanup_tier: cloud        # Optional: use Claude API (opt-in)

# Tier 2 settings (if using local_llm)
local_llm:
  provider: ollama
  model: phi3:mini           # or qwen2.5:3b
  endpoint: http://localhost:11434

# Tier 3 settings (if using cloud, opt-in only)
cloud:
  provider: claude
  model: claude-haiku
  api_key_env: ANTHROPIC_API_KEY  # Never store key in config
  confirm_before_send: true       # Show what will be sent
```

### 3. Custom Vocabulary

```yaml
# ~/.config/voice-input/vocabulary.yaml
terms:
  - term: React
    spoken_forms: ["react", "react js"]
    display_form: React
    category: technology

  - term: TypeScript
    spoken_forms: ["typescript", "type script"]
    display_form: TypeScript
    category: technology

  - term: getUserById
    spoken_forms: ["get user by id", "get user by ID"]
    display_form: getUserById
    category: function_name

  # Add your project-specific terms here
```

### 4. Superwhisper Mode Setup (Recommended)

Create a "Code Dictation" mode in Superwhisper:
1. Open Preferences > Modes
2. Create new mode: "Code Dictation"
3. Set AI model: `large-v3` (local)
4. Enable custom vocabulary
5. Set app triggers: Activate in Terminal, VS Code, code-server

## Usage

### Basic Workflow

1. **Activate**: Hold Right Command (or configured shortcut)
2. **Speak**: Dictate your instruction naturally
3. **Release**: Let go of the key
4. **Wait**: Transcription processes in <2 seconds
5. **Paste**: Cmd+V into your AI agent's input

### Example Dictation

**You say**: "Create a function that validates email addresses using regex and returns a boolean. It should handle edge cases like plus addressing and subdomains."

**You get**: "Create a function that validates email addresses using regex and returns a boolean. It should handle edge cases like plus addressing and subdomains."

### With AI Cleanup (Tier 2/3)

**You say**: "add a new endpoint to the users API that accepts a user id parameter and returns the user profile with their recent activity"

**Cleanup produces**: "Add a new endpoint to the users API that accepts a userId parameter and returns the user profile with their recent activity."

### Integration with Container IDE

1. Dictate on host (voice input runs on macOS)
2. Text is copied to clipboard
3. Switch to browser (code-server) or terminal
4. Paste with Cmd+V
5. Text arrives in the container IDE input

## Verification

### Test 1: Basic Dictation
- Press and hold your shortcut
- Say: "Hello world this is a test"
- Release the shortcut
- Verify text appears on clipboard (Cmd+V to paste somewhere)

### Test 2: Offline Mode
- Disconnect from internet
- Repeat Test 1
- Verify dictation works without network

### Test 3: Technical Terms
- Say: "Create a React component using TypeScript with useState hook"
- Verify "React", "TypeScript", and "useState" are correctly transcribed

### Test 4: Container Integration
- Open code-server in browser
- Dictate a prompt on host
- Paste into code-server terminal
- Verify text arrives correctly

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Shortcut doesn't activate | Check Accessibility permissions in System Settings > Privacy |
| Poor accuracy | Switch to larger Whisper model; check microphone input level |
| Slow transcription | Use `medium` model instead of `large-v3` for faster results |
| AI cleanup not working | Verify Ollama is running: `ollama serve` |
| Text not pasting in browser | Ensure clipboard permission granted; try Cmd+Shift+V |
