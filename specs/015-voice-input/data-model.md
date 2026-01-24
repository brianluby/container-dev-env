# Data Model: Voice Input for AI Coding Prompts

**Generated**: 2026-01-23
**Source**: Feature spec + research findings

## Entities

### DictationSession

A single voice input episode from activation to text output.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | Unique session identifier | Auto-generated |
| state | SessionState | Current session state | Required, enum |
| started_at | DateTime | When recording began | Set on activation |
| ended_at | DateTime | When recording stopped | Set on silence/release |
| transcription_completed_at | DateTime | When text was ready | Set after processing |
| raw_audio | AudioBuffer | In-memory audio data | Never persisted to disk |
| activation_method | ActivationMethod | How session was started | Required, enum |
| cancel_reason | CancelReason | Why session was cancelled | Nullable |

**State Machine**:

```
IDLE -> RECORDING -> PROCESSING -> COMPLETE -> IDLE
  |                     |             |
  |                     v             v
  +--- CANCELLED <------+-------------+
```

**Validation Rules**:
- Audio buffer MUST be cleared when state transitions to COMPLETE or CANCELLED
- Session duration MUST NOT exceed configurable max (default: 5 minutes)
- Processing MUST complete within 2 seconds of recording end

### Transcription

The text output produced from a DictationSession.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | Unique transcription identifier | Auto-generated |
| session_id | UUID | Reference to parent session | Required, FK |
| raw_text | String | Direct speech-to-text output | Required |
| cleaned_text | String | Post-cleanup formatted text | Nullable (if cleanup disabled) |
| cleanup_tier | CleanupTier | Which cleanup level was applied | Required, enum |
| cleanup_provider | String | Which provider did cleanup | Nullable |
| confidence | Float | Transcription confidence score | 0.0-1.0, from STT engine |
| language | String | Detected spoken language | ISO 639-1 code |
| output_method | OutputMethod | How text was delivered | Required, enum |

**Validation Rules**:
- raw_text MUST NOT be empty for COMPLETE sessions
- cleaned_text is only set when cleanup_tier > NONE
- If cleanup_tier is CLOUD, cleanup_provider MUST be set

### CustomVocabulary

User-configurable terms for improved recognition accuracy.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| term | String | The vocabulary term | Required, unique per project |
| spoken_forms | List[String] | How the term might be spoken | At least one entry |
| display_form | String | How the term should appear in output | Required |
| category | VocabCategory | Classification of the term | Required, enum |
| project | String | Project scope (or "global") | Default: "global" |
| enabled | Boolean | Whether term is active | Default: true |

**Example Entries**:
```yaml
- term: getUserById
  spoken_forms: ["get user by id", "get user by ID"]
  display_form: getUserById
  category: function_name
  project: global

- term: PostgreSQL
  spoken_forms: ["postgres", "postgresql", "post gres"]
  display_form: PostgreSQL
  category: technology
  project: global

- term: container-dev-env
  spoken_forms: ["container dev env", "container dev environment"]
  display_form: container-dev-env
  category: project_name
  project: container-dev-env
```

### VoiceInputSettings

Configuration for the voice input system.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| activation_shortcut | KeyCombo | Keyboard shortcut for activation | Required |
| activation_mode | ActivationMode | Toggle or push-to-talk | Default: push_to_talk |
| silence_timeout_ms | Integer | Pause duration before auto-stop | Default: 1500, range: 500-5000 |
| max_recording_duration_s | Integer | Maximum recording time | Default: 300 |
| whisper_model | WhisperModel | Which local model to use | Default: large-v3 |
| cleanup_tier | CleanupTier | Default cleanup level | Default: RULES |
| cleanup_cloud_provider | String | Cloud provider for Tier 3 | Nullable |
| cleanup_cloud_api_key_env | String | Env var name for API key | Nullable, never stores key directly |
| output_method | OutputMethod | How to deliver transcription | Default: clipboard |
| language | String | Expected spoken language | Default: "en" |
| custom_vocab_paths | List[Path] | Paths to vocabulary files | Default: [~/.config/voice-input/vocabulary.yaml] |
| visual_feedback | Boolean | Show recording indicator | Default: true |

## Enums

### SessionState
- `IDLE` - No active session
- `RECORDING` - Capturing audio
- `PROCESSING` - Transcribing audio to text
- `COMPLETE` - Text available
- `CANCELLED` - Session aborted by user

### ActivationMethod
- `SHORTCUT_TOGGLE` - Pressed shortcut to start, pressed again to stop
- `SHORTCUT_HOLD` - Held shortcut key, released to stop

### ActivationMode
- `PUSH_TO_TALK` - Hold key to record
- `TOGGLE` - Press to start/stop

### CleanupTier
- `NONE` - Raw transcription only
- `RULES` - Local rule-based cleanup (default)
- `LOCAL_LLM` - Local model cleanup (Ollama/MLX)
- `CLOUD` - Cloud API cleanup (opt-in)

### OutputMethod
- `CLIPBOARD` - Copy to system clipboard (only supported method in this version)

### CancelReason
- `USER_ESCAPE` - User pressed Escape
- `USER_SHORTCUT` - User pressed activation shortcut again
- `TIMEOUT` - Max recording duration exceeded
- `ERROR` - System error (mic unavailable, etc.)

### VocabCategory
- `function_name` - Function/method names
- `variable_name` - Variable names
- `technology` - Library/framework/tool names
- `project_name` - Project-specific names
- `domain_term` - Domain-specific terminology
- `custom` - User-defined category

### WhisperModel
- `tiny` - Fastest, lowest accuracy (~39M params)
- `base` - Fast, basic accuracy (~74M params)
- `small` - Balanced (~244M params)
- `medium` - Good accuracy (~769M params)
- `large-v3` - Best accuracy (~1.5B params, recommended)
- `turbo` - Optimized large model (if available)

## Relationships

```
VoiceInputSettings (1) ----configures----> DictationSession (*)
DictationSession (1) ----produces----> Transcription (0..1)
CustomVocabulary (*) ----improves----> Transcription (*)
VoiceInputSettings (1) ----references----> CustomVocabulary (*)
```

## Storage

### Configuration Files (Chezmoi-managed)

```
~/.config/voice-input/
├── settings.yaml         # VoiceInputSettings
├── vocabulary.yaml       # CustomVocabulary entries (uses `project` field per-term)
└── ai-cleanup-prompt.txt # AI cleanup system prompt
```

Note: Project-specific terms are differentiated by the `project` field on each vocabulary term entry, not by separate files. This keeps configuration simple while supporting per-project scoping.

### Runtime State (In-Memory Only)

- DictationSession: Lives only in application memory during active use
- Audio buffers: Never written to disk, cleared after processing
- Transcription: Held in memory until delivered to output, then discarded

### No Persistent Storage

Per privacy requirements:
- No audio recordings stored
- No transcription history database
- No session logs with content
- Settings and vocabulary are the only persisted data
