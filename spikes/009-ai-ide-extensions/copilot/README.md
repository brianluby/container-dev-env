# GitHub Copilot in code-server

GitHub Copilot is **NOT available on Open VSX** and requires manual installation.

## Installation Options

### Option 1: Manual VSIX Download (Recommended)

1. Download the VSIX from VS Code Marketplace:
   - Visit: https://marketplace.visualstudio.com/items?itemName=GitHub.copilot
   - Click "Download Extension" (requires VS Code account)
   - Download both `GitHub.copilot` and `GitHub.copilot-chat`

2. Install in code-server:
   ```bash
   code-server --install-extension /path/to/github.copilot.vsix
   code-server --install-extension /path/to/github.copilot-chat.vsix
   ```

3. Authenticate:
   - Open code-server
   - Run "GitHub Copilot: Sign In" from Command Palette
   - Complete OAuth flow in browser

### Option 2: Use Copilot via OpenRouter + Continue

If you have Copilot access through GitHub, you can use other extensions with Anthropic/OpenAI keys instead.

## Known Issues with code-server

| Issue | Workaround |
|-------|------------|
| OAuth redirect fails | Use device code flow: `GitHub Copilot: Sign In with Device Code` |
| Extension crashes on load | Ensure code-server version is 4.x+ |
| No inline suggestions | Check that Copilot is enabled in settings |
| Chat doesn't work | Copilot Chat may need separate authentication |

## VS Code Settings

```json
{
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": true
  },
  "github.copilot.chat.localeOverride": "en"
}
```

## Recommendation

**For containerized environments, use Continue or Cline instead.**

Reasons:
- Open VSX availability (no VSIX workaround needed)
- Multi-provider support (not locked to GitHub)
- Better MCP integration
- No authentication complexity in containers
