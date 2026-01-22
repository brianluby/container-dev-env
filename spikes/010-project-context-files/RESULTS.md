# Spike Results: 010 - Project Context Files

**PRD**: prds/010-prd-project-context-files.md
**Status**: Complete
**Date**: 2026-01-21

## Summary

This spike explored project context files for AI coding agents, focusing on the AGENTS.md specification and cross-tool compatibility. The deliverables include templates, examples, tooling, and documentation for implementing context files in any project.

## Key Findings

### AGENTS.md Specification

The AGENTS.md specification (https://agents.md/) has emerged as the de facto standard:

- **Adoption**: 60k+ open-source projects (including OpenAI repositories)
- **Governance**: Stewarded by the Linux Foundation
- **Compatibility**: Works with 25+ AI coding tools
- **Format**: Flexible markdown, no rigid structure required

Key features:
- Nested file support (closest file takes precedence)
- Files supplement, not replace parent context
- Human-readable and AI-parseable

### Tool Recognition Matrix

| Tool | Primary File | AGENTS.md Support |
|------|-------------|-------------------|
| Claude Code | CLAUDE.md | Yes (reads both) |
| Cline | .clinerules/ | Yes (fallback) |
| Roo-Code | .roo/rules.md | Yes (fallback) |
| Continue | .continue/config.json | Via config |
| Cursor | .cursor/rules | Limited |
| Windsurf | .windsurfrules | Yes (fallback) |
| GitHub Copilot | .github/copilot-instructions.md | No |
| Aider | CONVENTIONS.md | No |
| OpenCode | AGENTS.md | Native |

### Recommendation

**Primary approach**: Use AGENTS.md as the cross-tool standard
- Most tools read it automatically or as fallback
- Simple markdown format is maintainable
- Nested files support module-level context

**Tool-specific files**: Add only when needed
- CLAUDE.md for Claude Code specific behaviors
- .clinerules/ if team uses Cline heavily
- .github/copilot-instructions.md for Copilot users

## Deliverables

### Templates (`templates/`)

1. **AGENTS.md** - Full template with all recommended sections
   - Overview, Tech Stack, Coding Standards, Architecture
   - Common Patterns, Testing, Git Workflow, Security
   - AI Agent Instructions section
   - ~400 lines with comprehensive coverage

2. **AGENTS-minimal.md** - Quick start template
   - Essential sections only
   - ~50 lines, 5-10 minutes to complete

3. **CLAUDE.md** - Claude Code specific template
   - Tool preferences (Task, Bash, Edit)
   - Agent selection guidance
   - Workflow preferences
   - MCP server documentation

### Examples (`examples/`)

1. **nested-agents.md** - Module-level context examples
   - API module AGENTS.md
   - Core/Domain module AGENTS.md
   - Frontend module AGENTS.md
   - Tests module AGENTS.md
   - When to create/not create nested files

2. **AGENTS-example-project.md** - Spec-compliant example for container-dev-env
   - Demonstrates standard format
   - Real project context

### Tooling (`tooling/`)

1. **agents-md.code-snippets** - VS Code snippets
   - `agents-full` - Complete template
   - `agents-minimal` - Quick start
   - `agents-overview`, `agents-techstack`, `agents-standards`
   - `agents-ai`, `agents-testing`, `agents-git`, `agents-security`
   - `agents-pattern`, `agents-module`
   - `claude-md` - Claude-specific template

2. **.markdownlint.yaml** - Linter configuration
   - ATX heading style
   - Fenced code blocks with language
   - Proper capitalization for tech terms
   - Suitable for AGENTS.md validation

### Documentation (`docs/`)

1. **tool-compatibility.md** - Comprehensive tool documentation
   - Detailed configuration for each tool
   - File locations and formats
   - Nested support details
   - Migration and synchronization strategies
   - Testing/verification checklist

## Implementation Recommendations

### Development Process Documentation

AGENTS.md should document your team's development workflow. This project follows:

1. **PRD Phase**: Create `prds/###-prd-feature-name.md` defining requirements
2. **Spike Phase**: For uncertain features, explore in `spikes/###-feature-name/`
3. **SpecKit Process**:
   - `/speckit.specify` → Create specification
   - `/speckit.plan` → Research and design
   - `/speckit.tasks` → Generate task list
   - `/speckit.implement` → Execute tasks

AI agents must understand and follow this workflow. Include clear instructions in AGENTS.md about:
- When to suggest creating a PRD
- When to recommend a spike
- Prerequisites checks before implementation
- Task completion tracking

See `examples/workflow-context.md` for a template section to add to AGENTS.md.

### For New Projects

1. Start with `templates/AGENTS-minimal.md`
2. Add your development workflow documentation
3. Expand sections as project grows
4. Add nested AGENTS.md for complex modules
5. Install VS Code snippets for faster editing

### For Existing Projects

1. Audit current context files
2. Create AGENTS.md with essential info
3. Keep tool-specific files if team relies on them
4. Use symlinks or sync scripts to reduce duplication

### For Teams

1. Standardize on AGENTS.md as primary
2. Document team-specific additions
3. Include context file updates in PR reviews
4. Review quarterly for accuracy

## Files Created

```
spikes/010-project-context-files/
├── docs/
│   └── tool-compatibility.md      # Tool-by-tool documentation
├── examples/
│   ├── nested-agents.md           # Module context examples
│   ├── AGENTS-example-project.md  # Real project example
│   └── workflow-context.md        # Development process documentation
├── templates/
│   ├── AGENTS.md                  # Full template
│   ├── AGENTS-minimal.md          # Quick start template
│   └── CLAUDE.md                  # Claude Code template
├── tooling/
│   ├── agents-md.code-snippets    # VS Code snippets
│   └── .markdownlint.yaml         # Linter rules
└── RESULTS.md                     # This file
```

## Open Questions

1. **Synchronization**: How to keep tool-specific files in sync with AGENTS.md?
   - Symlinks work on Unix-like systems
   - Script-based sync adds maintenance burden
   - Consider single source of truth approach

2. **Continue Integration**: Continue's documentation was unavailable (404)
   - Need to verify context provider configuration
   - May need manual AGENTS.md setup via config.json

3. **Cursor Evolution**: Cursor is moving to project rules UI
   - File-based configuration may be deprecated
   - Monitor for changes to .cursor/rules format

4. **Memory Bank Integration**: PRD 012 will add persistent memory
   - How do static context files interact with dynamic memory?
   - May need AGENTS.md section for memory references

## Next Steps

1. [ ] Test templates with multiple AI tools
2. [ ] Create VS Code extension for one-click setup
3. [ ] Add GitHub Action for AGENTS.md validation
4. [ ] Integrate with PRD 012 (Memory Bank) when available
5. [ ] Monitor Continue docs for context provider updates

## References

- [AGENTS.md Specification](https://agents.md/)
- [AGENTS.md GitHub](https://github.com/agentsmd/agents.md)
- [Keep AGENTS.md in Sync](https://kau.sh/blog/agents-md/)
- [Improve AI Output with AGENTS.md](https://www.builder.io/blog/agents-md)
- [Mastering Project Context Files](https://eclipsesource.com/blogs/2025/11/20/mastering-project-context-files-for-ai-coding-agents/)
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules)
- [GitHub Copilot Instructions](https://docs.github.com/en/copilot/customizing-copilot)
