# Voice Input

Voice input is a host-side productivity feature: you dictate prompts and paste the cleaned-up text into your AI tool.

Applies to: macOS (Apple Silicon)

## Prerequisites

- macOS 14+ on Apple Silicon
- Microphone access
- Disk space for local speech-to-text models

## Setup

This project does not ship a voice recorder; it documents a working setup.

Recommended options:

- Superwhisper (paid): `https://superwhisper.com`
- VoiceInk (paid or build from source): `https://tryvoiceink.com`

## Configuration

- Push-to-talk shortcut (single key)
- Output to clipboard
- Optional cleanup tiers:
  - rules only (offline)
  - local LLM (offline)
  - cloud cleanup (opt-in; requires API key)

## Verification

1. Dictate a short sentence and verify it lands on the clipboard.
2. Paste into your terminal/IDE and confirm the text is correct.

## Troubleshooting

- Shortcut not working: check macOS Accessibility permissions
- Accuracy poor: try a larger model or improve mic input levels
- Clipboard paste fails in browser IDE: try the IDE paste option (no-format paste)

## Related

- `docs/features/containerized-ide.md`
- `docs/features/ai-assistants.md`

## Next steps

- Add mobile notifications for long tasks: `docs/features/mobile-access.md`
