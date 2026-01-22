# Codeium Configuration

Codeium (now "Windsurf Plugin") offers free AI code completion.

## Open VSX Availability

✅ **Available**: `Codeium.codeium`

```bash
code-server --install-extension Codeium.codeium
```

## Authentication

1. Open code-server
2. Run Command Palette: "Codeium: Provide Authentication Token"
3. Create account at https://codeium.com/ if needed
4. Copy token from Codeium dashboard

## VS Code Settings

```json
{
  "codeium.enableConfig": {
    "*": true
  },
  "codeium.enableSearch": true,
  "codeium.enableCodeLens": true
}
```

## Features

| Feature | Availability |
|---------|-------------|
| Inline completions | ✅ Yes |
| Chat interface | ✅ Yes (Windsurf) |
| Multi-language | ✅ Yes |
| Free tier | ✅ Generous |
| MCP support | ❌ No |
| Custom models | ❌ No |

## Pros & Cons

**Pros:**
- Free tier with generous limits
- Fast completion latency
- Wide language support
- Easy setup

**Cons:**
- Proprietary (no self-hosting)
- No MCP support
- Limited customization
- Locked to Codeium's models
- Recent rebranding to "Windsurf" causing confusion

## Container Considerations

- Authentication requires browser for initial setup
- Token can be set via environment variable after initial auth
- Works in code-server after authentication

## Recommendation

**Use for:** Quick setup, cost-sensitive scenarios, when API keys aren't available.

**Prefer Continue/Cline when:** You need MCP support, multi-provider flexibility, or advanced customization.
