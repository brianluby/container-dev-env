# AGENTS.md Template (Full)

<!--
  This template follows the AGENTS.md specification (https://agents.md/)
  AGENTS.md is recognized by 25+ AI coding tools including:
  Claude Code, Cline, Roo-Code, Continue, OpenCode, Cursor, Windsurf, and more.

  The spec is stewarded by the Linux Foundation.

  Key principles:
  - Closest file to edited file takes precedence
  - Nested files supplement (not replace) parent context
  - Flexible markdown format - use what you need
-->

# Project: {PROJECT_NAME}

## Overview

{Brief 2-3 sentence description of what this project does}

**Status**: {Active Development | Maintenance | Beta | Production}
**Primary Language**: {e.g., Python 3.12, TypeScript 5.x, Rust 1.75+}
**Domain**: {e.g., Web Application, CLI Tool, Library, Infrastructure}

## Goals

- {Primary goal of this project}
- {Secondary goal}
- {Non-goals or explicit out-of-scope items}

## Technology Stack

### Languages & Runtimes
- **Primary**: {Language version}
- **Secondary**: {If applicable}

### Frameworks
- {Framework name and version}
- {Framework name and version}

### Database & Storage
- **Primary DB**: {e.g., PostgreSQL 16}
- **Cache**: {e.g., Redis 7.x}
- **Storage**: {e.g., S3-compatible}

### Infrastructure
- **Containerization**: {e.g., Docker, Podman}
- **Orchestration**: {e.g., Kubernetes, Docker Compose}
- **CI/CD**: {e.g., GitHub Actions, GitLab CI}
- **Cloud**: {e.g., AWS, GCP, Azure, self-hosted}

### Key Dependencies
- {Dependency}: {Purpose}
- {Dependency}: {Purpose}
- {Dependency}: {Purpose}

## Project Structure

```
{project-name}/
├── src/                    # Source code
│   ├── {module}/           # {Description}
│   └── {module}/           # {Description}
├── tests/                  # Test files
├── docs/                   # Documentation
├── scripts/                # Build/deploy scripts
└── {other}/                # {Description}
```

## Coding Standards

### Style Guide
- {Reference to style guide, e.g., "Follow PEP 8", "Use Prettier defaults"}
- {Linter/formatter used, e.g., "Run `ruff check` before commits"}

### Naming Conventions
- **Files**: {e.g., snake_case.py, kebab-case.ts}
- **Classes**: {e.g., PascalCase}
- **Functions**: {e.g., snake_case, camelCase}
- **Constants**: {e.g., SCREAMING_SNAKE_CASE}
- **Variables**: {e.g., snake_case, camelCase}

### Code Organization
- {Pattern, e.g., "One class per file"}
- {Pattern, e.g., "Group imports: stdlib, third-party, local"}
- {Pattern, e.g., "Keep functions under 50 lines"}

### Error Handling
- {Pattern, e.g., "Use Result types over exceptions"}
- {Pattern, e.g., "Always log errors with context"}
- {Pattern, e.g., "Fail fast for unrecoverable errors"}

### Documentation
- {Standard, e.g., "Docstrings for all public APIs"}
- {Standard, e.g., "README in each module directory"}
- {Standard, e.g., "Update CHANGELOG for user-facing changes"}

## Architecture

### High-Level Design
{Brief description of the system architecture - 2-3 sentences}

### Key Patterns
- **{Pattern Name}**: {How it's used in this project}
- **{Pattern Name}**: {How it's used in this project}

### Module Boundaries
- **{Module A}** is responsible for {X} and should NOT know about {Y}
- **{Module B}** handles {Z} and exposes {interfaces}

### Data Flow
{Brief description of how data moves through the system}

## Common Patterns

### Pattern: {Name}
**When to use**: {Scenario}
**Example**:
```{language}
{code example}
```

### Pattern: {Name}
**When to use**: {Scenario}
**Example**:
```{language}
{code example}
```

## Anti-Patterns (Avoid)

- **{Anti-pattern}**: {Why it's problematic in this codebase}
- **{Anti-pattern}**: {Why it's problematic in this codebase}

## Testing Requirements

### Test Coverage
- **Minimum**: {e.g., 80% line coverage}
- **Critical paths**: {e.g., 100% for auth, payments}

### Testing Frameworks
- **Unit**: {e.g., pytest, Jest}
- **Integration**: {e.g., pytest-integration, Supertest}
- **E2E**: {e.g., Playwright, Cypress}

### Testing Conventions
- {Convention, e.g., "Test files mirror source structure"}
- {Convention, e.g., "Use AAA pattern: Arrange, Act, Assert"}
- {Convention, e.g., "Name tests: test_{function}_{scenario}_{expected}"}

### Running Tests
```bash
# Run all tests
{command}

# Run specific test
{command}

# Run with coverage
{command}
```

## Git Workflow

### Branch Naming
- `main` - Production-ready code
- `develop` - Integration branch (if used)
- `feature/{ticket}-{description}` - New features
- `fix/{ticket}-{description}` - Bug fixes
- `chore/{description}` - Maintenance tasks

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
{type}({scope}): {subject}

{body}

{footer}
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Requirements
- {Requirement, e.g., "All tests passing"}
- {Requirement, e.g., "At least 1 approval"}
- {Requirement, e.g., "No merge conflicts"}
- {Requirement, e.g., "Linked to issue/ticket"}

## Security Considerations

### Authentication & Authorization
- {Pattern, e.g., "Use JWT with RS256 signing"}
- {Pattern, e.g., "RBAC via middleware"}

### Sensitive Data
- {Policy, e.g., "Never log PII"}
- {Policy, e.g., "Encrypt at rest and in transit"}
- {Policy, e.g., "Use environment variables for secrets"}

### Input Validation
- {Standard, e.g., "Validate all external input at boundaries"}
- {Standard, e.g., "Use parameterized queries only"}
- {Standard, e.g., "Sanitize output for XSS prevention"}

### Dependencies
- {Policy, e.g., "Audit deps weekly with `npm audit`"}
- {Policy, e.g., "Pin exact versions in production"}

## Environment Setup

### Prerequisites
- {Tool} {version}
- {Tool} {version}

### Local Development
```bash
# Clone the repository
git clone {repo-url}
cd {project-name}

# Install dependencies
{command}

# Configure environment
cp .env.example .env
# Edit .env with your values

# Start development
{command}
```

### Environment Variables
| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `{VAR}` | {Description} | {Yes/No} | {value} |

## AI Agent Instructions

### General Preferences
- {Preference, e.g., "Prefer explicit over implicit code"}
- {Preference, e.g., "Keep functions focused and small"}
- {Preference, e.g., "Avoid premature optimization"}

### Always Do
- {Rule, e.g., "Run tests before suggesting code is complete"}
- {Rule, e.g., "Check existing patterns before creating new ones"}
- {Rule, e.g., "Use existing utilities from `src/utils/`"}

### Never Do
- {Rule, e.g., "Never commit secrets or credentials"}
- {Rule, e.g., "Don't introduce new dependencies without discussion"}
- {Rule, e.g., "Don't modify generated files directly"}

### When Making Changes
1. {Step, e.g., "Read the existing code first"}
2. {Step, e.g., "Check for similar implementations"}
3. {Step, e.g., "Follow established patterns"}
4. {Step, e.g., "Add tests for new functionality"}
5. {Step, e.g., "Update documentation if needed"}

## Troubleshooting

### Common Issues
- **{Issue}**: {Solution}
- **{Issue}**: {Solution}

### Debugging Tips
- {Tip, e.g., "Enable debug logging with DEBUG=* npm start"}
- {Tip, e.g., "Use pdb for Python debugging"}

## Contacts & Resources

### Team
- **Maintainer**: {Name/Handle}
- **Code Owners**: See CODEOWNERS file

### Resources
- [Documentation]({url})
- [Issue Tracker]({url})
- [Wiki/Confluence]({url})

---

<!--
  Maintenance Notes:
  - Update this file when project patterns change
  - Review quarterly for accuracy
  - Keep sections relevant - remove unused ones
  - Add nested AGENTS.md for complex modules
-->
