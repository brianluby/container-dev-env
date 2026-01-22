# CLAUDE.md Template (Claude Code Specific)

<!--
  CLAUDE.md is read by Claude Code (Anthropic's CLI tool).
  Use this file for Claude-specific instructions that supplement AGENTS.md.

  File precedence in Claude Code:
  1. ~/.claude/CLAUDE.md (global, user preferences)
  2. PROJECT_ROOT/CLAUDE.md (project-specific)

  Note: If you have AGENTS.md, Claude Code reads both. Use CLAUDE.md for
  Claude-specific behaviors that wouldn't apply to other AI tools.
-->

# {Project Name} - Claude Code Instructions

## Project Context

{Brief project description - Claude will combine this with AGENTS.md if present}

## Claude-Specific Behaviors

### Tool Preferences

<!-- Claude Code has specific tools like Task, Bash, Edit, etc. -->
<!-- Configure how Claude should use them in your project -->

- **Task Tool**: {When to spawn sub-agents, e.g., "Use for codebase exploration"}
- **Bash Tool**: {Commands that are safe, e.g., "Safe to run: npm test, npm run build"}
- **Edit Tool**: {Editing preferences, e.g., "Prefer small, focused edits"}

### Agent Selection

<!-- Claude Code can use specialized agents for different tasks -->

For this project, prefer these agents when appropriate:
- **Code changes**: `{language}-pro` (e.g., `python-pro`, `typescript-pro`)
- **Testing**: `test-automator`
- **Security review**: `security-auditor`
- **Architecture decisions**: `architect-review`

### Slash Commands

<!-- Configure how slash commands should behave -->

- `/test`: Run `{test command}`
- `/build`: Run `{build command}`
- `/lint`: Run `{lint command}`
- `/commit`: Use conventional commits, reference tickets

## Workflow Preferences

### Before Making Changes
1. Read the relevant file(s) first
2. Check for existing patterns in similar files
3. Verify tests exist for the area being modified

### When Implementing Features
1. Start with tests (TDD preferred)
2. Implement minimal solution first
3. Refactor only if needed
4. Update documentation for public APIs

### After Making Changes
1. Run test suite: `{test command}`
2. Check linting: `{lint command}`
3. Format code: `{format command}`

## Allowed/Restricted Operations

### Safe Operations (auto-approve)
- Reading any file
- Running tests
- Running linters
- Running build commands
- Git status/diff/log operations

### Require Confirmation
- Installing new dependencies
- Modifying configuration files
- Database migrations
- Git push operations

### Never Do
- Run destructive commands (`rm -rf`, `git reset --hard`)
- Modify `.env` files directly
- Commit secrets or credentials
- Skip pre-commit hooks

## Context Files

<!-- Help Claude understand your project's documentation structure -->

Key files for understanding this project:
- `{path}` - {Description}
- `{path}` - {Description}
- `{path}` - {Description}

## Project-Specific Terminology

<!-- Domain terms that Claude should understand -->

| Term | Meaning |
|------|---------|
| {term} | {definition} |
| {term} | {definition} |

## Common Tasks

### Adding a New {Entity}

```bash
# 1. Create the {entity} file
# Location: {path}

# 2. Add tests
# Location: {path}

# 3. Update {config/registry}
# Location: {path}
```

### Running Migrations

```bash
{migration commands}
```

### Debugging

```bash
# Enable verbose logging
{command}

# Check logs
{command}
```

## Environment Variables

<!-- Claude-specific environment hints -->

Required for local development:
- `{VAR}` - {where to get it}
- `{VAR}` - {where to get it}

## MCP Servers

<!-- If using MCP servers with Claude Code -->

Available MCP servers in this project:
- `{server}`: {What it provides, e.g., "Database queries"}
- `{server}`: {What it provides, e.g., "File system access"}

## Hooks Configuration

<!-- If using Claude Code hooks -->

Pre-tool hooks configured:
- {hook}: {What it does}

Post-tool hooks configured:
- {hook}: {What it does}

---

<!--
  This file supplements AGENTS.md with Claude Code specific instructions.
  Keep AGENTS.md for cross-tool compatible information.
  Keep CLAUDE.md for Claude-specific behaviors and tool configurations.
-->
