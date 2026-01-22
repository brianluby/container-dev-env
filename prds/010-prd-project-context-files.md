# 010-prd-project-context-files

## Problem Statement

AI coding agents perform better when they understand project conventions, architecture decisions,
coding standards, and domain context. Currently, developers must repeatedly explain the same
project details in every AI session. A standardized system of context files provides persistent,
structured information that AI agents can read automatically, improving response quality and
reducing repetitive prompting.

**Goal**: Define and implement a project context file strategy that works across all AI tools
(Claude Code, Cline, Roo-Code, Continue, OpenCode, Cursor, etc.) used in the containerized
development environment.

## Requirements

### Must Have (M)

- [ ] Root-level context file that all AI tools read automatically
- [ ] Project description and goals documentation
- [ ] Coding standards and style guidelines
- [ ] Technology stack and dependencies overview
- [ ] Clear file naming convention that AI tools recognize
- [ ] Markdown format for human readability and AI parsing
- [ ] Works with tools in PRD 005 (terminal agents) and PRD 006 (agentic assistants)

### Should Have (S)

- [ ] Nested/directory-specific context files for module-level instructions
- [ ] Architecture decision records (ADRs) integration
- [ ] Common patterns and anti-patterns documentation
- [ ] Testing conventions and requirements
- [ ] Git workflow and commit message standards
- [ ] Security considerations and constraints

### Could Have (C)

- [ ] Template generator for new projects
- [ ] Validation/linting for context files
- [ ] Version-specific context (different instructions for different branches)
- [ ] Tool-specific sections (Continue-specific, Claude-specific hints)
- [ ] Integration with Memory Bank pattern (PRD 012)
- [ ] Auto-generation from codebase analysis

### Won't Have (W)

- [ ] Runtime context injection (that's MCP/PRD 011)
- [ ] Dynamic context based on current task (that's Memory Bank/PRD 012)
- [ ] Proprietary formats locked to single tool

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Cross-tool compatibility | Must | Works with Claude Code, Cline, Continue, etc. |
| Human readable | Must | Developers can read and edit easily |
| AI parseable | Must | Structured enough for AI to extract info |
| Industry adoption | High | Aligns with emerging standards |
| Simplicity | High | Easy to create and maintain |
| Flexibility | Medium | Supports various project types |
| Extensibility | Medium | Can grow with project complexity |

## Format Candidates

| Format | Adoption | Pros | Cons | Recommendation |
|--------|----------|------|------|----------------|
| AGENTS.md | High (60k+ projects) | Industry standard, supported by most tools, simple | Relatively new, still evolving | Primary |
| .cursorrules | Medium | Cursor-native, well-documented | Cursor-specific, deprecated in favor of .mdc | Tool-specific fallback |
| CLAUDE.md | Medium | Claude Code native, detailed instructions | Claude-specific | Tool-specific fallback |
| .github/copilot-instructions.md | Low | GitHub Copilot native | Copilot-specific | Tool-specific fallback |
| Custom (PROJECT_CONTEXT.md) | N/A | Full control, custom structure | No automatic tool recognition | Not recommended |

## Recommended Structure

### Primary: AGENTS.md

Based on the emerging standard adopted by 60k+ open-source projects including OpenAI repositories:

```
project-root/
├── AGENTS.md                    # Primary context file (all tools read this)
├── CLAUDE.md                    # Claude Code specific (optional)
├── .cursorrules                 # Cursor specific (optional, legacy)
├── docs/
│   ├── architecture/
│   │   └── decisions/           # ADRs
│   └── AGENTS.md                # Docs-specific context (optional)
├── src/
│   ├── api/
│   │   └── AGENTS.md            # API module context (optional)
│   └── frontend/
│       └── AGENTS.md            # Frontend module context (optional)
└── tests/
    └── AGENTS.md                # Testing context (optional)
```

### AGENTS.md Content Structure

```markdown
# Project Context

## Overview
[Brief project description, goals, target users]

## Technology Stack
- Language: [e.g., Python 3.12, TypeScript 5.x]
- Framework: [e.g., FastAPI, Next.js]
- Database: [e.g., PostgreSQL, Redis]
- Infrastructure: [e.g., Docker, Kubernetes]

## Coding Standards
- [Style guide references]
- [Naming conventions]
- [File organization patterns]

## Architecture
- [High-level architecture description]
- [Key design patterns used]
- [Important boundaries and constraints]

## Common Patterns
- [Frequently used patterns with examples]
- [Anti-patterns to avoid]

## Testing Requirements
- [Test coverage expectations]
- [Testing frameworks and conventions]

## Git Workflow
- [Branch naming conventions]
- [Commit message format]
- [PR requirements]

## Security Considerations
- [Authentication/authorization patterns]
- [Data handling requirements]
- [Known constraints]

## AI Agent Instructions
- [Specific instructions for AI tools]
- [Preferences for code generation]
- [Things to always/never do]
```

## Selected Approach

Adopt **AGENTS.md** as the primary cross-tool context file standard:

1. Most AI coding tools automatically read AGENTS.md
2. Support nested AGENTS.md for directory-specific context
3. Maintain tool-specific files (CLAUDE.md, .cursorrules) only when needed
4. Keep content in structured Markdown for both human and AI consumption
5. Start simple, expand based on project complexity

## Acceptance Criteria

- [ ] Given a new project, when I create AGENTS.md, then Claude Code reads it automatically
- [ ] Given AGENTS.md exists, when I use Cline/Continue/Roo-Code, then they incorporate the context
- [ ] Given nested AGENTS.md in subdirectory, when AI works in that directory, then it reads both root and nested files
- [ ] Given the template, when a developer creates context files, then completion takes under 30 minutes
- [ ] Given context files, when AI generates code, then it follows documented patterns and standards
- [ ] Given AGENTS.md, when a human reads it, then project context is clear and useful
- [ ] Given updates to the project, when I modify AGENTS.md, then AI behavior reflects changes immediately

## Dependencies

- Requires: 005-prd-terminal-ai-agent, 006-prd-agentic-assistant (tools that will read context)
- Blocks: none (documentation standard)

## Spike Tasks

### Template Creation

- [ ] Create AGENTS.md template with all recommended sections
- [ ] Create minimal AGENTS.md template for quick start
- [ ] Create CLAUDE.md template for Claude Code specific instructions
- [ ] Create example nested AGENTS.md for modules
- [ ] Document when to use each section

### Validation & Tooling

- [ ] Create markdown linter rules for AGENTS.md structure
- [ ] Create VS Code snippet for quick section creation
- [ ] Document how each AI tool reads context files
- [ ] Test context file recognition across all tools (Claude Code, Cline, Continue, Roo-Code, OpenCode)

### Integration

- [ ] Add AGENTS.md to container-dev-env project as example
- [ ] Document relationship with ADRs
- [ ] Document relationship with Memory Bank (PRD 012)
- [ ] Create onboarding guide for new projects

## References

- [AGENTS.md Specification](https://agents.md/)
- [AGENTS.md GitHub](https://github.com/agentsmd/agents.md)
- [Keep AGENTS.md in Sync](https://kau.sh/blog/agents-md/)
- [Improve AI Output with AGENTS.md](https://www.builder.io/blog/agents-md)
- [Mastering Project Context Files](https://eclipsesource.com/blogs/2025/11/20/mastering-project-context-files-for-ai-coding-agents/)
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules)
