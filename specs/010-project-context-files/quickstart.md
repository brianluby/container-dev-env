# Quickstart: Project Context Files

**Feature**: 010-project-context-files
**Date**: 2026-01-23

## 5-Minute Setup (Minimal Template)

### Step 1: Create AGENTS.md

At your project root, create `AGENTS.md`:

```bash
# Option A: Use the bootstrap script
./src/scripts/init-context.sh --minimal

# Option B: Create manually
touch AGENTS.md
```

### Step 2: Fill in the template

Edit `AGENTS.md` with your project details:

```markdown
# Project Context

## Overview
A containerized development environment providing reproducible,
multi-language workspaces with integrated AI coding assistants.

## Technology Stack
- Language: Bash, Python 3.11+, TypeScript
- Framework: Docker, Docker Compose
- Infrastructure: Debian Bookworm-slim containers

## Key Conventions
- Use conventional commits (feat:, fix:, docs:, etc.)
- Follow language-specific formatters (ruff, prettier, shellcheck)
- All code must pass linting before commit

## AI Instructions
- Follow existing code patterns in the repository
- Write tests for new functionality
- Never include secrets or API keys in code
- Prefer simple solutions over clever ones
```

### Step 3: Verify

Start a new AI session in your project. The AI tool should reference your documented conventions in its responses.

## 30-Minute Setup (Comprehensive Template)

### Step 1: Generate full template

```bash
./src/scripts/init-context.sh --full
```

### Step 2: Fill in each section

Work through the 9 sections, spending 2-4 minutes on each:

1. **Overview** — Describe what your project does and who it's for
2. **Technology Stack** — List languages, frameworks, databases, infrastructure
3. **Coding Standards** — Reference style guides or list key rules
4. **Architecture** — Describe high-level design and key patterns
5. **Common Patterns** — Show 2-3 frequently used patterns with brief examples
6. **Testing Requirements** — State coverage expectations and test conventions
7. **Git Workflow** — Document branch naming, commit format, PR process
8. **Security Considerations** — Document auth patterns and data handling (no secrets!)
9. **AI Agent Instructions** — List specific do/don't rules for AI tools

### Step 3: Add tool-specific supplement (optional)

If you use Claude Code and want Claude-specific behavior:

```bash
# Create CLAUDE.md alongside AGENTS.md
cat > CLAUDE.md << 'EOF'
# Claude Code Instructions

## Behavior Preferences
- Use the Read tool before suggesting file changes
- Prefer editing existing files over creating new ones
- Run tests after making changes

## Response Style
- Keep responses concise (CLI output context)
- Use markdown formatting for code blocks
EOF
```

## Adding Nested Context (When Needed)

For large projects with distinct modules:

```bash
# API module has different conventions
cat > src/api/AGENTS.md << 'EOF'
# API Module Context

## Module Purpose
REST API service handling all external client requests.

## Local Conventions
- All endpoints follow RESTful naming
- Request/response types defined in types.ts
- Middleware order: auth → validate → handle → error

## Testing
- Integration tests required for all endpoints
- Mock external services in tests
EOF
```

## Verification Checklist

After creating your context files:

- [ ] `AGENTS.md` exists at project root
- [ ] File is under 10KB (`wc -c AGENTS.md`)
- [ ] File uses UTF-8 encoding
- [ ] File uses LF line endings (no `\r`)
- [ ] No secrets, API keys, or passwords in any context file
- [ ] No internal URLs or infrastructure details exposed
- [ ] AI tool reads and references the context in a new session
- [ ] At least Overview, Technology Stack, and AI Instructions sections filled in

## Running Tests

Validate your templates and bootstrap script:

```bash
# Run all context file tests
./tests/bats/bin/bats tests/unit/test_templates.bats tests/unit/test_init_context.bats tests/integration/test_security.bats

# Run ShellCheck on the bootstrap script
shellcheck src/scripts/init-context.sh
```

## Related Documentation

- [Tool Compatibility](../../docs/tool-compatibility.md) — Per-tool discovery behavior
- [Composition Rules](../../docs/composition-rules.md) — How nested context files merge
- [Security Guidance](../../docs/security-guidance.md) — What to include/exclude, pre-commit hooks
- [Test Matrix](../../docs/test-matrix.md) — Manual verification across AI tools

## Troubleshooting

**AI tool doesn't seem to read the file:**
- Verify filename is exactly `AGENTS.md` (case-sensitive)
- Start a new session (most tools read context files at session start)
- Check the tool's documentation for supported context file locations

**File is too large:**
- Move module-specific content to nested `AGENTS.md` files
- Link to external docs (ADRs, wikis) instead of duplicating content
- Remove examples that are better as inline code comments

**Context file contains outdated information:**
- Add "Update AGENTS.md" to your PR review checklist
- Review context files when architecture changes
- Keep sections concise — less content means less to maintain
