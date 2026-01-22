# Cline Configuration

Cline is configured via VS Code settings and MCP server settings.

## VS Code Settings

Add these to your VS Code `settings.json`:

```json
{
  "cline.apiProvider": "anthropic",
  "cline.anthropicApiKey": "${env:ANTHROPIC_API_KEY}",
  "cline.apiModelId": "claude-sonnet-4-20250514",

  "cline.autoApprovalSettings": {
    "enabled": false,
    "maxRequests": 10,
    "enableNotifications": true
  },

  "cline.customInstructions": "Follow conventional commits. Use explicit types. Prefer composition over inheritance."
}
```

## Alternative Providers

### OpenRouter (aggregated access to multiple models)
```json
{
  "cline.apiProvider": "openrouter",
  "cline.openRouterApiKey": "${env:OPENROUTER_API_KEY}",
  "cline.openRouterModelId": "anthropic/claude-sonnet-4"
}
```

### OpenAI
```json
{
  "cline.apiProvider": "openai",
  "cline.openAiApiKey": "${env:OPENAI_API_KEY}",
  "cline.openAiModelId": "gpt-4o"
}
```

## MCP Servers

The `cline_mcp_settings.json` file configures Model Context Protocol servers:

- **filesystem**: Provides file system access tools
- **memory**: Optional persistent memory (disabled by default)

See [MCP documentation](https://modelcontextprotocol.io/) for available servers.

## Usage Tips

1. **Plan Mode**: Use `/plan` to have Cline analyze before acting
2. **Approval**: Keep auto-approval off for safety in containerized environments
3. **Context**: Add relevant files to context before asking complex questions
4. **Custom Instructions**: Set project-specific guidelines in settings
