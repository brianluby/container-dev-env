# Event Contract: Voice Input System

**Generated**: 2026-01-23

## Overview

The voice input system uses an event-driven model for state transitions. These events are primarily internal to the voice tool but are documented for integration purposes.

## Events

### session.started

Emitted when a dictation session begins.

```json
{
  "event": "session.started",
  "session_id": "uuid",
  "timestamp": "ISO-8601",
  "activation_method": "SHORTCUT_HOLD | SHORTCUT_TOGGLE",
  "whisper_model": "large-v3"
}
```

### session.recording

Emitted periodically during recording (for UI feedback).

```json
{
  "event": "session.recording",
  "session_id": "uuid",
  "duration_ms": 1500,
  "audio_level": 0.73
}
```

### session.processing

Emitted when recording stops and transcription begins.

```json
{
  "event": "session.processing",
  "session_id": "uuid",
  "recording_duration_ms": 3200
}
```

### session.transcribed

Emitted when raw transcription is ready.

```json
{
  "event": "session.transcribed",
  "session_id": "uuid",
  "raw_text": "create a function that validates emails",
  "confidence": 0.94,
  "language": "en",
  "transcription_time_ms": 1200
}
```

### session.cleaned

Emitted when AI cleanup completes (if enabled).

```json
{
  "event": "session.cleaned",
  "session_id": "uuid",
  "cleaned_text": "Create a function that validates emails.",
  "cleanup_tier": "rules | local_llm | cloud",
  "cleanup_time_ms": 150,
  "provider": "rule-engine | ollama:phi3 | claude-haiku"
}
```

### session.complete

Emitted when text is delivered to output.

```json
{
  "event": "session.complete",
  "session_id": "uuid",
  "final_text": "Create a function that validates emails.",
  "output_method": "clipboard | direct_input | both",
  "total_time_ms": 2800
}
```

### session.cancelled

Emitted when a session is cancelled.

```json
{
  "event": "session.cancelled",
  "session_id": "uuid",
  "cancel_reason": "USER_ESCAPE | USER_SHORTCUT | TIMEOUT | ERROR",
  "recording_duration_ms": 500
}
```

### session.error

Emitted on error conditions.

```json
{
  "event": "session.error",
  "session_id": "uuid",
  "error_code": "MIC_UNAVAILABLE | MODEL_LOAD_FAILED | CLEANUP_FAILED | PERMISSION_DENIED",
  "error_message": "Microphone access denied. Please enable in System Settings.",
  "fallback_action": "none | use_raw_text"
}
```

## Error Handling

All errors follow graceful degradation:
1. Cleanup errors -> Fall back to raw transcription
2. Model errors -> Notify user, suggest smaller model
3. Permission errors -> Guide user to System Settings
4. Microphone errors -> Clear error message, no silent failure
