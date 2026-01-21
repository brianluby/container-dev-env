# 005-prd-terminal-ai-agent

## Problem Statement

Developers need AI-assisted code generation directly in the terminal without
switching contexts to a web browser or IDE plugin. A terminal-based AI agent
enables hands-free coding workflows, integrates with existing CLI toolchains,
and supports auto-commit for rapid iteration. The containerized dev environment
should include a pre-configured, best-in-class terminal AI agent.

## Requirements

### Must Have (M)

- [ ] Terminal-native interface (no browser or GUI required)
- [ ] Code generation and editing in existing files
- [ ] Git integration with auto-commit capability
- [ ] Support for multiple programming languages (Python, TypeScript, Rust, Go)
- [ ] Context awareness of local codebase (can read/search files)
- [ ] Works within container environment
- [ ] Open source or permissive license for commercial use
- [ ] API key configuration via environment variables

### Should Have (S)

- [ ] Conversation history persistence across sessions
- [ ] Ability to run shell commands with user approval
- [ ] Multi-file editing in a single operation
- [ ] Undo/revert capability for changes
- [ ] Cost tracking or token usage visibility
- [ ] Support for multiple LLM providers (OpenAI, Anthropic, local models)

### Could Have (C)

- [ ] Voice input support
- [ ] Custom system prompts or personas
- [ ] Integration with test runners (auto-run tests after changes)
- [ ] Pair programming mode (real-time suggestions)
- [ ] Project-specific configuration files
- [ ] MCP (Model Context Protocol) server support

### Won't Have (W)

- [ ] GUI interface
- [ ] IDE plugin integration (covered separately if needed)
- [ ] Self-hosted LLM inference (users provide API keys)
- [ ] Code review automation (different workflow)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Terminal-native UX | Must | No browser required for core workflow |
| Auto-commit quality | Must | Clean, atomic commits with good messages |
| Codebase context | Must | Can understand project structure |
| License compatibility | Must | MIT/Apache for open source use |
| Multi-language support | High | Python, TS, Rust, Go at minimum |
| Active maintenance | High | Recent commits, responsive maintainers |
| LLM provider flexibility | High | Not locked to single provider |
| Container compatibility | High | Works headless, no special deps |
| Session persistence | Medium | Resume conversations |
| Token efficiency | Medium | Minimize API costs |
| Community adoption | Medium | Documentation, examples, support |

## Tool Candidates

| Tool | License | Pros | Cons | Spike Result |
|------|---------|------|------|--------------|
| OpenCode | MIT | Go binary (no runtime deps), 75+ LLM providers via Models.dev, MCP support, LSP integration, TUI, 70k GitHub stars, privacy-focused, built-in plan/build agents, GitHub Actions integration | Newer project, less git-specific features than Aider | **Recommended** |
| Aider | Apache 2.0 | Mature, excellent git integration with conventional commits, multi-file editing, supports Claude/OpenAI/DeepSeek/local models, voice coding, active development | Python dependency, can be token-heavy | Strong alternative |
| Claude Code | Elastic 2.0 | Official Anthropic tool, best-in-class context handling, MCP ecosystem, plugin system, Explore subagent | Anthropic-only, source-available (not OSI open source), commercial restrictions | Alternative |
| Codex CLI | Apache 2.0 | OpenAI official, GPT-5.2-Codex state-of-art benchmarks, included with ChatGPT Plus/Pro, full-screen TUI | OpenAI-only, no multi-provider support | Viable |
| Mentat | MIT | Truly open source, RAG-based auto-context, multi-provider (OpenAI/Anthropic/Azure/Ollama) | Less active development, smaller community, fewer features | Not recommended |
| Continue | Apache 2.0 | Multi-provider, extensible, good docs | Primarily IDE-focused, terminal mode limited | Not evaluated |
| GPT Engineer | MIT | Full project generation | More for greenfield, less for editing | Not evaluated |

## Selected Approach

**Primary: OpenCode** with **Aider** as secondary option for git-heavy workflows.

### Rationale for OpenCode

1. **License**: MIT - most permissive OSI-approved license, no restrictions
2. **No Runtime Dependencies**: Go binary - no Python or Node.js required in container
3. **Maximum LLM Flexibility**: 75+ providers via Models.dev including local models (Ollama)
4. **MCP Support**: Model Context Protocol for external tool integration (like Claude Code)
5. **LSP Integration**: Language Server Protocol for code intelligence across languages
6. **Built-in Agents**: `plan` (read-only analysis) and `build` (full development) modes
7. **Privacy-Focused**: No code/context storage - suitable for sensitive environments
8. **Community**: 70k+ GitHub stars, 500+ contributors, 650k monthly users
9. **GitHub Actions**: Native `/opencode` integration for CI workflows

### Installation in Container

```dockerfile
# OpenCode installation (recommended - single binary)
RUN curl -fsSL https://opencode.ai/install | bash

# Or via Go
RUN go install github.com/opencode-ai/opencode@latest
```

### When to Use Aider Instead

- If conventional commits format is critical (Aider has best git integration)
- If voice coding is needed
- If you prefer Python ecosystem tooling
- If you need the `/undo` command for easy rollback

### When to Use Claude Code Instead

- If committed to Anthropic ecosystem exclusively
- If you want official Anthropic support
- Note: Elastic License 2.0 has commercial use restrictions - review before enterprise deployment

### Installation Comparison

| Tool | Install Command | Runtime | Binary Size |
|------|-----------------|---------|-------------|
| OpenCode | `curl -fsSL https://opencode.ai/install \| bash` | None (Go binary) | ~30MB |
| Aider | `pip install aider-install && aider-install` | Python 3.9+ | ~50MB + deps |
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` | Node.js 18+ | ~100MB + deps |
| Codex CLI | `npm install -g @openai/codex` | Node.js | ~80MB + deps |
| Mentat | `pip install mentat` | Python 3.10+ | ~40MB + deps |

### Spike Findings Summary

| Criterion | OpenCode | Aider | Claude Code | Codex CLI | Mentat |
|-----------|----------|-------|-------------|-----------|--------|
| Terminal-native | Yes | Yes | Yes | Yes | Yes |
| Auto-commit | Good | Excellent | Good | Good | Basic |
| Multi-LLM | 75+ providers | ~10 providers | Anthropic only | OpenAI only | ~5 providers |
| License | MIT | Apache 2.0 | Elastic 2.0 | Apache 2.0 | MIT |
| MCP Support | Yes | No | Yes | No | No |
| LSP Integration | Yes | No | No | No | No |
| Multi-file edit | Yes | Yes | Yes | Yes | Yes |
| Session persist | Yes | Yes | Yes | Yes | Limited |
| Active dev | Very High | High | High | High | Medium |
| Container-ready | Excellent | Good | Good | Good | Good |
| Runtime deps | None | Python | Node.js | Node.js | Python |

## Acceptance Criteria

- [ ] Given API keys configured, when I start the agent, then it initializes without error
- [ ] Given a codebase, when I ask "add a function to parse JSON from file", then it creates working code
- [ ] Given code changes, when I approve them, then a clean git commit is created automatically
- [ ] Given a multi-file change request, when I approve, then all files are updated atomically
- [ ] Given the container environment, when I run the agent, then it works without additional setup
- [ ] Given a session, when I exit and restart, then conversation context can be resumed
- [ ] Given token usage, when I complete a task, then I can see approximate cost/tokens used

## Dependencies

- Requires: 001-prd-container-base, 003-prd-secret-injection (for API key management)
- Blocks: none (end-user feature)

## Spike Tasks

- [x] Install and configure OpenCode in container, test TUI and MCP features
- [x] Install and configure Aider in container, test code generation and auto-commit
- [x] Install and configure Claude Code in container, test auth flow and features
- [x] Install and configure Codex CLI in container, test basic operations
- [x] Install and configure Mentat in container, test codebase awareness
- [x] Compare token usage across tools for equivalent tasks
- [x] Evaluate git commit quality (message format, atomicity)
- [x] Test multi-file refactoring workflow in each tool
- [x] Measure startup time and responsiveness
- [x] Document container-specific installation steps for each tool
- [ ] Test with Python, TypeScript, and Rust codebases (deferred to implementation)

## Spike Sources

- [OpenCode Website](https://opencode.ai/) - MIT
- [OpenCode GitHub](https://github.com/opencode-ai/opencode) - MIT
- [OpenCode Documentation](https://opencode.ai/docs/)
- [Aider GitHub](https://github.com/Aider-AI/aider) - Apache 2.0
- [Aider Documentation](https://aider.chat/docs/)
- [Claude Code GitHub](https://github.com/anthropics/claude-code) - Elastic 2.0
- [Claude Code Release Notes](https://releasebot.io/updates/anthropic/claude-code)
- [Codex CLI GitHub](https://github.com/openai/codex) - Apache 2.0
- [OpenAI Codex CLI Docs](https://developers.openai.com/codex/cli/)
- [Mentat AI](https://mentat.ai/)
