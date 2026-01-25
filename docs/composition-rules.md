# Context Composition Rules

This page describes how AI tools compose multiple context files into an effective set of instructions.

## Overview

When multiple context files exist in a project, AI tools compose them into a
single effective context. This document defines the composition rules.

## Prerequisites

- None

## File Discovery Order

```
1. Root AGENTS.md         (always loaded first)
2. Tool-specific supplement (e.g., CLAUDE.md, .clinerules)
3. Nested AGENTS.md       (loaded when working in that directory)
```

## Composition Algorithm

When an AI tool resolves context for a file at path `project/src/api/handler.ts`:

```
1. Load project/AGENTS.md (root context — always)
2. Load project/CLAUDE.md (tool supplement — if exists and tool is Claude)
3. Walk path: project/ -> project/src/ -> project/src/api/
4. At each level, if AGENTS.md exists, add to accumulated context
5. Final context = root + supplement + all nested (deepest wins on conflicts)
```

## Precedence Rules

| Scenario | Winner | Rationale |
|----------|--------|-----------|
| Root says "use camelCase", nested says "use snake_case" | Nested | Deeper context is more specific |
| AGENTS.md says "use Jest", CLAUDE.md says "prefer vitest" | CLAUDE.md | Tool-specific supplements override |
| Root says "always write tests", nested is silent on testing | Root | Nested only overrides on explicit conflicts |
| Two nested files at same depth disagree | Closest to file | The AGENTS.md in the same directory as the target file wins |

## Content Separation Guidelines

| Content Type | Location | Rationale |
|--------------|----------|-----------|
| Universal project conventions | Root AGENTS.md | Applies to all code, all tools |
| Module-specific patterns | Nested AGENTS.md in that directory | Only relevant in scope |
| Tool-specific behaviors | CLAUDE.md, .clinerules, etc. | Only one tool reads it |
| Secrets, credentials | NOWHERE (never in any context file) | Security requirement |
| Architecture decisions | Link from AGENTS.md to ADRs | Avoid content duplication |
| Local-only overrides | AGENTS.local.md (.gitignored) | Personal preferences, not shared |

## Example: Multi-Level Project

```
project/
├── AGENTS.md              # "Use TypeScript, conventional commits"
├── CLAUDE.md              # "Prefer Read tool before Edit"
├── src/
│   ├── AGENTS.md          # "All source uses strict mode"
│   └── api/
│       ├── AGENTS.md      # "REST endpoints use snake_case URLs"
│       └── handler.ts
└── tests/
    └── AGENTS.md          # "Use vitest, mock external services"
```

When working on `src/api/handler.ts`, effective context is:
1. Root: TypeScript, conventional commits
2. CLAUDE.md: Read before Edit (Claude only)
3. src/AGENTS.md: strict mode
4. src/api/AGENTS.md: snake_case URLs

When working on `tests/`, effective context is:
1. Root: TypeScript, conventional commits
2. tests/AGENTS.md: vitest, mock externals

## Best Practices

1. **Keep root general** — Only project-wide rules in root AGENTS.md
2. **Keep nested focused** — Only rules specific to that directory subtree
3. **Don't repeat** — If it's in root, don't restate in nested files
4. **Conflict intentionally** — Only override root rules when the module genuinely needs different behavior
5. **Limit depth** — One level of nesting (root + subdirectory) is recommended; deeper nesting adds complexity
6. **Size budget** — Each file under 10KB; total project context should stay manageable

## Documentation page composition rules

User-facing documentation pages under `docs/` follow the page contract in `docs/_page-template.md`:

- Each page has a single `#` title.
- Each page includes `## Prerequisites`, `## Related`, and `## Next steps`.
- Setup/config pages should include a troubleshooting section when there are known failure modes.

Exceptions:

- `docs/_page-template.md` is a template.
- Pointer-only legacy pages (deprecated stubs) are allowed to be short, but should still include Prerequisites/Related/Next steps.

## Related

- [Tool Compatibility](reference/tool-compatibility.md)
- [Navigation](navigation.md)

## Next steps

- If you are writing docs pages: [Page Template](_page-template.md)
