# Advanced Guide

This guide covers customization, AI tooling, MCP integration, and the
spec-driven workflow. It assumes you already know how to start the container.

## Mental model: layered, opt-in capabilities

The system is built in layers you can opt into as needed:

- Base container image and runtime tools
- Hybrid volume architecture for performance and persistence
- Secrets management with encrypted-at-rest values
- AI tools and agent wrappers
- MCP configuration that feeds multiple tools

See `docs/architecture/overview.md` and
`docs/decisions/005-container-image-architecture.md` for deeper context.

## Runtime modes

### Mode A: Compose-based dev shell (default)

- Compose file: `docker/docker-compose.yml`
- Best when you want: local IDE + container builds + fast volume performance

### Mode B: Agent-enabled container

- Agent wrapper: `src/agent/agent.sh`
- Compose override: `docker/docker-compose.agent.yml`

Start:

```bash
docker compose -f docker/docker-compose.yml -f docker/docker-compose.agent.yml \
  up -d --build
```

Environment variables to know:

- `AGENT_BACKEND` (default: `opencode`, or `claude`)
- `AGENT_MODE` (`manual`, `auto`, `hybrid`)
- Provider keys: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`
- Server auth: `OPENCODE_SERVER_PASSWORD`

See `src/agent/agent.sh` for the full usage block.

### Mode C: Containerized IDE

Quickstart: `docs/quickstarts/008-containerized-ide.md`

Use this when you want a browser-based IDE without local installation.

### Mode D: IDE + AI extensions

Quickstart: `docs/quickstarts/009-ai-ide-extensions.md`

Use this when you want pre-installed IDE extensions, templated configs,
and controlled telemetry defaults.

## Volume architecture customization

The default setup is intentionally hybrid:

- `/workspace` bind mount for host IDE edits
- Named volumes for caches and heavy I/O paths
- `tmpfs` for `/tmp` scratch space

Customization points:

- Change the host workspace path with `WORKSPACE_PATH` in
  `docker/docker-compose.yml` (defaults to the repo root because the compose
  file lives under `docker/`).
- Adjust which directories are backed by named volumes (tradeoff:
  performance vs host visibility).

See `docs/volume-architecture.md` for the full matrix of mounts and tradeoffs.

## Secrets and security model

Secrets are encrypted at rest and only injected at runtime (Chezmoi + age).
They are not baked into images and should never be stored in context files.

- Secrets guide: `docs/secrets-guide.md`
- Security guidance: `docs/security-guidance.md`
- Auth patterns if you build services: `docs/security/authentication.md`

## MCP integration

MCP provides a single config that can be translated into tool-specific configs.

Workflow:

1. Create or edit `/workspace/.mcp/config.json`
2. Validate: `src/mcp/validate-mcp.sh`
3. Generate tool configs: `src/mcp/generate-configs.sh`
4. Restart your AI tool so it reloads the generated config

See `src/mcp/defaults/README.md` and `docs/quickstarts/012-mcp-integration.md`.

## Persistent memory

Quickstart: `docs/quickstarts/013-persistent-memory.md`

Two layers:

- Strategic memory: versioned markdown in `.memory/`
- Tactical memory: persisted storage for session learnings

Use strategic memory for stable project truths and tactical memory for
searchable, session-level notes.

## Context file composition

AI tools load rules from project-level context files:

- Root entrypoint: `AGENTS.md`
- Tool-specific rules: `CLAUDE.md` (and other tool files as needed)
- Local-only overrides: `AGENTS.local.md` (gitignored)

Read these for behavior and file discovery:

- `docs/tool-compatibility.md`
- `docs/composition-rules.md`
- `docs/navigation.md`

## Spec-driven workflow (contributors)

This repo is designed for spec-first development and feature-scoped branches.

- Pipeline overview: `docs/spec-driven-development-pipeline.md`
- Create new feature worktrees: `.specify/scripts/bash/create-new-feature.sh`
- Check prerequisites before implementation:
  `.specify/scripts/bash/check-prerequisites.sh`

## Optional workflows

- Voice input quickstart: `docs/quickstarts/015-voice-input.md`
- Mobile notifications: `docs/quickstarts/016-mobile-access.md`

## Suggested reading paths

- Faster installs and persistence: `docs/volume-architecture.md`
- Secrets done right: `docs/secrets-guide.md`
- AI tool context composition: `docs/tool-compatibility.md`
- MCP + memory: `docs/quickstarts/012-mcp-integration.md` and
  `docs/quickstarts/013-persistent-memory.md`
- Contributor workflow: `docs/spec-driven-development-pipeline.md`
