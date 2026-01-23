# File Structure Contract: Project Context Files

**Feature**: 010-project-context-files
**Date**: 2026-01-23

## Overview

This contract defines the file structure, naming, and content conventions that constitute the "API" of the project context file system. AI tools and developers depend on these contracts for interoperability.

## File Naming Contract

### Primary Context File

```
Filename: AGENTS.md
Case:     Exact (case-sensitive on Linux/macOS)
Location: Repository root (required)
          Any subdirectory (optional, for nested context)
```

### Tool-Specific Supplements

```
Claude Code:  CLAUDE.md        (repository root)
Cursor:       .cursorrules     (repository root, legacy)
Cursor (new): .cursor/rules/*.mdc (directory)
Cline:        .clinerules      (repository root)
Continue:     .continuerules   (repository root)
Roo-Code:     .roo/rules       (repository root)
```

### Local Override (not committed)

```
Filename: AGENTS.local.md
Location: Repository root
Gitignore: Must be listed in .gitignore
```

## Content Structure Contract

### Comprehensive Template (AGENTS.md.full)

```markdown
# Project Context

## Overview
[1-3 paragraphs: what the project does, who it's for, key goals]

## Technology Stack
- Language: [primary language and version]
- Framework: [primary framework]
- Database: [if applicable]
- Infrastructure: [deployment target]

## Coding Standards
- [Style guide reference or inline rules]
- [Naming conventions: variables, functions, files]
- [File organization patterns]
- [Import/module ordering]

## Architecture
- [High-level architecture description]
- [Key design patterns used]
- [Important boundaries and constraints]
- [Link to ADRs if applicable]

## Common Patterns
- [Pattern 1 with brief example]
- [Pattern 2 with brief example]
- [Anti-patterns to avoid]

## Testing Requirements
- [Test coverage expectations]
- [Testing frameworks and conventions]
- [Test file naming and location]

## Git Workflow
- [Branch naming: e.g., feature/xxx, fix/xxx]
- [Commit message format: e.g., conventional commits]
- [PR requirements: reviews, checks]

## Security Considerations
<!-- WARNING: Do NOT include actual secrets, API keys, passwords, or internal URLs.
     Document security PATTERNS and PRACTICES only. -->
- [Authentication/authorization patterns]
- [Data handling requirements]
- [Known security constraints]

## AI Agent Instructions
- [Specific do/don't rules for AI tools]
- [Code generation preferences]
- [Things to always/never do]
```

### Minimal Template (AGENTS.md.minimal)

```markdown
# Project Context

## Overview
[One paragraph describing the project]

## Technology Stack
- Language: [primary language]
- Framework: [primary framework]

## Key Conventions
- [Most important convention 1]
- [Most important convention 2]
- [Most important convention 3]

## AI Instructions
- [Critical instruction for AI tools]
- [Another important instruction]
```

### CLAUDE.md Supplement Template

```markdown
# Claude Code Instructions

## Behavior Preferences
- [Claude-specific instruction 1]
- [Claude-specific instruction 2]

## Tool Usage
- [Preferred tools/commands for Claude to use]
- [Tools/commands to avoid]

## Response Style
- [Output format preferences]
- [Verbosity level]
```

### Nested AGENTS.md Template

```markdown
# [Module Name] Context

## Module Purpose
[What this module/directory is responsible for]

## Local Conventions
- [Convention specific to this module]
- [Override or supplement to root conventions]

## Key Patterns
- [Module-specific patterns]

## Testing
- [Module-specific test conventions]
```

## Bootstrap Script Contract

### Interface

```
Usage: init-context.sh [OPTIONS]

Options:
  --full        Use comprehensive template (9 sections)
  --minimal     Use minimal template (4 sections)
  --output FILE Write to FILE instead of ./AGENTS.md
  --force       Overwrite existing file without prompt
  --help        Show usage information

Exit Codes:
  0  Success (file created or overwritten)
  1  File already exists (use --force to overwrite)
  2  Invalid arguments or missing required input
```

### Behavior

1. If no `--full` or `--minimal` flag, prompt user interactively
2. Check if output file exists; abort with exit 1 unless `--force`
3. Write selected template to output path
4. Print confirmation message to stdout
5. Errors go to stderr

### Output Format

- File is valid Markdown (CommonMark)
- UTF-8 encoded
- LF line endings
- Placeholder format: `[description in brackets]`
- Security warnings in HTML comments

## Size Contract

| Constraint | Value | Enforcement |
|------------|-------|-------------|
| Maximum file size | 10,240 bytes (10KB) | CI lint check |
| Recommended max sections (root) | 9 | Template guidance |
| Recommended max sections (nested) | 4 | Template guidance |
| Maximum nesting depth | 1 level (root + subdirectory) | Documentation guidance |

## Encoding Contract

| Property | Required Value | Validation |
|----------|---------------|------------|
| Character encoding | UTF-8 | `file --mime-encoding` |
| Line endings | LF (`\n`) | No `\r` in file |
| BOM | None (no UTF-8 BOM) | First bytes != `EF BB BF` |
| Trailing newline | Yes (file ends with `\n`) | Last byte = `0x0A` |
