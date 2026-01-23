# Research: Project Context Files

**Feature**: 010-project-context-files
**Date**: 2026-01-23
**Status**: Complete

## Research Topics

### 1. AGENTS.md Specification & Best Practices

**Decision**: Use AGENTS.md as the primary context file format following the emerging industry standard.

**Rationale**:
- 60k+ projects on GitHub already use AGENTS.md (including OpenAI repos)
- Recognized automatically by Claude Code, Cline, Continue, Roo-Code, Cursor, and OpenCode
- Simple Markdown format — no proprietary extensions needed
- Supports hierarchical composition (root + nested in subdirectories)

**Alternatives considered**:
- `.cursorrules` — Cursor-specific, deprecated in favor of `.mdc` files
- `.github/copilot-instructions.md` — GitHub Copilot only
- Custom filename (e.g., `PROJECT_CONTEXT.md`) — No auto-recognition by any tool
- YAML/TOML config — Not human-friendly, tools don't recognize

**Key findings**:
- AGENTS.md content is treated as system-level context (higher priority than user prompts in some tools)
- File is read once per session (not re-read on every interaction unless tool is restarted)
- Most tools support hierarchical loading: root + subdirectory files merged
- Recommended sections: Overview, Tech Stack, Coding Standards, Architecture, AI Instructions
- Maximum effective size varies by tool but 10KB is a safe universal limit

### 2. AI Tool Context File Discovery Behavior

**Decision**: Document per-tool behavior rather than trying to normalize it.

**Rationale**: Each AI tool has slightly different discovery and precedence rules. Understanding these differences helps developers create effective context files.

**Tool-specific behaviors**:

| Tool | Primary File | Supplements | Nested Support | Precedence |
|------|-------------|-------------|----------------|------------|
| Claude Code | AGENTS.md, CLAUDE.md | .claude/settings.json | Yes (subdirectory AGENTS.md) | CLAUDE.md supplements AGENTS.md |
| Cline | AGENTS.md, .clinerules | — | Yes | .clinerules supplements |
| Continue | AGENTS.md, .continuerules | — | Yes | Nested overrides root for scope |
| Roo-Code | AGENTS.md, .roo/rules | — | Yes | .roo/ supplements |
| OpenCode | AGENTS.md | config.yaml | Yes | Config supplements |
| Cursor | .cursorrules, AGENTS.md | .cursor/rules/*.mdc | Limited | .mdc rules override |

**Key findings**:
- All tools listed read AGENTS.md from project root
- Most support nested AGENTS.md files in subdirectories
- Tool-specific files (CLAUDE.md, .cursorrules) supplement but don't replace AGENTS.md
- Changes to context files take effect on next session/interaction (no hot-reload in most tools)

### 3. Content Structure Best Practices

**Decision**: Define two template tiers — comprehensive (all sections) and minimal (4 essential sections).

**Rationale**: Different projects need different levels of detail. A minimal template lowers the barrier to adoption while the comprehensive template serves mature projects.

**Comprehensive template sections** (ordered by importance):
1. Overview — What the project is, who it's for
2. Technology Stack — Languages, frameworks, infrastructure
3. Coding Standards — Style, naming, formatting rules
4. Architecture — High-level design, key patterns, boundaries
5. Common Patterns — Frequently used patterns with examples
6. Testing Requirements — Coverage expectations, conventions
7. Git Workflow — Branch naming, commit format, PR requirements
8. Security Considerations — Auth patterns, data handling, constraints
9. AI Agent Instructions — Specific do/don't instructions for AI tools

**Minimal template sections**:
1. Overview
2. Technology Stack
3. Key Conventions (combines standards + patterns)
4. AI Instructions

**Key findings**:
- Sections with examples are more effective than abstract rules
- Anti-patterns ("don't do X") are as valuable as patterns
- AI-specific instructions should be action-oriented ("always", "never", "prefer")
- Linking to external docs (ADRs, style guides) preferred over duplicating content

### 4. Bootstrap Script Patterns

**Decision**: Single Bash script with `--full` and `--minimal` flags, outputting to stdout or writing directly.

**Rationale**: A shell script is the simplest, most portable approach. It requires no dependencies beyond bash and works inside containers and on host systems alike.

**Alternatives considered**:
- Python script — Adds dependency, overkill for template generation
- Cookiecutter/copier — Full project templating tools, too heavy for single-file creation
- Makefile target — Non-interactive, limited user guidance
- VS Code snippets — IDE-specific, doesn't work in terminal workflows

**Script behavior**:
```
init-context.sh [--full|--minimal] [--output FILE] [--force]
  --full        Use comprehensive template (default)
  --minimal     Use minimal template (4 sections)
  --output FILE Write to FILE instead of ./AGENTS.md
  --force       Overwrite existing file without prompt
  (no flags)    Interactive: prompt user to choose template
```

**Exit codes**:
- 0: Success (file created)
- 1: File already exists (no --force)
- 2: Invalid arguments

### 5. Security Considerations for Context Files

**Decision**: Template-level warnings + optional pre-commit hook recommendation.

**Rationale**: Since context files are static text committed to git, the primary risk is accidental secret inclusion. Template warnings are the first line of defense; pre-commit scanning is the second.

**Alternatives considered**:
- Mandatory pre-commit hook — Too invasive for a documentation standard
- Encryption for sensitive sections — Over-engineering; just don't include secrets
- Separate private context file — Adds complexity; .gitignore pattern sufficient

**Security template section content**:
```markdown
## Security Considerations
<!-- WARNING: Do NOT include actual secrets, API keys, passwords, or internal URLs.
     Document security PATTERNS and PRACTICES only. -->
- [Authentication patterns used]
- [Authorization approach]
- [Data handling constraints]
```

**Key findings**:
- Pre-commit hooks like `detect-secrets` or `gitleaks` can scan AGENTS.md files
- The `.gitignore` pattern `AGENTS.local.md` provides local-only overrides
- No AI tool treats context file content as executable — it's purely informational
