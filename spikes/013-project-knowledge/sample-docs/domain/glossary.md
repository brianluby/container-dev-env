# Container Dev Env Glossary

<!--
AI Agent Instructions:
- USE THESE TERMS EXACTLY as defined when writing code and documentation
- Do not introduce synonyms or alternative terms
- This glossary defines the ubiquitous language for the project
-->

## Quick Reference

| Term | Definition |
|------|------------|
| Container | Isolated runtime environment for development |
| Dotfiles | User configuration files (shell, git, editor) |
| code-server | VS Code accessible via web browser |
| MCP | Model Context Protocol for AI tool integration |
| Memory Bank | Persistent context storage for AI sessions |
| ADR | Architecture Decision Record |
| Volume | Persistent storage mounted into container |

---

## Core Terms

### Container

**Definition**: An isolated, reproducible runtime environment created from a Docker image that provides all tools needed for development.

**Context**: The primary artifact of this project. Everything runs inside the container.

**Examples**:
- "Start the container with `docker compose up`"
- "The container includes Python 3.14 and Node.js 22"

**Not to be confused with**: Virtual machine (heavier isolation), Docker image (static template)

---

### Development Container (Dev Container)

**Definition**: A container specifically configured for software development, including IDE, tools, and extensions.

**Context**: The complete development environment, not just a runtime.

**Examples**:
- "The dev container has code-server pre-configured"
- "Connect to the dev container at localhost:8443"

---

### Base Image

**Definition**: The foundational Docker image (Debian Bookworm-slim) upon which all other layers are built.

**Context**: Defined in PRD-001. All tools and configurations are added on top.

**Code Reference**: `FROM debian:bookworm-slim` in Dockerfile

---

### Dotfiles

**Definition**: Configuration files typically stored in the user's home directory, starting with a dot (e.g., `.bashrc`, `.gitconfig`).

**Context**: Managed by Chezmoi (PRD-002). Synced from user's personal repo.

**Examples**:
- ".bashrc contains shell aliases"
- "Dotfiles are applied on container startup"

---

### Chezmoi

**Definition**: The dotfile manager tool used to sync, template, and apply user configuration files.

**Context**: Selected in PRD-002 for template support and cross-platform compatibility.

**Code Reference**: Binary at `/usr/local/bin/chezmoi`

---

### Secret

**Definition**: Sensitive credentials (API keys, tokens) that must not be committed to version control.

**Context**: Handled by PRD-003. Injected via environment variables or encrypted files.

**Not to be confused with**: Dotfiles (may be public), configuration (may be committed)

---

### age (encryption)

**Definition**: Modern encryption tool used for encrypting sensitive dotfiles and secrets.

**Context**: Used by Chezmoi for file encryption. Keys stored securely on host.

**Code Reference**: `age-keygen`, `.age` files

---

### Volume

**Definition**: Persistent storage mounted from the host into the container, surviving container restarts.

**Context**: Defined in PRD-004. Used for code, cache, and data persistence.

**Examples**:
- "Code volume mounts ~/code to /workspace"
- "Cache volume persists package downloads"

---

## IDE Terms

### code-server

**Definition**: VS Code running as a server, accessible via web browser.

**Context**: The primary IDE interface (PRD-008). Runs on port 8443 by default.

**Examples**:
- "Access code-server at http://localhost:8443"
- "Extensions are installed via code-server marketplace"

**Not to be confused with**: VS Code Desktop (native app), Remote SSH (different architecture)

---

### Extension

**Definition**: VS Code plugin that adds functionality to the IDE.

**Context**: AI extensions (Continue, Cline) are covered in PRD-009.

**Examples**:
- "Install the Continue extension for AI completions"
- "Extensions are stored in ~/.local/share/code-server/extensions"

---

## AI Terms

### MCP (Model Context Protocol)

**Definition**: Open protocol for connecting AI assistants to external tools and data sources.

**Context**: PRD-011 covers MCP server configuration for tool integration.

**Examples**:
- "MCP servers provide filesystem and git access to AI"
- "Configure MCP in the Continue config.yaml"

---

### Memory Bank

**Definition**: Persistent storage of AI session context across container restarts.

**Context**: PRD-012. Enables AI to remember project context between sessions.

**Examples**:
- "Memory bank stores conversation history"
- "Load memory bank on container start"

---

### Project Knowledge

**Definition**: Structured documentation (ADRs, diagrams, glossary) optimized for AI consumption.

**Context**: PRD-013 (this spike). Helps AI understand the "why" behind code.

---

### Continue

**Definition**: Open-source AI coding assistant extension for VS Code.

**Context**: Primary AI extension (PRD-009). Supports multiple providers.

**Code Reference**: Extension ID `Continue.continue`

---

### Cline

**Definition**: Agentic AI coding assistant with human-in-the-loop safety.

**Context**: Secondary AI extension (PRD-009). Used for complex multi-step tasks.

**Code Reference**: Extension ID `saoudrizwan.claude-dev`

---

## Documentation Terms

### ADR (Architecture Decision Record)

**Definition**: Document capturing a significant architectural decision, its context, and consequences.

**Context**: PRD-013. Stored in `docs/architecture/decisions/`.

**Examples**:
- "ADR-001 documents the Debian base image decision"
- "Create an ADR before making major changes"

---

### PRD (Product Requirements Document)

**Definition**: Document specifying requirements for a feature or component.

**Context**: Each major component has a PRD in `/prds/`.

**Examples**:
- "PRD-001 defines base image requirements"
- "Check the PRD before implementing"

---

### Spike

**Definition**: Time-boxed research or prototyping to validate an approach before implementation.

**Context**: Stored in `/spikes/NNN-feature-name/`.

**Examples**:
- "Run a spike to evaluate AI extensions"
- "Spike results inform the PRD selection"

---

## Status Terms

| Status | Meaning | Use In |
|--------|---------|--------|
| **Proposed** | Under discussion, not approved | ADRs |
| **Accepted** | Approved, in effect | ADRs |
| **Deprecated** | No longer recommended | ADRs, features |
| **Superseded** | Replaced by newer decision | ADRs |
| **Pending** | Not started | PRD requirements |
| **In Progress** | Currently being worked on | PRD requirements |
| **Completed** | Done and verified | PRD requirements |

---

## Deprecated Terms

| Deprecated | Replacement | Reason |
|------------|-------------|--------|
| "devbox" | "container" | Consistency |
| "workspace" | "container" or "project" | Ambiguous |

---

## References

- [Architecture Overview](../architecture/overview.md)
- [Domain Model](./model.md)
- [PRD Directory](../../../prds/)
