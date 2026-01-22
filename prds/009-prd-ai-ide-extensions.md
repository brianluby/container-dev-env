# 009-prd-ai-ide-extensions

## Problem Statement

Developers using containerized IDEs need AI-powered assistance for code completions, inline
suggestions, chat-based help, and intelligent refactoring. These AI capabilities must work
within the containerized IDE environment (code-server or equivalent) without requiring
additional host-side installations or breaking container isolation.

**Critical constraint**: All AI extensions must run within the containerized IDE (code-server,
OpenVSCode-Server, or JetBrains backend). Extensions requiring native host components or
desktop-only features are excluded.

## Requirements

### Must Have (M)

- [ ] Works in containerized VS Code (code-server or OpenVSCode-Server)
- [ ] Inline code completions (autocomplete as you type)
- [ ] Chat interface for code questions and explanations
- [ ] Multi-language support (Python, TypeScript, Rust, Go at minimum)
- [ ] API key configuration via environment variables
- [ ] No host-side dependencies
- [ ] Reasonable token efficiency (not excessively expensive)

### Should Have (S)

- [ ] Context-aware completions (understands project structure)
- [ ] Code generation from natural language descriptions
- [ ] Inline code editing/refactoring suggestions
- [ ] Multiple LLM provider support (not locked to single vendor)
- [ ] MCP (Model Context Protocol) integration
- [ ] Open source or source-available
- [ ] Cost/usage visibility

### Could Have (C)

- [ ] Codebase indexing for improved context
- [ ] Custom system prompts or personas
- [ ] Team/enterprise features (shared context, policies)
- [ ] Inline documentation generation
- [ ] Test generation from code
- [ ] Code review assistance

### Won't Have (W)

- [ ] Extensions requiring desktop-only VS Code
- [ ] Proprietary extensions not available on Open VSX
- [ ] Self-hosted LLM inference (users provide API keys)
- [ ] Autonomous agentic coding (covered in PRD 006)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| code-server compatibility | Must | Works in containerized VS Code |
| Inline completions | Must | Core autocomplete functionality |
| Chat interface | Must | Interactive code assistance |
| Multi-provider support | High | OpenAI, Anthropic, local models |
| Open VSX availability | High | Installable in code-server |
| MCP support | High | Extensibility via Model Context Protocol |
| License | High | Open source or reasonable commercial terms |
| Token efficiency | Medium | Cost-effective API usage |
| Active maintenance | Medium | Regular updates, bug fixes |
| Privacy options | Medium | Local model support, data handling |

## Tool Candidates

| Tool | License | Pros | Cons | code-server | Spike Result |
|------|---------|------|------|-------------|--------------|
| Continue | Apache 2.0 | Open source, multi-provider, MCP support, excellent docs, active development | Newer than Copilot, some features still maturing | Available | ✅ **Primary** |
| Cline | Apache 2.0 | Open source, agentic features, human-in-the-loop, MCP support, 4M+ users | More agentic than pure completion, can be verbose | Available | ✅ Secondary |
| Roo-Code | Apache 2.0 | Open source, reliable multi-file edits, role-based agents | VS Code focused, less pure-completion focus | Available | ⚡ Alternative |
| GitHub Copilot | Proprietary | Industry standard, excellent completions, large training data, GitHub integration | Subscription required, not on Open VSX, may need workarounds | Workaround needed | ❌ Not recommended |
| Codeium | Freemium | Free tier, fast completions, good accuracy | Proprietary, limited customization | Available | ⚡ Budget option |

## Detailed Tool Analysis

### Continue

**Source**: [GitHub - continuedev/continue](https://github.com/continuedev/continue) | [Docs](https://docs.continue.dev)

Continue is the leading open-source AI code assistant:

- **Multi-provider**: OpenAI, Anthropic, Ollama, LM Studio, Azure, and more
- **Features**: Inline completions, chat, code actions, custom commands
- **MCP support**: Extensible via Model Context Protocol
- **Open VSX**: Available for code-server installation
- **Configuration**: JSON-based config, supports multiple models per task

Container compatibility: Excellent—designed for flexibility, works in code-server.

### Cline

**Source**: [GitHub - cline/cline](https://github.com/cline/cline) | [Open VSX](https://open-vsx.org/extension/saoudrizwan/claude-dev)

Cline provides autonomous coding with human-in-the-loop safety:

- **Agentic**: Can create/edit files, run commands, browse web
- **Human-in-the-loop**: Approval required for actions (configurable)
- **Multi-provider**: OpenRouter, Anthropic, OpenAI, local models
- **MCP support**: Extends capabilities via MCP servers
- **Plan/Act modes**: Structured approach to complex tasks

Container compatibility: Available on Open VSX, works in code-server.

### Roo-Code

**Source**: [GitHub - RooCodeInc/Roo-Code](https://github.com/RooCodeInc/Roo-Code)

Roo-Code focuses on reliability for complex multi-file operations:

- **Multi-agent**: Role-driven execution (architect, coder, reviewer)
- **Approval modes**: Manual, auto-approve, or hybrid
- **Reliability**: Known for completing complex refactors without partial failures
- **Model flexibility**: OpenAI, Anthropic, local LLMs

Container compatibility: VS Code extension, should work in code-server.

### GitHub Copilot

**Source**: [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)

GitHub Copilot is the industry-standard AI coding assistant:

- **Completions**: Excellent inline suggestions, trained on vast codebase
- **Chat**: Copilot Chat for interactive assistance
- **GitHub integration**: Deep integration with GitHub workflows
- **MCP support**: Recent additions for extensibility

Container compatibility: Not on Open VSX; may require manual VSIX installation or alternative approach.

### Codeium

**Source**: [Codeium](https://codeium.com/)

Codeium offers free AI code completion:

- **Free tier**: Generous free usage for individuals
- **Speed**: Fast completions with low latency
- **Languages**: Wide language support
- **IDE support**: Multiple IDE plugins

Container compatibility: Check Open VSX availability.

## Selected Approach

Based on spike results from `spikes/009-ai-ide-extensions/`, the recommended approach is:

### Primary: Continue

**Installation**: `code-server --install-extension Continue.continue`

**Rationale**:
- Full Open VSX availability - native code-server support
- Multi-provider support: Anthropic, OpenAI, Ollama, Azure, and more
- Comprehensive MCP support for extensibility
- Excellent documentation and active development
- Flexible `config.yaml` with secrets syntax `${{ secrets.API_KEY }}`
- Tab autocomplete + chat + inline edit capabilities

**Configuration**: See `spikes/009-ai-ide-extensions/continue/config.yaml`

### Secondary: Cline (for complex agentic tasks)

**Installation**: `code-server --install-extension saoudrizwan.claude-dev`

**Rationale**:
- Excellent for multi-step, complex tasks
- Human-in-the-loop approval system for safety
- MCP integration for extended capabilities
- Plan/Act modes for structured problem-solving

**Configuration**: See `spikes/009-ai-ide-extensions/cline/`

### Not Recommended: GitHub Copilot

- Not available on Open VSX
- Complex OAuth authentication in containers
- Requires manual VSIX installation and workarounds

### Detailed findings available in:
- `spikes/009-ai-ide-extensions/FINDINGS.md` - Full comparison and recommendations
- `spikes/009-ai-ide-extensions/docker-compose.yml` - Test environment

## Acceptance Criteria

- [ ] Given code-server running, when I install the extension, then it activates without errors
- [ ] Given typing code, when completions are suggested, then they are contextually relevant
- [ ] Given the chat interface, when I ask code questions, then I receive helpful responses
- [ ] Given multiple files open, when I request refactoring, then changes are consistent
- [ ] Given API keys in environment, when extension loads, then it authenticates automatically
- [ ] Given Python/TypeScript/Rust files, when editing, then language-specific completions work
- [ ] Given MCP servers configured, when extension runs, then MCP tools are accessible
- [ ] Given usage, when I check metrics, then token/cost information is visible

## Dependencies

- Requires: 008-prd-containerized-ide, 003-prd-secret-injection (for API keys)
- Blocks: none (end-user feature)

## Spike Tasks

### Installation & Compatibility

- [ ] Install Continue in code-server, verify activation
- [ ] Install Cline in code-server, verify activation
- [ ] Install Roo-Code in code-server, verify activation
- [ ] Test GitHub Copilot installation options (VSIX, alternative methods)
- [ ] Test Codeium availability and installation
- [ ] Document installation steps for each extension

### Feature Validation

- [ ] Test inline completions in Python, TypeScript, Rust, Go
- [ ] Test chat interface for code explanation
- [ ] Test code generation from natural language
- [ ] Test multi-file context awareness
- [ ] Test MCP integration (where supported)

### Provider Configuration

- [ ] Configure and test with OpenAI API
- [ ] Configure and test with Anthropic API
- [ ] Configure and test with local models (Ollama)
- [ ] Test API key configuration via environment variables
- [ ] Measure token usage for equivalent tasks

### Performance & UX

- [ ] Measure completion latency
- [ ] Evaluate completion quality across languages
- [ ] Test with large codebases (context handling)
- [ ] Document any code-server specific issues or workarounds

## References

- [Continue Documentation](https://docs.continue.dev)
- [Cline on Open VSX](https://open-vsx.org/extension/saoudrizwan/claude-dev)
- [Roo Code vs Cline Comparison](https://www.qodo.ai/blog/roo-code-vs-cline/)
- [GitHub Copilot CLI Updates (2026)](https://github.blog/changelog/2026-01-14-github-copilot-cli-enhanced-agents-context-management-and-new-ways-to-install/)
