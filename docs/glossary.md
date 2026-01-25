# Glossary

Project-specific terminology used across the documentation and the codebase.

## Prerequisites

- None

## Terms

### ADR (Architecture Decision Record)

Definition: A document capturing a significant architectural decision (one that constrains future choices or would be costly to reverse), along with its context, alternatives considered, and consequences.

Aliases: Decision Record, Architecture Decision

Code mapping: Files in `docs/decisions/NNN-kebab-title.md`; common status values include `proposed`, `accepted`, `deprecated`, `superseded`.

Related terms: Documentation Category, Navigation Map

---

### Chezmoi

Definition: A dotfile management tool (single Go binary) used to template and deploy user configuration files into the development environment. Supports age encryption for secrets.

Aliases: None (use "Chezmoi")

Code mapping: Source directory at `~/.local/share/chezmoi/`; templates use Go template syntax (`.tmpl`).

Related terms: DevContainer, Secrets Management

---

### DevContainer

Definition: A containerized, reproducible development environment built from a Dockerfile and orchestrated with Docker Compose.

Aliases: Development Container, Dev Environment

Code mapping: `docker/Dockerfile` defines the image; `docker/docker-compose.yml` orchestrates the runtime.

Related terms: Feature Branch, Volume Architecture

---

### Feature Branch

Definition: A git branch dedicated to implementing a single numbered feature, following the naming convention `NNN-feature-name`. Feature branches are created via `.specify/scripts/bash/create-new-feature.sh` and are typically merged via squash.

Aliases: None

Code mapping: Specs live under `specs/NNN-feature-name/`.

Related terms: SpecKit, ADR

---

### Navigation Map

Definition: The human-maintained map of the docs tree at `docs/navigation.md`. It provides a routing table for finding documentation by task/role.

Aliases: Doc Nav

Code mapping: `docs/navigation.md`

Related terms: Documentation Category, ADR

---

### SpecKit

Definition: The specification-driven development pipeline used by this repository. It consists of commands that generate a feature spec, plan, and tasks, then guide implementation.

Aliases: Spec pipeline

Code mapping: Scripts in `.specify/scripts/bash/`; output in `specs/NNN-feature-name/`.

Related terms: Feature Branch, ADR

---

### Documentation Category

Definition: A top-level intent-based grouping under `docs/`.

Standard categories:

- `docs/getting-started/`
- `docs/features/`
- `docs/operations/`
- `docs/architecture/`
- `docs/contributing/`
- `docs/reference/`

Related terms: Navigation Map

## Related

- [Navigation](navigation.md)
- [Decisions](decisions/)

## Next steps

- If you are new here: [Getting Started](getting-started/index.md)
