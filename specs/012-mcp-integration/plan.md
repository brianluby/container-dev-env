# Implementation Plan: MCP Integration for AI Agent Capabilities

**Branch**: `012-mcp-integration` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-mcp-integration/spec.md`

## Summary

Integrate MCP (Model Context Protocol) servers into the containerized development environment, providing AI agents with access to filesystem, documentation, memory, and external services. Implementation uses a single source configuration file (`.mcp/config.json`) in the project workspace that is translated into each AI tool's native format at container startup via a Bash generation script.

## Technical Context

**Language/Version**: Bash 5.x (config generation, validation scripts), Node.js 22.x LTS (MCP server runtime)
**Primary Dependencies**: @modelcontextprotocol/server-filesystem 2026.1.14, @modelcontextprotocol/server-memory, @modelcontextprotocol/server-sequential-thinking, @upstash/context7-mcp 2.1.0, @modelcontextprotocol/server-github, @playwright/mcp
**Storage**: File-based JSON knowledge graph in Docker volume (`~/.local/share/mcp-memory/memory.json`)
**Testing**: BATS (Bash Automated Testing System) for unit/integration tests
**Target Platform**: Linux container (Debian Bookworm-slim, arm64 + amd64)
**Project Type**: Single project (Dockerfile layer + Bash scripts + JSON config templates)
**Performance Goals**: All configured MCP servers available within 30 seconds of container startup
**Constraints**: <150MB additional image size (all packages combined), stdio transport only, no host-side setup required
**Scale/Scope**: 4 core servers (filesystem, context7, memory, sequential-thinking), 3 optional servers (github, playwright, git), 3 AI tool config formats (Claude Code, Cline, Continue)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | PASS | All MCP servers run inside container; Dockerfile additions are declarative; npm packages pinned to specific versions |
| II. Multi-Language Standards | PASS | Bash scripts follow conventions; Node.js packages are runtime dependencies not custom code |
| III. Test-First Development | PASS | BATS tests planned for config generation, env substitution, security validation |
| IV. Security-First Design | PASS | Credentials via env vars only; never in config files or logs; path traversal blocked by directory allowlist |
| V. Reproducibility & Portability | PASS | npm packages installed with pinned versions in Dockerfile; multi-arch via Node.js LTS; no floating versions |
| VI. Observability & Debuggability | PASS | Startup validation script with structured logging; health check at startup; clear error messages |
| VII. Simplicity & Pragmatism | PASS | Lifecycle delegated to AI tools; simple Bash script for config generation; no over-engineering |

**Gate Result**: ALL PASS. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/012-mcp-integration/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── mcp-source-config.md
│   └── config-generation.md
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
src/
├── mcp/
│   ├── generate-configs.sh       # Reads .mcp/config.json, generates tool-native configs
│   ├── validate-mcp.sh           # Startup validation (checks packages, config, env vars)
│   └── defaults/
│       └── mcp-config.json       # Default source config (all servers, optional disabled)
├── config/
│   ├── cline/
│   │   └── cline_mcp_settings.json  # (existing, will be generated at runtime)
│   └── continue/
│       └── config.yaml.tmpl         # (existing Chezmoi template, independent of MCP generation)

docker/
├── Dockerfile                       # Base image (add Node.js + MCP layer)
├── entrypoint.sh                    # Add MCP init hook

tests/
├── unit/
│   ├── test_config_generation.bats  # Config generation logic
│   ├── test_env_substitution.bats   # Env var substitution
│   └── test_security.bats           # Credential redaction, path blocking
├── integration/
│   └── test_mcp_startup.sh          # End-to-end container startup
└── contract/
    └── test_config_schema.bats      # Source config JSON schema validation
```

**Structure Decision**: Single project structure. MCP integration adds a `src/mcp/` directory for generation/validation scripts, extends the existing `docker/Dockerfile` with a Node.js + npm install layer, and hooks into the existing `docker/entrypoint.sh` for startup validation.

## Complexity Tracking

No violations to justify. Design follows YAGNI — config generation is a single Bash script, not a framework.

## Architecture Decisions

### AD-1: Config Generation via Bash (not Go templates or Node.js)

**Decision**: Use a Bash script with `jq` for JSON manipulation to generate tool-native configs from the source `.mcp/config.json`.

**Rationale**:
- `jq` is already in the base image (001-container-base-image)
- Bash scripts are the established pattern in this project (entrypoint.sh, secrets scripts)
- No additional runtime dependencies needed
- Simple enough that a template engine is over-engineering

**Dependencies**: `jq` (JSON processing, in base image), `python3` with `yaml` module (YAML output for Continue config; Python already in base image, `python3-yaml` package added to Dockerfile).

**Alternatives rejected**:
- Go templates (Chezmoi): Would couple MCP config to dotfile management unnecessarily
- Node.js script: Would require Node.js to be available before MCP servers, adds startup dependency
- `yq` binary: Additional binary to install; `python3 -c "import yaml; ..."` avoids new dependency

### AD-2: Environment Variable Substitution at Generation Time

**Decision**: Substitute `${VARIABLE_NAME}` references during config generation (not at MCP server runtime).

**Rationale**:
- Generated configs contain resolved values, so AI tools can read them natively without custom loaders
- Env vars are available at container startup when generation runs
- Changing env vars requires re-running generation (acceptable trade-off for simplicity)
- Aligns with how the Continue config already handles `${{ secrets.X }}` substitution

### AD-3: Per-Tool Config Generation Targets

**Decision**: Generate into each tool's established config location:
- Claude Code: `/workspace/.claude/settings.local.json` (project scope, `mcpServers` key)
- Cline: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- Continue: `~/.continue/config.yaml` (update `mcpServers` section only)

**Rationale**: Each tool reads its own config format from its own location. Project-scoped configs (Claude Code) are preferred where supported so they travel with the workspace. Continue's MCP section is generated independently of the existing Chezmoi template (`src/config/continue/config.yaml.tmpl`), which handles model configuration separately.

**Note**: For Claude Code, the generation script MUST merge the `mcpServers` key into existing `settings.local.json` content (preserving `permissions` and other keys) rather than overwriting the file.

### AD-4: Dockerfile Layer Strategy

**Decision**: Add MCP server installation as a new stage in the existing `docker/Dockerfile`, after the base development stage.

**Rationale**:
- Keeps MCP layer separable (can be cached independently)
- Follows existing multi-stage pattern
- All packages installed globally via `npm install -g` with pinned versions
- Non-root user installation via NPM_CONFIG_PREFIX

### AD-5: Memory Volume Mount Path

**Decision**: Memory MCP server stores data at `~/.local/share/mcp-memory/memory.json`, backed by a Docker named volume.

**Rationale**:
- Follows XDG Base Directory Specification for application data
- Named volume ensures persistence across container restarts
- Separate from workspace (not version-controlled)
- Single JSON file (knowledge graph) is the default format for @modelcontextprotocol/server-memory

## Implementation Flow

```
Container Build Time:
  Dockerfile → Install Node.js 22.x → npm install -g [all MCP packages]

Container Startup (entrypoint.sh):
  1. Existing volume/permission validation
  2. NEW: Run validate-mcp.sh (check packages installed, config parseable)
  3. NEW: Run generate-configs.sh (source → tool-native configs)
  4. Existing: Execute user command

Developer Workflow:
  Edit .mcp/config.json → Restart AI tool (or re-run generate-configs.sh)
```
