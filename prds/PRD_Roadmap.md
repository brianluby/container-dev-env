# PRD Roadmap: AI-Assisted Development Environment

## Overview

This roadmap defines capability-based PRDs for building a containerized, reproducible AI-assisted development workflow. Each PRD is tool-agnostic—tool selection happens as part of the deliverable through hands-on spikes.

**Principles:**
- Container-first: Everything runs in containers for isolation and reproducibility
- Open source: All tools must be MIT-compatible (repo will be MIT licensed)
- Capability-driven: PRDs define *what*, not *which tool*

---

## Phase 1: Container Foundation

| PRD | Capability | Scope | Tool Selection Included |
|-----|------------|-------|-------------------------|
| 001-prd-container-base | Development Container Base | Base image, user config, shell environment | Evaluate: Ubuntu vs Debian vs Alpine vs Wolfi |
| 002-prd-dotfile-management | Dotfile Management | Reproducible config across machines | Evaluate: Chezmoi vs stow vs bare git repo vs Nix home-manager |
| 003-prd-secret-injection | Secret Injection Pattern | API keys, tokens enter container securely | Evaluate: Docker secrets vs sops vs age-encrypted dotfiles vs Vault |
| 004-prd-volume-architecture | Volume Architecture | Workspace, home, ephemeral boundaries | Design decision, not tool selection |

---

## Phase 2: AI Agent Layer

| PRD | Capability | Scope | Tool Selection Included |
|-----|------------|-------|-------------------------|
| 005-prd-terminal-ai-agent | Terminal-Based AI Agent | CLI agent for code generation with auto-commit | Evaluate: aider vs Claude Code vs Codex CLI vs mentat |
| 006-prd-agentic-assistant | Agentic Code Assistant | Long-running, multi-file autonomous coding | Evaluate: Claude Code vs Cline vs Roo-Code vs Continue |
| 007-prd-git-worktree-compat | Git Worktree Compatibility | Agent works correctly in worktree-based workflow | Acceptance criteria, applied to selected tools |

---

## Phase 3: IDE Layer

| PRD | Capability | Scope | Tool Selection Included |
|-----|------------|-------|-------------------------|
| 008-prd-containerized-ide | Containerized IDE | Browser-accessible or remote-attached IDE | Evaluate: code-server vs OpenVSCode-Server vs JetBrains Gateway vs native remote SSH |
| 009-prd-ai-ide-extensions | AI IDE Extensions | In-editor AI assistance (completions, chat) | Evaluate: Continue vs Cline vs Roo-Code vs Copilot |
| 010-prd-project-context-files | Project Context Files | Static context that agents always see | Design: `.cursorrules` equivalent, `AGENTS.md`, conventions |

---

## Phase 4: Context & Memory

| PRD | Capability | Scope | Tool Selection Included |
|-----|------------|-------|-------------------------|
| 011-prd-mcp-integration | MCP Integration | Model Context Protocol for tool access | Evaluate: Which MCP servers, native vs containerized |
| 012-prd-persistent-memory | Persistent Memory | Cross-session context retention | Evaluate: MCP Memory vs vector store vs markdown knowledge base |
| 013-prd-project-knowledge | Project Knowledge Structure | Standardized documentation for AI consumption | Design: memory-bank pattern vs ADRs vs custom |

---

## Phase 5: Input/Output

| PRD | Capability | Scope | Tool Selection Included |
|-----|------------|-------|-------------------------|
| 014-prd-voice-input | Voice Input | Dictation to IDE/terminal | Evaluate: Superwhisper vs Whisper.cpp vs macOS Dictation vs Talon |
| 015-prd-mobile-access | Mobile Access | Trigger/monitor agents from phone | Evaluate: Happy vs custom webhook vs SSH app |

---

## Dependency Graph

```
001-container-base
 ├── 002-dotfile-management
 ├── 003-secret-injection
 └── 004-volume-architecture
      ├── 005-terminal-ai-agent
      │    └── 007-git-worktree-compat
      ├── 006-agentic-assistant
      │    └── 007-git-worktree-compat
      └── 008-containerized-ide
           ├── 009-ai-ide-extensions
           ├── 010-project-context-files
           └── 011-mcp-integration
                ├── 012-persistent-memory
                └── 013-project-knowledge

014-voice-input ─────► (integrates with 005, 006, 008)
015-mobile-access ───► (integrates with 006)
```

---

## PRD Template

See `templates/prd-template.md` for the standard PRD structure using MoSCoW prioritization.