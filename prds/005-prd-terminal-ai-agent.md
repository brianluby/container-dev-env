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
| Aider | Apache 2.0 | Mature, excellent git integration, multi-file editing, supports many LLMs, active development | Python dependency, can be token-heavy | Pending |
| Claude Code | Proprietary (free tier) | Official Anthropic tool, excellent context handling, built-in tools, MCP support | Anthropic-only, requires auth flow | Pending |
| Codex CLI | MIT | OpenAI official, simple interface | OpenAI-only, less mature, limited features | Pending |
| Mentat | MIT | Open source, good codebase understanding, Anthropic/OpenAI support | Smaller community, less documentation | Pending |
| Continue | Apache 2.0 | Multi-provider, extensible, good docs | Primarily IDE-focused, terminal mode limited | Not evaluated |
| GPT Engineer | MIT | Full project generation | More for greenfield, less for editing | Not evaluated |

## Selected Approach

[Filled after spike]

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

- [ ] Install and configure Aider in container, test code generation and auto-commit
- [ ] Install and configure Claude Code in container, test auth flow and features
- [ ] Install and configure Codex CLI in container, test basic operations
- [ ] Install and configure Mentat in container, test codebase awareness
- [ ] Compare token usage across tools for equivalent tasks
- [ ] Evaluate git commit quality (message format, atomicity)
- [ ] Test multi-file refactoring workflow in each tool
- [ ] Measure startup time and responsiveness
- [ ] Document container-specific installation steps for each tool
- [ ] Test with Python, TypeScript, and Rust codebases
