# 006-prd-agentic-assistant

## Problem Statement

Modern software development increasingly requires AI assistants that can work autonomously
on complex, multi-file tasks over extended periods. While terminal-based agents (PRD 005)
excel at interactive, session-based workflows, there is a need for agentic assistants that
can operate with minimal supervision—running for hours, coordinating sub-tasks, managing
checkpoints, and recovering from failures.

**Critical constraint**: All tools evaluated must run entirely within a Docker container.
Acceptable deployment modes include:
- CLI/TUI running directly in the container terminal
- Web-based interface accessible via browser (e.g., code-server, VS Code Server)
- VS Code extension running inside containerized code-server

Tools requiring native desktop applications or host-side IDE installations are excluded.

## Requirements

### Must Have (M)

- [ ] Autonomous operation capability (can run for extended periods without constant input)
- [ ] Multi-file editing in a single operation with atomic commits
- [ ] Checkpoint/rollback system for safe autonomous exploration
- [ ] Container-compatible (runs headless, no GUI dependencies)
- [ ] Codebase-aware context (can read, search, and understand project structure)
- [ ] API key configuration via environment variables
- [ ] Support for major LLM providers (at minimum: Anthropic Claude)
- [ ] Git integration with clean commit practices
- [ ] Ability to run shell commands and iterate on results
- [ ] Open source or permissive license for commercial use

### Should Have (S)

- [ ] Sub-agent or task delegation capability (parallel workflows)
- [ ] Background task execution (dev servers, watchers)
- [ ] MCP (Model Context Protocol) integration for extensibility
- [ ] Multiple LLM provider support (OpenAI, local models, etc.)
- [ ] Human-in-the-loop approval modes (manual, auto-approve, hybrid)
- [ ] Session persistence and resumption
- [ ] Cost/token usage tracking
- [ ] IDE integration option (VS Code remote or code-server)

### Could Have (C)

- [ ] Browser automation for testing and debugging
- [ ] CI/CD workflow integration (GitHub Actions, etc.)
- [ ] Scheduled/triggered agent execution
- [ ] Mission control dashboard for monitoring agents
- [ ] Custom system prompts and agent personas
- [ ] Integration with issue trackers (GitHub Issues, Linear, Jira)
- [ ] Automatic documentation generation

### Won't Have (W)

- [ ] GUI-only interfaces (must have headless/CLI mode)
- [ ] Self-hosted LLM inference (users provide API keys or use external services)
- [ ] Real-time pair programming (different use case than autonomous agents)
- [ ] Voice input (covered in PRD 014)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Autonomous operation | Must | Can run for hours without user input |
| Container compatibility | Must | Works headless in Docker, no X11/GUI needed |
| Checkpoint/rollback | Must | Safe to let agent explore without data loss |
| Multi-file coherence | Must | Changes across files are consistent and atomic |
| License compatibility | Must | MIT/Apache for open source use |
| Sub-agent/parallelism | High | Delegate and parallelize complex tasks |
| MCP support | High | Extensibility via Model Context Protocol |
| Multi-provider LLMs | High | Not locked to single AI provider |
| CLI/TUI availability | High | Can operate without VS Code running |
| Background tasks | Medium | Long-running processes don't block agent |
| Cost tracking | Medium | Visibility into API spend |
| Active maintenance | Medium | Recent commits, responsive to issues |
| Community adoption | Medium | Documentation, examples, enterprise use |

## Tool Candidates

| Tool | License | Pros | Cons | Spike Result |
|------|---------|------|------|--------------|
| Claude Code | Proprietary (subscription) | Native checkpoints, sub-agents, background tasks, Anthropic-optimized, active development, CLI-native | Anthropic-only, requires subscription (Pro/Max/Teams), proprietary | Pending |
| Cline | Apache 2.0 | Open source, multi-provider (OpenRouter, Anthropic, OpenAI, local), MCP support, human-in-the-loop safety, 4M+ users, enterprise tier available | Primarily VS Code extension, requires IDE runtime for full features, CLI is newer | Pending |
| Roo-Code | Apache 2.0 | Open source, multi-agent role-driven execution, reliable on large multi-file changes, hybrid approval modes, trusted for complex refactors | VS Code-centric, smaller community than Cline, may be slower on some tasks | Pending |
| Continue | Apache 2.0 | Open source, dedicated headless/CLI mode, background agents, Mission Control, CI/CD integration, air-gapped deployment option | Agent mode newer, less mature than competitors for autonomous coding | Pending |

## Detailed Tool Analysis

### Claude Code

**Source**: [GitHub - anthropics/claude-code](https://github.com/anthropics/claude-code) | [Overview](https://code.claude.com/docs/en/overview)

Claude Code is Anthropic's official agentic coding tool. Key autonomous features:

- **Checkpoints**: Automatically saves code state before each change; instant rewind via `Esc Esc` or `/rewind`
- **Sub-agents**: Delegate specialized tasks (e.g., backend API while main agent builds frontend)
- **Hooks**: Automatically trigger actions (run tests after changes, lint before commits)
- **Background tasks**: Keep dev servers running without blocking progress
- **Auto-accept mode**: `Shift+Tab` to toggle autonomous operation

Container compatibility: CLI-native, designed for terminal use. Requires Anthropic subscription.

### Cline

**Source**: [GitHub - cline/cline](https://github.com/cline/cline) | [Website](https://cline.bot/)

Cline is an open-source autonomous coding agent with:

- **Plan/Act modes**: Stepwise planning before execution
- **Human-in-the-loop GUI**: Every action requires explicit approval (configurable)
- **MCP integration**: Extend capabilities via Model Context Protocol
- **Multi-provider**: OpenRouter, Anthropic, OpenAI, Google Gemini, local models (LM Studio/Ollama)
- **Cross-platform**: VS Code extension (primary), CLI tool, JetBrains plugin

Container compatibility: CLI tool available; VS Code extension requires code-server or VS Code Server in container.

### Roo-Code

**Source**: [GitHub - RooCodeInc/Roo-Code](https://github.com/RooCodeInc/Roo-Code) | [Website](https://roocode.com/)

Roo-Code (originally Roo Cline) focuses on reliability for complex tasks:

- **Multi-agent, role-driven execution**: Specialized agents for different task types
- **Approval modes**: Manual, Autonomous/Auto-Approve, or Hybrid
- **Multi-file reliability**: Known for fewer "half-finished edits" on large refactors
- **Model flexibility**: OpenAI, Anthropic, local LLMs

Container compatibility: VS Code-centric; requires code-server or VS Code Server.

### Continue

**Source**: [GitHub - continuedev/continue](https://github.com/continuedev/continue) | [Website](https://www.continue.dev/)

Continue offers both IDE and headless modes:

- **Headless mode**: CLI for async cloud agents
- **TUI mode**: Terminal-based in-sync coding agent
- **Background agents**: Pre-built workflows for GitHub, Sentry, Snyk, Linear
- **Mission Control**: Central dashboard for managing agents
- **Air-gapped deployment**: Can run completely offline with local LLMs

Container compatibility: Excellent—headless/CLI modes designed for containerized and CI/CD environments.

## Selected Approach

[Filled after spike]

## Acceptance Criteria

- [ ] Given a container environment with API keys configured, when I start the agent, then it initializes without error and without GUI
- [ ] Given a complex multi-file task, when I describe the changes, then the agent plans and executes across all relevant files
- [ ] Given autonomous mode enabled, when the agent runs for 30+ minutes, then it continues working without manual intervention
- [ ] Given a failed change attempt, when I request rollback, then the agent restores the previous checkpoint
- [ ] Given a long-running background task (dev server), when I continue working, then the agent handles both concurrently
- [ ] Given a sub-task that can be parallelized, when using sub-agents, then multiple work streams execute simultaneously
- [ ] Given MCP tools configured, when the agent needs external capabilities, then it can invoke MCP servers
- [ ] Given session interruption, when I reconnect, then I can resume the previous context
- [ ] Given completed work, when I review token usage, then I can see cost/usage metrics
- [ ] Given the container image, when I run the agent in Docker, then no additional host dependencies are required

## Dependencies

- Requires: 001-prd-container-base, 003-prd-secret-injection (for API key management), 004-prd-volume-architecture
- Blocks: 007-prd-git-worktree-compat (must validate worktree support)

## Spike Tasks

### Environment Setup

- [ ] Test Claude Code installation in container (verify CLI-only operation)
- [ ] Test Cline CLI installation in container (without VS Code)
- [ ] Test Roo-Code with code-server in container
- [ ] Test Continue headless mode in container
- [ ] Document API key configuration for each tool

### Autonomous Operation

- [ ] Run each tool on a 1-hour autonomous refactoring task
- [ ] Measure checkpoint/rollback reliability for each tool
- [ ] Test sub-agent/parallel task capability (where supported)
- [ ] Verify background task handling (dev servers, watchers)
- [ ] Test recovery from network interruption mid-task

### Multi-File Coherence

- [ ] Execute cross-file refactoring (rename, move, extract) with each tool
- [ ] Verify atomic commits (all related changes in one commit)
- [ ] Test with Python, TypeScript, and Rust codebases
- [ ] Measure success rate on complex multi-file changes

### Integration & Extensibility

- [ ] Test MCP server integration for each tool
- [ ] Evaluate CI/CD integration options (GitHub Actions)
- [ ] Test scheduled/triggered execution (Continue Mission Control)
- [ ] Document IDE integration options for containerized environment

### Comparison Metrics

- [ ] Compare token usage for equivalent tasks across tools
- [ ] Measure time-to-completion for standard benchmark tasks
- [ ] Document licensing requirements and costs
- [ ] Assess community activity (issues, PRs, releases)

## References

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Enabling Claude Code to Work Autonomously](https://www.anthropic.com/news/enabling-claude-code-to-work-more-autonomously)
- [Roo Code vs Cline Comparison (2026)](https://www.qodo.ai/blog/roo-code-vs-cline/)
- [Best AI Coding Agents 2026](https://www.faros.ai/blog/best-ai-coding-agents-2026)
- [Agentic CLI Tools Compared](https://research.aimultiple.com/agentic-cli/)
