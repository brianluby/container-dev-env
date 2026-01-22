# Technical Specification Document: 014-voice-input

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/014-voice-input/` and `prds/014-prd-voice-input.md`

## 1. Executive Summary

This document defines the technical approach for Voice Input. Due to container audio limitations, the architecture enforces **Host-Side Processing** (Pattern 1), injecting text into the container via Clipboard or API.

## 2. Technical Specifications

### 2.1 Architecture: Pattern 1 (Host Injection)
1.  **Host App** (e.g., Superwhisper, macOS Dictation) captures audio.
2.  **Processing**: Local STT (Speech-to-Text) on Host.
3.  **Transport**:
    *   **Clipboard**: Text copied to host clipboard, pasted into IDE (requires clipboard sync).
    *   **HTTP**: Host app posts text to `http://localhost:3000/api/voice` (if code-server supports it).

### 2.2 Container Support
*   **Clipboard Sync**: Use `osc52` (terminal) or browser clipboard API (code-server).

## 3. Data Models

### 3.1 Vocabulary
*   `custom_dictionary.txt`: A list of project-specific terms ("Kubernetes", "gRPC") to train/hint the host STT model.

## 4. API Contracts & Interfaces

### 4.1 Clipboard Contract
*   The container environment MUST support `OSC 52` escape sequences to allow remote clipboard writing from the host terminal emulator.

## 5. Architectural Improvements

### 5.1 Latency Reduction
**Problem**: Clipboard sync can be slow or blocked by browsers.
**Solution**: Recommend **Web Speech API** (Pattern 2) for `code-server` usage.
*   **Implementation**: A browser extension or bookmarklet that captures audio in the browser and types it into the active editor element.

## 6. Testing Strategy
*   **Latency Test**: Measure time from "end of speech" to "text appearance". Target < 1s.
*   **Vocabulary Test**: Dictate technical jargon and verify transcription accuracy.
