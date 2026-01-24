# Quickstart: MCP Integration

**Feature**: 012-mcp-integration
**Date**: 2026-01-23

## Prerequisites

- Docker 24+ with buildx
- A project workspace directory
- (Optional) API keys for Context7, GitHub

## 1. Build the Container

```bash
docker build -t container-dev-env:mcp -f docker/Dockerfile .
```

For Playwright browser support (adds ~150MB):
```bash
docker build -t container-dev-env:mcp \
  --build-arg INSTALL_PLAYWRIGHT_BROWSER=true \
  -f docker/Dockerfile .
```

## 2. Create MCP Source Configuration

In your project workspace, create `.mcp/config.json`:

```bash
mkdir -p .mcp
cat > .mcp/config.json << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      },
      "enabled": true
    },
    "memory": {
      "command": "mcp-server-memory",
      "env": {
        "MEMORY_FILE_PATH": "/home/dev/.local/share/mcp-memory/memory.json"
      },
      "enabled": true
    }
  }
}
EOF
```

## 3. Run the Container

```bash
docker run -it \
  -v "$(pwd):/workspace:cached" \
  -v mcp-memory:/home/dev/.local/share/mcp-memory \
  -e CONTEXT7_API_KEY="${CONTEXT7_API_KEY}" \
  container-dev-env:mcp
```

The entrypoint automatically:
1. Validates MCP server availability
2. Generates tool-native configs from `.mcp/config.json`

## 4. Verify MCP Servers

Inside the container:

```bash
# Check validation output
validate-mcp.sh

# View generated Claude Code config
cat /workspace/.claude/settings.local.json

# View generated Cline config
cat ~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json

# View generated Continue config (mcpServers section)
grep -A 20 'mcpServers:' ~/.continue/config.yaml
```

## 5. Use with AI Tools

### Claude Code
```bash
claude  # MCP servers automatically available
```

### Cline / Continue
Open VS Code with the devcontainer — MCP servers are pre-configured.

## Common Tasks

### Enable an Optional Server

Edit `.mcp/config.json` and set `"enabled": true`:

```json
{
  "github": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
    },
    "enabled": true
  }
}
```

Then regenerate configs:
```bash
generate-configs.sh
```

### Add a Custom MCP Server

Add a new entry to `.mcp/config.json`:

```json
{
  "my-custom-server": {
    "command": "npx",
    "args": ["-y", "@my-org/my-mcp-server"],
    "env": {
      "MY_API_KEY": "${MY_API_KEY}"
    },
    "enabled": true,
    "description": "My custom MCP server"
  }
}
```

Run `generate-configs.sh` to update all tool configs.

### Check Server Health

```bash
validate-mcp.sh --json | jq '.servers'
```

### Regenerate Configs After Env Change

```bash
# After updating environment variables
generate-configs.sh
# Restart your AI tool to pick up changes
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "command not found" for MCP server | Verify package installed: `npm list -g @modelcontextprotocol/server-filesystem` |
| Context7 returns errors | Check `CONTEXT7_API_KEY` is set: `echo $CONTEXT7_API_KEY` |
| Memory not persisting | Verify volume mount: `docker volume ls | grep mcp-memory` |
| Config generation fails | Validate JSON: `jq . /workspace/.mcp/config.json` |
| Server works in Claude but not Cline | Run `generate-configs.sh` to sync all tool configs |
