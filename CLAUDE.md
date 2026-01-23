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
- 007-git-worktree-compat: Added Bash (POSIX-compatible, targeting bash 5.x in Debian Bookworm) + git CLI (already in base image per 001-container-base-image)
- 006-agentic-assistant: Added Bash 5.x (wrapper scripts, entrypoint), Dockerfile (container layer) + OpenCode (MIT, CLI/TUI binary), Claude Code (proprietary, native binary, optional)
- 005-terminal-ai-agent: Added Bash (Dockerfile, scripts), Go templates (Chezmoi configs) + OpenCode (pre-built Go binary, MIT license)
- 003-secret-injection: Added Bash (shell scripts), Go templates (Chezmoi) + Chezmoi (dotfile manager), age (encryption), existing base container image
- 004-volume-architecture: Added Bash (entrypoint scripts), Dockerfile (multi-stage) + Docker 24+, Docker Compose 2.x, Docker Buildx (multi-arch)


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
