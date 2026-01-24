# Feature Specification: Voice Input for AI Coding Prompts

**Feature Branch**: `015-voice-input`
**Created**: 2026-01-23
**Status**: Draft
**Input**: User description: "Voice-to-text dictation enabling developers to speak instructions to AI coding agents instead of typing, with local privacy-preserving processing and support for technical vocabulary"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Dictates Complex Instructions to AI (Priority: P1)

A developer needs to explain a complex feature requirement to their AI coding assistant. Instead of typing a lengthy paragraph, they press a keyboard shortcut to activate dictation, speak naturally describing what they want, and the transcribed text appears ready to send to the AI agent. The transcription accurately captures technical terminology like library names and coding patterns.

**Why this priority**: This is the core value proposition—replacing slow typing of complex prompts with fast natural speech. It delivers immediate productivity gains for the most common and time-consuming interaction pattern with AI agents.

**Independent Test**: Can be tested by activating voice dictation, speaking a technical instruction (e.g., "Create a function that validates email addresses using the pattern from our utils module"), and verifying accurate transcription appears in the IDE.

**Acceptance Scenarios**:

1. **Given** voice dictation is configured and active, **When** a developer speaks a coding instruction clearly, **Then** the spoken words are transcribed to text with at least 95% accuracy for general language.
2. **Given** voice dictation is active, **When** a developer speaks technical terms (library names, framework names, programming concepts), **Then** at least 90% of technical terms are transcribed correctly.
3. **Given** transcribed text is available, **When** the developer pastes it into the AI agent's input, **Then** the AI receives clear, usable instructions.
4. **Given** the developer finishes speaking, **When** transcription completes, **Then** the text is available within 2 seconds of the last spoken word.

---

### User Story 2 - Privacy-Preserving Local Processing (Priority: P1)

A developer dictates instructions that may reference proprietary code, internal architecture, or sensitive project details. All voice processing happens locally on their machine—no audio or transcriptions are sent to external services unless the developer explicitly enables optional cloud-based cleanup.

**Why this priority**: Developers routinely dictate information about proprietary codebases. Privacy is a non-negotiable requirement—without it, voice input is unusable for professional development work.

**Independent Test**: Can be tested by enabling offline mode, disconnecting from the internet, and verifying dictation still works correctly with no external network calls.

**Acceptance Scenarios**:

1. **Given** offline/local mode is enabled, **When** the developer dictates instructions, **Then** all processing happens on the local machine with no network requests.
2. **Given** no internet connection, **When** the developer activates dictation, **Then** transcription still works correctly.
3. **Given** the voice system is running, **When** audio is captured, **Then** no audio recordings are stored permanently on disk.
4. **Given** push-to-talk mode, **When** the developer has not pressed the activation shortcut, **Then** no audio is captured or processed.

---

### User Story 3 - Quick Activation via Keyboard Shortcut (Priority: P1)

A developer is in the middle of coding and wants to quickly dictate a prompt to their AI assistant. They press a single keyboard shortcut to start dictation, speak their instruction, and dictation automatically stops after a pause. The entire interaction takes seconds and doesn't require mouse clicks or navigating menus.

**Why this priority**: If activation is slow or cumbersome, developers will default to typing. The shortcut must be as natural as pressing a key to start a conversation.

**Independent Test**: Can be tested by pressing the configured shortcut, verifying dictation begins within 1 second, and confirming the entire flow (shortcut → speak → text ready) takes under 5 seconds for a short phrase.

**Acceptance Scenarios**:

1. **Given** voice input is configured, **When** the developer presses the activation shortcut, **Then** dictation begins within 1 second.
2. **Given** dictation is active, **When** the developer stops speaking for a configured pause duration, **Then** dictation ends and text is finalized.
3. **Given** the shortcut is configurable, **When** the developer changes the shortcut, **Then** the new shortcut activates dictation.

---

### User Story 4 - AI-Powered Transcription Cleanup (Priority: P2)

After raw transcription, an optional AI cleanup step formats the text appropriately for coding context—correcting technical terms, adding proper punctuation, and formatting variable names in the appropriate style (camelCase, snake_case). This produces cleaner prompts without the developer needing to edit.

**Why this priority**: Raw transcription often produces "spoken" text that needs reformatting for coding context. Cleanup significantly improves the quality of AI prompts. However, the system provides value without it (raw transcription is still faster than typing).

**Independent Test**: Can be tested by dictating "create a function called get user by ID that takes a user ID parameter" and verifying the cleanup produces something like "Create a function called getUserById that takes a userId parameter."

**Acceptance Scenarios**:

1. **Given** AI cleanup is enabled, **When** transcription completes, **Then** the output text has improved formatting, punctuation, and technical term capitalization.
2. **Given** AI cleanup is enabled, **When** the developer mentions variable-like terms, **Then** they are formatted in appropriate coding conventions.
3. **Given** AI cleanup is unavailable (API down or disabled), **When** transcription completes, **Then** raw transcription is provided as fallback without blocking the workflow.
4. **Given** the developer has disabled AI cleanup for privacy, **When** transcription completes, **Then** no text is sent to any external service.

---

### User Story 5 - Integration with Containerized IDE Workflow (Priority: P2)

The voice input system works seamlessly with the containerized development environment. Transcribed text can be pasted into the browser-based IDE (code-server) or terminal-based AI tools running inside the container, providing the same voice input experience as using a local IDE.

**Why this priority**: The container-dev-env is the target environment. Voice input must work with this specific workflow, not just local IDEs.

**Independent Test**: Can be tested by dictating text and pasting it into a code-server instance running in a container, verifying the text arrives correctly.

**Acceptance Scenarios**:

1. **Given** transcribed text is on the clipboard, **When** the developer pastes into the container IDE, **Then** the text is inserted correctly.
2. **Given** the developer is using a browser-based IDE, **When** they paste dictated text, **Then** special characters and formatting are preserved.
3. **Given** the developer is using a terminal-based AI tool (Claude Code), **When** they paste dictated text, **Then** the text is inserted correctly.

---

### User Story 6 - Custom Vocabulary for Project Terms (Priority: P3)

A developer works on a project with domain-specific terminology, custom library names, or internal project names. They can add these terms to a custom vocabulary that improves transcription accuracy for project-specific language.

**Why this priority**: Custom vocabulary improves accuracy for terms the base model doesn't know. However, the system is useful without it for standard technical terminology.

**Independent Test**: Can be tested by adding a custom term to the vocabulary, dictating a sentence using that term, and verifying it's transcribed correctly.

**Acceptance Scenarios**:

1. **Given** custom vocabulary is configured with project-specific terms, **When** the developer speaks those terms, **Then** they are transcribed more accurately than without custom vocabulary.
2. **Given** the vocabulary configuration, **When** the developer adds a new term, **Then** it takes effect on the next dictation session.

---

### Edge Cases

- What happens when background noise is high? Transcription accuracy should degrade gracefully, and the developer should be able to review and correct before sending.
- How does the system handle the developer speaking code syntax literally (e.g., "open paren, close paren")? This should be transcribed as spoken text, not interpreted as code—voice is for natural language instructions, not code dictation.
- What happens when the developer accidentally activates dictation? There should be an easy way to cancel (press shortcut again or Escape) without the partial transcription being used.
- How does the system behave when the microphone is not available or permission is denied? A clear error message should indicate the problem.
- What happens when the developer switches between apps while dictating? Dictation should continue capturing in the voice app regardless of the focused window.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide voice-to-text transcription with at least 95% general accuracy and 90% accuracy for common technical terms.
- **FR-002**: System MUST support fully local/offline voice processing with no network calls for the core transcription workflow.
- **FR-003**: System MUST activate via a configurable keyboard shortcut with response time under 1 second.
- **FR-004**: System MUST produce transcribed text within 2 seconds of the developer finishing speaking.
- **FR-005**: System MUST operate in push-to-talk mode only—no always-on microphone listening.
- **FR-006**: System MUST NOT store audio recordings permanently; audio exists only in memory during the active transcription session.
- **FR-007**: System MUST output transcribed text in a form that can be pasted into any text input (IDE, terminal, browser).
- **FR-008**: System MUST support the primary development platform (macOS).
- **FR-009**: System SHOULD provide optional AI-powered cleanup that improves formatting and technical term accuracy.
- **FR-010**: System SHOULD clearly indicate when AI cleanup sends transcription to an external service, and this must be opt-in.
- **FR-011**: System SHOULD support multiple spoken languages and accents.
- **FR-012**: System SHOULD support custom vocabulary for project-specific terms.
- **FR-013**: System SHOULD provide visual indication of dictation state (recording, processing, complete).
- **FR-014**: System SHOULD allow cancellation of dictation mid-session without producing output.
- **FR-015**: System SHOULD work with the containerized IDE (code-server in browser) via standard clipboard paste.

### Key Entities

- **Dictation Session**: A single voice input episode from activation (shortcut press) to text output. Audio exists only for the duration of this session and is discarded after transcription.
- **Transcription**: The text output produced from a dictation session. May be raw (direct from speech recognition) or cleaned (post-processed by AI for formatting).
- **Custom Vocabulary**: A user-configurable set of terms (project names, library names, domain terms) that improves recognition accuracy for specific terminology.
- **AI Cleanup**: An optional post-processing step that sends raw transcription to a language model for formatting improvement. Always opt-in, always clearly indicated when active.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can dictate a 50-word technical instruction and receive accurate text in under 5 seconds total (activation to text ready).
- **SC-002**: Transcription accuracy exceeds 95% for general English and 90% for common technical terms (programming languages, popular libraries, coding concepts).
- **SC-003**: Voice input reduces time spent composing complex AI prompts (>30 words) by at least 30% compared to typing.
- **SC-004**: The system works fully offline with no degradation in core transcription quality.
- **SC-005**: At least 50% of complex AI prompts (descriptions, feature requests, explanations) are composed via voice input after 2 weeks of adoption.
- **SC-006**: The entire voice workflow (activation → speech → text in IDE) completes in under 5 seconds for a typical sentence.
- **SC-007**: Developers report the voice input feels natural and doesn't interrupt their coding flow (qualitative feedback: >80% satisfaction).

## Assumptions

- macOS is the primary development platform for users of this feature.
- Developers have access to a reasonable quality microphone (built-in MacBook microphone is sufficient for quiet environments).
- Voice input supplements keyboard input—it is not intended to replace typing for short commands or code syntax.
- The clipboard-based integration pattern (dictate on host, paste into container) is acceptable for the containerized IDE workflow.
- Local speech recognition models provide sufficient accuracy for technical content without cloud processing.
- Developers will primarily use voice for natural language instructions to AI agents, not for dictating code syntax.
- A one-time commercial tool purchase (under $300) is acceptable for this developer productivity enhancement.

## Dependencies

- **008-containerized-ide**: Provides the IDE environment where dictated text is used. Voice input must work with the browser-based IDE via clipboard paste.

## Constraints

- Voice processing must run on the host machine (not inside the container) for microphone access and latency reasons.
- No audio recordings may be stored permanently—audio exists only in memory during active transcription.
- The system must support a fully offline/local mode with no network calls for core transcription.
- Push-to-talk activation only—no always-on microphone listening.
- macOS is the required platform; cross-platform support is deferred.
- AI cleanup (sending transcription to external service) must be opt-in and clearly indicated.
- The specific voice tool is pending spike evaluation—the spec defines requirements that any selected tool must meet.
