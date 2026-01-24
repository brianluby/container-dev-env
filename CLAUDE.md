# container-dev-env Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-20

## Active Technologies
- Bash for installation scripts, Go templates for Chezmoi configs (user-provided) + Chezmoi (single binary, MIT license), age (encryption, optional) (002-dotfile-management)
- File-based (~/.local/share/chezmoi for source, ~ for targets) (002-dotfile-management)
- Bash (shell scripts), Go templates (Chezmoi) + Chezmoi (dotfile manager), age (encryption), existing base container image (003-secret-injection)
- Encrypted files on host filesystem, decrypted to environment variables at runtime (003-secret-injection)
- Bash 5.x (wrapper scripts, entrypoint), Dockerfile (container layer) + OpenCode (MIT, CLI/TUI binary), Claude Code (proprietary, native binary, optional) (006-agentic-assistant)
- Docker volumes for agent state (`~/.local/share/opencode/`, `~/.claude/`, `~/.local/share/agent/`); git stashes for checkpoints (006-agentic-assistant)
- Bash (Dockerfile, scripts), Go templates (Chezmoi configs) + OpenCode (pre-built Go binary, MIT license) (005-terminal-ai-agent)
- File-based (`~/.local/share/opencode/sessions/` for history, `~/.config/opencode/config.yaml` for settings) (005-terminal-ai-agent)
- Bash 5.x (scripts), Dockerfile (container layer), Go templates (Chezmoi configs) + Continue v1.2.14, Cline v3.51.0, @modelcontextprotocol/server-filesystem 2026.1.14, mcp-server-git 2026.1.14 (Python) (009-ai-ide-extensions)
- File-based (YAML, JSON, dotenv) persisted via Docker volumes (009-ai-ide-extensions)
- Bash 5.x (helper scripts), Markdown (documentation format) + None (static Markdown files, no runtime dependencies) (014-project-knowledge)
- File-based (`docs/` directory at project root, version-controlled) (014-project-knowledge)
- Bash 5.x (optional helper script for ADR creation) + None (static Markdown files, no runtime dependencies) (014-project-knowledge)
- Python 3.11+ (MCP server, embedding inference, CLI) + FastEmbed (embeddings), sqlite-vec (vector search), mcp SDK 1.x (server framework), pydantic (models) (013-persistent-memory)
- SQLite with sqlite-vec extension (tactical), Markdown files (strategic) (013-persistent-memory)
- Bash 5.x (config generation, validation scripts), Node.js 22.x LTS (MCP server runtime) + @modelcontextprotocol/server-filesystem 2026.1.14, @modelcontextprotocol/server-memory, @modelcontextprotocol/server-sequential-thinking, @upstash/context7-mcp 2.1.0, @modelcontextprotocol/server-github, @playwright/mcp (012-mcp-integration)
- File-based JSON knowledge graph in Docker volume (`~/.local/share/mcp-memory/memory.json`) (012-mcp-integration)

- Dockerfile (multi-stage), Bash for shell configuration + Debian Bookworm-slim base image, Python 3.14+, Node.js LTS (22.x) (001-container-base-image)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dockerfile (multi-stage), Bash for shell configuration

## Code Style

Dockerfile (multi-stage), Bash for shell configuration: Follow standard conventions

## Recent Changes
- 014-project-knowledge: Added Bash 5.x (optional helper script for ADR creation) + None (static Markdown files, no runtime dependencies)
- 014-project-knowledge: Added Bash 5.x (helper scripts), Markdown (documentation format) + None (static Markdown files, no runtime dependencies)
- 010-project-context-files: Added Bash 5.x (bootstrap script), Markdown (content files) + None (static files + POSIX-compatible shell script)
- 013-persistent-memory: Added Python 3.11+ (MCP server, embedding inference, CLI) + FastEmbed (embeddings), sqlite-vec (vector search), mcp SDK 1.x (server framework), pydantic (models)
- 012-mcp-integration: Added Bash 5.x (config generation, validation scripts), Node.js 22.x LTS (MCP server runtime) + @modelcontextprotocol/server-filesystem 2026.1.14, @modelcontextprotocol/server-memory, @modelcontextprotocol/server-sequential-thinking, @upstash/context7-mcp 2.1.0, @modelcontextprotocol/server-github, @playwright/mcp
- 010-project-context-files: Added Bash 5.x (bootstrap script), Markdown (content files) + None (static files + POSIX-compatible shell script)
- 009-ai-ide-extensions: Added Bash 5.x (scripts), Dockerfile (container layer), Go templates (Chezmoi configs) + Continue v1.2.14, Cline v3.51.0, @modelcontextprotocol/server-filesystem 2026.1.14, mcp-server-git 2026.1.14 (Python)


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
