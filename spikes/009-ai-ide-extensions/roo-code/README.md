# Roo-Code Configuration

Roo-Code provides multi-agent AI assistance with role-based execution.

## VS Code Settings

Add these to your VS Code `settings.json`:

```json
{
  "roo-cline.apiProvider": "anthropic",
  "roo-cline.anthropicApiKey": "${env:ANTHROPIC_API_KEY}",
  "roo-cline.apiModelId": "claude-sonnet-4-20250514",

  "roo-cline.customModes": {
    "architect": {
      "model": "claude-sonnet-4-20250514",
      "systemPrompt": "You are a software architect. Focus on design decisions, patterns, and high-level structure."
    },
    "coder": {
      "model": "claude-sonnet-4-20250514",
      "systemPrompt": "You are a skilled programmer. Write clean, efficient, well-tested code."
    },
    "reviewer": {
      "model": "claude-sonnet-4-20250514",
      "systemPrompt": "You are a code reviewer. Focus on bugs, security issues, and code quality."
    }
  },

  "roo-cline.autoApprovalSettings": {
    "enabled": false
  }
}
```

## Alternative Providers

### OpenRouter
```json
{
  "roo-cline.apiProvider": "openrouter",
  "roo-cline.openRouterApiKey": "${env:OPENROUTER_API_KEY}",
  "roo-cline.openRouterModelId": "anthropic/claude-sonnet-4"
}
```

## Agent Roles

Roo-Code excels at multi-agent workflows:

| Role | Purpose | Use When |
|------|---------|----------|
| **Architect** | Design & planning | Starting new features, making structural decisions |
| **Coder** | Implementation | Writing code, fixing bugs, refactoring |
| **Reviewer** | Quality assurance | Code review, finding issues, security checks |

## MCP Integration

Roo-Code supports MCP servers similar to Cline. Create `.roo-code/mcp_settings.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/coder/project"]
    }
  }
}
```

## Usage Tips

1. **Role Selection**: Choose the right agent for the task
2. **Context Loading**: Roo-Code handles large codebases well
3. **Multi-file Edits**: Reliable for complex refactoring
4. **Diff Review**: Always review proposed changes before applying
