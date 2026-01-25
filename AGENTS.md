# Project Context

## Overview

A containerized development environment providing reproducible, multi-language
workspaces with integrated AI coding assistants. The project produces Docker
images, shell scripts, and configuration templates that enable consistent
development across machines with zero manual setup.

Target users: developers who want a portable, pre-configured dev environment
with AI coding tools (OpenCode, Claude Code) available out of the box.

## Technology Stack

- Language: Bash 5.x (scripts), Go templates (Chezmoi configs)
- Container: Docker, Docker Compose, Debian Bookworm-slim base
- Runtime: Python 3.14+, Node.js 22.x LTS
- AI Tools: OpenCode (terminal agent), Claude Code (optional)
- Dotfiles: Chezmoi with age encryption
- Testing: BATS (Bash Automated Testing System), ShellCheck
- Automation: SpecKit scripts (`.specify/scripts/bash/`)

## Coding Standards

- Shell scripts: POSIX-compatible subset of Bash 5.x, ShellCheck clean (zero warnings)
- Use `set -euo pipefail` in all scripts
- Quote all variable expansions: `"${var}"`
- Use `[[ ]]` for conditionals, `$(command)` for substitution
- Functions: lowercase_snake_case; Constants: UPPER_SNAKE_CASE
- Prefer `local` for function variables
- Exit codes: 0=success, 1=runtime error, 2=usage error
- Run formatter before commit (shellcheck, ruff, prettier, rustfmt as applicable)

## Architecture

- Feature-based organization: each feature (001-010) has PRD, spec, plan, tasks
- Source in `src/` with subdirectories per component (docker, scripts, agent, templates)
- Tests in `tests/` with unit/, integration/, contract/ subdirectories
- Specs in `specs/` with per-feature directories
- Docker multi-stage builds for minimal image size
- SpecKit pipeline: specify -> plan -> tasks -> implement

## Common Patterns

- TDD: Write BATS tests first, verify they fail, then implement
- Feature branches: one branch per feature number (e.g., `010-project-context-files`)
- Git worktrees: parallel feature development using separate worktrees
- Template-based config: Chezmoi templates for user-specific values
- Contract testing: verify interfaces between components
- Anti-pattern: never hand-craft branch names; use `create-new-feature.sh`

## Testing Requirements

- BATS for all shell script unit and integration tests
- ShellCheck for static analysis (zero warnings required)
- Test file naming: `test_<feature>.bats` or `test_<feature>.sh`
- Tests must be independent and isolated (use temp directories)
- Integration tests may require Docker (skip gracefully if unavailable)
- Follow AAA pattern: Arrange, Act, Assert
- Every feature needs at least one automated test for main path + edge cases

## Git Workflow

- Branch naming: `NNN-feature-name` (e.g., `010-project-context-files`)
- Commit format: conventional commits (`feat:`, `fix:`, `docs:`, `test:`, `chore:`)
- Subject line under 72 characters, focus on "why" not "what"
- Reference issues: `Fixes #123`
- PR requirements: tests pass, ShellCheck clean, review approved
- Merge strategy: squash merge to main

## Security Considerations

<!-- WARNING: Do NOT include actual secrets, API keys, passwords, or internal URLs.
     Document security PATTERNS and PRACTICES only.
     Use AGENTS.local.md (gitignored) for environment-specific details. -->

- Never commit secrets: use Chezmoi + age encryption for sensitive values
- Environment variables for runtime secrets (never in source)
- Pre-commit hooks recommended: detect-secrets, gitleaks
- Container isolation: least-privilege, non-root user in containers
- Input validation on all script arguments
- Follow OWASP basics for any web-facing components

## AI Agent Instructions

- Read existing code before suggesting changes
- Follow existing patterns in the repository
- Write BATS tests for new shell functionality (TDD)
- Run ShellCheck on any shell script changes
- Use conventional commits for all changes
- Never include secrets, API keys, or internal URLs in code or docs
- Prefer editing existing files over creating new ones
- Keep solutions simple: avoid over-engineering
- Context files must be under 10KB
- Run `.specify/scripts/bash/check-prerequisites.sh` before implementation work
- Use absolute paths in scripts; avoid `cd` when possible

## Project Knowledge

Before implementing features that touch architectural boundaries, read
docs/navigation.md for a map of documented architecture decisions, domain
terminology, and design patterns. Check docs/decisions/ for relevant
Architecture Decision Records before proposing new architectural approaches.

## Active Technologies
- Markdown (repository docs), Bash 5.x for any helper scripts + N/A (static Markdown); Mermaid/ASCII for diagrams (no site generator) (018-docs-overhaul)
- Git repository files (Markdown) (018-docs-overhaul)

## Recent Changes
- 018-docs-overhaul: Added Markdown (repository docs), Bash 5.x for any helper scripts + N/A (static Markdown); Mermaid/ASCII for diagrams (no site generator)
