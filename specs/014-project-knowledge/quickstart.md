# Quickstart: Project Knowledge Documentation System

## Prerequisites

- A project repository with an existing AGENTS.md (from feature 010-project-context-files)
- Bash 5.x (for the optional ADR creation script)

## Setup Steps

### 1. Create the Directory Structure

```bash
mkdir -p docs/{architecture,decisions,api,domain,operations,security}
```

### 2. Add the Navigation Guide

Copy the navigation guide template to `docs/navigation.md`:

```bash
cp specs/014-project-knowledge/contracts/navigation-guide-template.md docs/navigation.md
```

Edit `docs/navigation.md` to update file paths to match your project's actual documentation files.

### 3. Add the ADR Template

```bash
cp specs/014-project-knowledge/contracts/adr-template.md docs/decisions/_template.md
```

### 4. Update AGENTS.md

Add the following section to your project's AGENTS.md:

```markdown
## Project Knowledge

Before implementing features that touch architectural boundaries, read
docs/navigation.md for a map of documented architecture decisions, domain
terminology, and design patterns. Check docs/decisions/ for relevant
Architecture Decision Records before proposing new architectural approaches.
```

### 5. Create Your First ADR

```bash
# Copy template
cp docs/decisions/_template.md docs/decisions/001-your-first-decision.md

# Edit with your decision details
# Fill in: Status, Date, Context, Decision, Alternatives, Consequences
```

### 6. Add Core Documentation (as needed)

Create documents based on your project's needs:

- `docs/architecture/overview.md` — system structure and component relationships
- `docs/domain/glossary.md` — project-specific terminology
- `docs/api/principles.md` — API design principles
- `docs/operations/deployment.md` — deployment procedures
- `docs/security/authentication.md` — security patterns

Use templates from `specs/014-project-knowledge/contracts/` as starting points.

## Verification

After setup, verify the system works:

1. **Structure check**: `find docs/ -type f -name "*.md" | sort`
2. **Size check**: No file should exceed 500 lines: `wc -l docs/**/*.md`
3. **Navigation check**: All paths in `docs/navigation.md` resolve to existing files
4. **AI test**: Ask an AI agent "what architectural decisions has this project made?" — it should reference your ADRs

## Creating New ADRs

When making a decision that constrains future choices or would be costly to reverse:

1. Determine the next number: `ls docs/decisions/ | grep -E '^[0-9]' | tail -1`
2. Copy template: `cp docs/decisions/_template.md docs/decisions/NNN-kebab-title.md`
3. Fill in all sections (target: under 15 minutes)
4. Commit and push

## Guidelines

- Keep all documents under 500 lines
- Use Mermaid for diagrams (flowcharts and sequence diagrams preferred)
- Keep Mermaid diagrams under 15 nodes each
- Add prose descriptions before every diagram
- Use descriptive node IDs in diagrams (`AuthService` not `A`)
- Label all diagram edges (`A -->|authenticates| B`)
- Update `docs/navigation.md` when adding new document categories
