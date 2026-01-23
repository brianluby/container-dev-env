# Data Model: Project Context Files

**Feature**: 010-project-context-files
**Date**: 2026-01-23

## Entities

### Root Context File

The primary project-wide context file providing global conventions to all AI tools.

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| filename | string | Exactly `AGENTS.md` (case-sensitive) | Fixed filename for auto-discovery |
| location | path | Project root directory | Must be at repository root |
| format | string | Markdown (CommonMark) | Human-readable, AI-parseable |
| encoding | string | UTF-8 | Universal character encoding |
| line_endings | string | LF only | Unix-style line endings |
| size | integer | < 10,240 bytes (10KB) | Fits within AI context windows |
| sections | list | At minimum: Overview, Technology Stack, Coding Standards | Structured content sections |

**Lifecycle**: Created once → edited as project evolves → never deleted while project is active

### Directory Context File

A scoped context file providing module-specific instructions within a subdirectory.

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| filename | string | Exactly `AGENTS.md` | Same name as root for consistent discovery |
| location | path | Any subdirectory (1 level deep recommended) | Module-specific location |
| format | string | Markdown (CommonMark) | Same format as root |
| encoding | string | UTF-8 | Same encoding as root |
| line_endings | string | LF only | Same line endings as root |
| size | integer | < 10,240 bytes | Same size constraint |
| scope | string | Directory and descendants | Applies only to this subtree |

**Lifecycle**: Created when module needs specific context → updated with module → deleted if module removed

**Relationship to Root**: Supplements root context; takes precedence on conflicting instructions for its scope.

### Tool-Specific Supplement

An optional file containing instructions specific to one AI tool.

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| filename | string | Tool-dependent (see table below) | Per-tool naming convention |
| location | path | Project root directory | Same location as root context |
| format | string | Markdown or tool-specific | Varies by tool |
| content | string | Must not duplicate AGENTS.md content | Supplement only |

**Known tool-specific filenames**:

| Tool | Filename | Format |
|------|----------|--------|
| Claude Code | `CLAUDE.md` | Markdown |
| Cursor | `.cursorrules` | Markdown (legacy) |
| Cursor (new) | `.cursor/rules/*.mdc` | MDC format |
| Cline | `.clinerules` | Markdown |
| Continue | `.continuerules` | Markdown |
| Roo-Code | `.roo/rules` | Markdown |

**Lifecycle**: Created when tool-specific behavior needed → updated as tool features change → deleted if tool abandoned

### Context Template

A pre-structured file that developers fill in for their project.

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| variant | enum | `full` or `minimal` | Template complexity level |
| sections | list | See section catalog below | Ordered content sections |
| placeholders | list | Bracket format `[description]` | Replacement targets |
| warnings | list | HTML comment format | Security/usage warnings |

**Section catalog**:

| Section | Full Template | Minimal Template | Purpose |
|---------|:---:|:---:|---------|
| Overview | ✅ | ✅ | Project description and goals |
| Technology Stack | ✅ | ✅ | Languages, frameworks, infra |
| Coding Standards | ✅ | — | Style, naming, formatting |
| Key Conventions | — | ✅ | Combined standards + patterns |
| Architecture | ✅ | — | High-level design, patterns |
| Common Patterns | ✅ | — | Frequently used patterns |
| Testing Requirements | ✅ | — | Coverage, conventions |
| Git Workflow | ✅ | — | Branching, commits, PRs |
| Security Considerations | ✅ | — | Auth, data handling |
| AI Instructions | ✅ | ✅ | Specific AI tool directives |

### Bootstrap Script

A CLI utility that generates context file templates.

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| name | string | `init-context.sh` | Script filename |
| location | path | `src/scripts/` | Source location in this repo |
| shell | string | Bash 5.x (POSIX-compatible subset) | Script interpreter |
| arguments | list | `--full`, `--minimal`, `--output`, `--force` | CLI flags |
| exit_codes | map | 0=success, 1=exists, 2=invalid args | Structured exit status |
| output | file | AGENTS.md at specified path | Generated context file |

## Composition Rules

### Context Merging

When an AI tool resolves context for a given file path:

```
1. Load root AGENTS.md (always)
2. Load tool-specific supplement if exists (e.g., CLAUDE.md)
3. Walk path from root toward file's directory
4. At each directory level, if AGENTS.md exists:
   - Add its content to accumulated context
   - For conflicting instructions, later (deeper) overrides earlier
5. Final context = root + supplement + nested (deepest wins on conflicts)
```

### Content Separation Rules

| Content Type | Goes In | Rationale |
|--------------|---------|-----------|
| Universal project conventions | Root AGENTS.md | Applies to all code, all tools |
| Module-specific patterns | Nested AGENTS.md | Only relevant in that directory |
| Claude Code behaviors | CLAUDE.md | Claude-specific features |
| Cursor IDE rules | .cursorrules | Cursor-specific features |
| Secrets, credentials | NOWHERE | Never in any context file |
| Architecture decisions | ADRs (linked from AGENTS.md) | Avoid duplication |
| Local-only overrides | AGENTS.local.md (.gitignored) | Not shared with team |

## Validation Rules

| Rule | Check | Error |
|------|-------|-------|
| File size | `wc -c < FILE` < 10240 | "Context file exceeds 10KB limit" |
| Encoding | `file --mime-encoding FILE` = utf-8 | "Context file must be UTF-8" |
| Line endings | No `\r\n` in file | "Context file must use LF line endings" |
| Filename case | Exactly `AGENTS.md` | "Filename must be AGENTS.md (case-sensitive)" |
| No secrets | No patterns matching API keys, tokens | "Potential secret detected" |
| Required sections | Overview, Tech Stack present | "Missing required section" |
