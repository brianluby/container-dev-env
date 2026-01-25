# Contributor Workflow

This repository uses a spec-driven workflow to keep changes scoped, reviewable, and well documented.

Applies to: `main`

## Prerequisites

- [Contributing](index.md)
- You can run Docker + Compose on your machine

## Spec-driven development

The primary workflow is documented in [Spec-Driven Development](spec-driven-development.md).

High-level loop:

1. Clarify the change
2. Write a spec
3. Create a plan
4. Break down tasks
5. Implement + test
6. Update docs in the same PR when behavior/config changes (FR-013)

## Branching strategy

- One feature per branch/worktree
- Branch naming: `NNN-feature-name` (feature number prefix)
- Prefer using the helper: `.specify/scripts/bash/create-new-feature.sh`

## Pull request checklist

- Code changes follow repo standards (shell scripts are ShellCheck clean)
- Tests pass locally (see [Testing](testing.md))
- User-facing behavior/config changes include corresponding docs updates (FR-013)
- New docs pages follow the [Page Template](../_page-template.md) (Prerequisites/Related/Next steps)

## Related

- [Spec-Driven Development](spec-driven-development.md)
- [Testing](testing.md)
- [Project Structure](project-structure.md)

## Next steps

- Run the local checks: [Testing](testing.md)
