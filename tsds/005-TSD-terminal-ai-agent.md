# Technical Specification Document: 005-terminal-ai-agent

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/005-terminal-ai-agent/` and `prds/005-prd-terminal-ai-agent.md`

## 1. Executive Summary

This document defines the technical specifications for the Terminal AI Agent feature. The primary selection is **OpenCode** for general-purpose terminal assistance, with **Aider** as a specialized option for git-heavy workflows. The implementation focuses on headless, container-native execution with robust API key management via the `003-secret-injection` system.

## 2. Technical Specifications

### 2.1 Tool Selection & Installation
*   **Primary Tool**: OpenCode (Go binary)
    *   **Source**: `curl -fsSL https://opencode.ai/install | bash`
    *   **Installation Path**: `/usr/local/bin/opencode`
    *   **Dependencies**: None (statically linked)
*   **Secondary Tool**: Aider (Python)
    *   **Source**: `pipx install aider-chat` (using `pipx` for isolation)
    *   **Installation Path**: `/root/.local/bin/aider` (symlinked to `/usr/local/bin`)
    *   **Dependencies**: Python 3.10+, git

### 2.2 Container Integration
*   **Dockerfile Layer**: Added after base tools installation.
*   **Health Check**: `opencode --version` and `aider --version` added to `scripts/health-check.sh`.

## 3. Data Models

### 3.1 Configuration Persistence
*   **OpenCode Config**: `~/.config/opencode/config.toml`
    *   **Attributes**: `model_provider`, `temperature`, `system_prompt`.
    *   **Persistence**: Mapped to `home-data` volume (PRD 004).
*   **Aider Config**: `~/.aider.conf.yml`
    *   **Attributes**: `model`, `dark-mode`, `no-auto-commits`.
    *   **Persistence**: Mapped to `home-data` volume.

### 3.2 Session State
*   **Chat History**:
    *   OpenCode: `~/.local/share/opencode/history/`
    *   Aider: `.aider.chat.history.md` (project-local)

## 4. API Contracts & Interfaces

### 4.1 Environment Variables (Secret Injection)
The system requires mapping internal secret names to tool-specific variables at runtime.

| Internal Secret | OpenCode Var | Aider Var | Description |
| :--- | :--- | :--- | :--- |
| `OPENAI_API_KEY` | `OPENAI_API_KEY` | `OPENAI_API_KEY` | OpenAI Model Access |
| `ANTHROPIC_API_KEY` | `ANTHROPIC_API_KEY` | `ANTHROPIC_API_KEY` | Claude Model Access |

### 4.2 CLI Commands
*   `opencode`: Starts the interactive TUI.
*   `aider`: Starts the chat interface.
*   `agent-auth`: A new helper script to validate API keys before starting agents.

## 5. Architectural Improvements

### 5.1 Unified Credential Wrapper
**Problem**: Users might start agents without keys loaded, leading to crashes.
**Solution**: Create wrapper scripts (`/usr/local/bin/opencode-wrap`) that check for required env vars:
```bash
#!/bin/bash
if [[ -z "$OPENAI_API_KEY" && -z "$ANTHROPIC_API_KEY" ]]; then
  echo "Error: No API keys found. Run 'secrets-setup.sh' first."
  exit 1
fi
exec /usr/local/bin/opencode "$@"
```

### 5.2 Performance Optimization
*   **Optimization**: Pre-download model tokenizers or metadata if applicable to speed up cold starts.
*   **Target**: Startup time < 2 seconds.

## 6. Testing Strategy
*   **Integration Test**: Verify `opencode --version` returns success code.
*   **Functional Test**: Inject a dummy API key and verify the agent starts (even if it auth fails downstream, binary execution works).
