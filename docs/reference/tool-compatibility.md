# Tool Compatibility

This page documents how common AI coding tools discover project context files (for example `AGENTS.md` and tool-specific supplements).

Applies to: `main`

## Prerequisites

- None

## Discovery matrix

| Tool | Primary file | Supplement file | Nested support | Discovery trigger |
|---|---|---|---|---|
| Claude Code | `AGENTS.md` | `CLAUDE.md` | Yes | Session start |
| Cline | `AGENTS.md` | `.clinerules` | Yes | Session start |
| Continue | `AGENTS.md` | `.continuerules` | Yes | Session start |
| Roo-Code | `AGENTS.md` | `.roo/rules` | Yes | Session start |
| OpenCode | `AGENTS.md` | `config.yaml` | Yes | Session start |
| Cursor | `AGENTS.md` | `.cursorrules` / `.cursor/rules/*.mdc` | Limited | File open |

## Guidance

- Keep `AGENTS.md` universal and under 10KB
- Put tool-specific behavior in the supplement file
- Never include secrets or internal URLs in context files

## Related

- [Composition Rules](../composition-rules.md)
- [Navigation](../navigation.md)

## Next steps

- If you are configuring AI tooling: [AI Assistants](../features/ai-assistants.md)
