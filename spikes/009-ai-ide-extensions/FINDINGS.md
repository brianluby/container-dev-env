# Spike 009: AI IDE Extensions - Findings

## Executive Summary

**Recommendation**: Use **Continue** as the primary AI assistant, with **Cline** as a secondary option for complex agentic tasks.

| Extension | Recommendation | Rationale |
|-----------|---------------|-----------|
| **Continue** | ✅ Primary | Best overall: Open VSX, multi-provider, MCP, excellent docs |
| **Cline** | ✅ Secondary | Excellent for agentic tasks, human-in-the-loop safety |
| **Roo-Code** | ⚡ Alternative | Good for multi-file refactors, role-based agents |
| **GitHub Copilot** | ⚠️ Not recommended | Not on Open VSX, auth complexity in containers |
| **Codeium** | ⚡ Budget option | Free tier, but no MCP, limited customization |

## Detailed Evaluation

### Continue (Primary Recommendation)

**Open VSX**: `Continue.continue` ✅

**Strengths**:
- Full Open VSX availability - native code-server support
- Multi-provider: Anthropic, OpenAI, Ollama, Azure, and more
- Comprehensive MCP support for extensibility
- Excellent documentation and active development
- Flexible config.yaml with secrets syntax
- Tab autocomplete + chat + inline edit
- Custom prompts and rules system

**Configuration**: See `continue/config.yaml`

**Installation**:
```bash
code-server --install-extension Continue.continue
```

**API Key Setup**: Uses `${{ secrets.ANTHROPIC_API_KEY }}` syntax in config.yaml

### Cline (Secondary Recommendation)

**Open VSX**: `saoudrizwan.claude-dev` ✅

**Strengths**:
- Excellent for complex, multi-step tasks
- Human-in-the-loop approval system
- MCP integration for extended capabilities
- Plan/Act modes for structured problem-solving
- 57k+ GitHub stars, active community
- Works well with Claude models

**Best For**: Agentic coding tasks, complex refactors, multi-file changes

**Configuration**: See `cline/README.md` and `cline/cline_mcp_settings.json`

**Installation**:
```bash
code-server --install-extension saoudrizwan.claude-dev
```

### Roo-Code (Alternative)

**Open VSX**: `RooVeterinaryInc.roo-cline` ✅

**Strengths**:
- Role-based agents (architect, coder, reviewer)
- Reliable multi-file editing
- Good for large refactors
- Apache 2.0 license

**Best For**: Complex multi-file refactors, team workflows with defined roles

**Configuration**: See `roo-code/README.md`

### GitHub Copilot (Not Recommended for Containers)

**Open VSX**: ❌ Not available

**Issues**:
- Requires manual VSIX download and installation
- OAuth authentication complex in containers
- Device code flow may be needed
- Chat functionality may require separate auth

**Workaround**: See `copilot/README.md` for manual installation steps

**Recommendation**: Use Continue or Cline instead for containerized environments

### Codeium (Budget Option)

**Open VSX**: `Codeium.codeium` ✅

**Strengths**:
- Generous free tier
- Fast completions
- Easy setup

**Weaknesses**:
- No MCP support
- No custom model selection
- Proprietary service
- Recent rebranding causing confusion

**Best For**: Quick setup, cost-sensitive scenarios

## Feature Comparison Matrix

| Feature | Continue | Cline | Roo-Code | Copilot | Codeium |
|---------|----------|-------|----------|---------|---------|
| Open VSX | ✅ | ✅ | ✅ | ❌ | ✅ |
| code-server | ✅ | ✅ | ✅ | ⚠️ Manual | ✅ |
| MCP Support | ✅ | ✅ | ✅ | ⚠️ Limited | ❌ |
| Multi-provider | ✅ | ✅ | ✅ | ❌ | ❌ |
| Inline Completions | ✅ | ✅ | ✅ | ✅ | ✅ |
| Chat Interface | ✅ | ✅ | ✅ | ✅ | ✅ |
| Custom Prompts | ✅ | ✅ | ✅ | ⚠️ | ❌ |
| Env Var API Keys | ✅ | ✅ | ✅ | N/A | ⚠️ |
| License | Apache 2.0 | Apache 2.0 | Apache 2.0 | Proprietary | Freemium |

## Installation Commands

### Recommended Setup (Continue + Cline)

```bash
# Primary: Continue
code-server --install-extension Continue.continue

# Secondary: Cline (for agentic tasks)
code-server --install-extension saoudrizwan.claude-dev
```

### Full Suite (All Open VSX Extensions)

```bash
code-server --install-extension Continue.continue
code-server --install-extension saoudrizwan.claude-dev
code-server --install-extension RooVeterinaryInc.roo-cline
code-server --install-extension Codeium.codeium
```

## Configuration Best Practices

### API Key Management

1. **Environment Variables**: Set keys in container environment
   ```yaml
   environment:
     - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
     - OPENAI_API_KEY=${OPENAI_API_KEY}
   ```

2. **Continue Secrets Syntax**: Reference in config.yaml
   ```yaml
   apiKey: ${{ secrets.ANTHROPIC_API_KEY }}
   ```

3. **VS Code Settings**: For Cline/Roo-Code
   ```json
   "cline.anthropicApiKey": "${env:ANTHROPIC_API_KEY}"
   ```

### Recommended Model Configuration

| Task | Model | Provider |
|------|-------|----------|
| Chat & Edit | Claude Sonnet 4 | Anthropic |
| Autocomplete | Claude 3.5 Haiku | Anthropic |
| Complex Agentic | Claude Sonnet 4 | Anthropic |
| Cost-sensitive | GPT-4o-mini | OpenAI |
| Local/Private | CodeLlama 13B | Ollama |

## Testing Procedure

1. **Start Environment**:
   ```bash
   cd spikes/009-ai-ide-extensions
   cp .env.example .env
   # Add your API keys to .env
   docker compose up -d
   ```

2. **Access**: Open http://localhost:8443 (password: from .env)

3. **Test Extensions**:
   - Open files in `workspace/sample-code/`
   - Test inline completions by typing
   - Test chat by selecting code and asking questions
   - Test MCP by enabling filesystem server

4. **Validation Checklist**:
   - [ ] Extension activates without errors
   - [ ] Inline completions work in Python
   - [ ] Inline completions work in TypeScript
   - [ ] Inline completions work in Rust
   - [ ] Inline completions work in Go
   - [ ] Chat interface responds
   - [ ] API key authentication works
   - [ ] MCP servers connect (if configured)

## Known Issues & Workarounds

### Issue: Continue config not loading

**Symptom**: Default config used instead of custom
**Solution**: Ensure `~/.continue/config.yaml` exists and is valid YAML

### Issue: Cline MCP servers fail to start

**Symptom**: MCP tools unavailable
**Solution**: Ensure Node.js is installed, check `npx` is in PATH

### Issue: Slow completions in container

**Symptom**: High latency for inline suggestions
**Solution**: Use faster models (Haiku, GPT-4o-mini) for autocomplete

### Issue: Extensions conflict with each other

**Symptom**: Multiple completion popups, slowdown
**Solution**: Disable autocomplete in all but one extension

## Cost Considerations

| Provider | Model | Input (1M tokens) | Output (1M tokens) |
|----------|-------|------------------|-------------------|
| Anthropic | Claude Sonnet 4 | $3.00 | $15.00 |
| Anthropic | Claude 3.5 Haiku | $0.80 | $4.00 |
| OpenAI | GPT-4o | $2.50 | $10.00 |
| OpenAI | GPT-4o-mini | $0.15 | $0.60 |
| OpenRouter | Various | Varies | Varies |

**Recommendation**: Use Haiku/GPT-4o-mini for autocomplete, Sonnet/GPT-4o for chat and complex tasks.

## Integration with container-dev-env

### Dockerfile Addition

```dockerfile
# Install AI extensions (from 009-ai-ide-extensions spike)
RUN code-server --install-extension Continue.continue \
    && code-server --install-extension saoudrizwan.claude-dev
```

### Secret Injection (from PRD 003)

```yaml
# Use age-encrypted secrets for API keys
environment:
  - ANTHROPIC_API_KEY={{ .anthropic_api_key }}
```

### Volume Mounts

```yaml
volumes:
  # Continue config
  - ./ai-config/continue:/home/coder/.continue:ro
  # Cline MCP settings
  - ./ai-config/cline:/home/coder/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings:ro
```

## Conclusion

For the container-dev-env project:

1. **Install Continue** as the primary AI assistant
   - Best Open VSX support
   - Flexible multi-provider configuration
   - Full MCP support
   - Excellent for daily coding tasks

2. **Install Cline** as secondary for complex agentic tasks
   - Human-in-the-loop safety
   - Great for multi-file refactors
   - Plan/Act modes for structured problem-solving

3. **Skip Copilot** due to Open VSX limitations and auth complexity

4. **Consider Codeium** only for free-tier/budget scenarios

This approach provides maximum flexibility while maintaining ease of setup and use in containerized environments.
