# Domain Glossary

> Project-specific terminology and business concepts.
> AI agents: use these terms consistently in generated code and responses.

## Terms

### ADR (Architecture Decision Record)

**Definition**: A document capturing a significant architectural decision — one that constrains future choices or would be costly to reverse — along with its context, alternatives considered, and consequences.

**Aliases**: Decision Record, Architecture Decision

**Code mapping**: Files in `docs/decisions/NNN-kebab-title.md`; status field values: `proposed`, `accepted`, `deprecated`, `superseded`

**Related terms**: Navigation Guide, Documentation Category

---

### Chezmoi

**Definition**: A dotfile management tool (single Go binary, MIT license) used to template and deploy user configuration files into the container development environment. Supports age encryption for secrets.

**Aliases**: None (always use "Chezmoi")

**Code mapping**: Source directory at `~/.local/share/chezmoi/`; templates use Go template syntax (`.tmpl` extension)

**Related terms**: DevContainer, Feature Branch

---

### DevContainer

**Definition**: A containerized, reproducible development environment built from a Dockerfile, providing pre-configured language runtimes, tools, and AI coding assistants. The primary artifact produced by this project.

**Aliases**: Development Container, Dev Environment

**Code mapping**: `Dockerfile` and `docker/Dockerfile.*` define the container layers; `docker-compose.yml` orchestrates services

**Related terms**: Feature Branch, SpecKit

---

### Feature Branch

**Definition**: A git branch dedicated to implementing a single numbered feature, following the naming convention `NNN-feature-name` (e.g., `014-project-knowledge`). Created by `create-new-feature.sh` and merged to main via squash merge.

**Aliases**: None (always use "Feature Branch" or the specific branch name)

**Code mapping**: Branch naming pattern `NNN-feature-name`; specs live in `specs/NNN-feature-name/`

**Related terms**: SpecKit, ADR

---

### Navigation Guide

**Definition**: An AI-specific entry point document (`docs/navigation.md`) that maps documentation categories to file locations, referenced from AGENTS.md. Acts as a routing table for AI agents to find relevant project knowledge.

**Aliases**: Doc Nav, AI Navigation

**Code mapping**: Single file at `docs/navigation.md`; referenced from `AGENTS.md` "Project Knowledge" section

**Related terms**: ADR, Documentation Category

---

### SpecKit

**Definition**: The specification-driven development pipeline used by this project. Consists of a series of commands (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`) that transform feature descriptions into structured specs, implementation plans, and task breakdowns.

**Aliases**: Specify Pipeline, Spec Pipeline

**Code mapping**: Scripts in `.specify/scripts/bash/`; templates in `.specify/templates/`; output in `specs/NNN-feature-name/`

**Related terms**: Feature Branch, ADR

---

### Documentation Category

**Definition**: A logical grouping of related documents within the `docs/` directory, each with its own subdirectory and purpose. Standard categories: architecture, decisions, api, domain, operations, security.

**Aliases**: Doc Category

**Code mapping**: Subdirectories under `docs/`: `architecture/`, `decisions/`, `api/`, `domain/`, `operations/`, `security/`

**Related terms**: Navigation Guide, ADR
