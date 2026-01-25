# MCP Integration

MCP (Model Context Protocol) provides a single source configuration that is translated into tool-native configs for supported AI tools.

Applies to: `main`

## Prerequisites

- [Getting Started](../getting-started/index.md)
- If you enable servers that require credentials, set them up first: [Secrets Management](secrets-management.md)

## How it works

1. You define MCP servers in `/workspace/.mcp/config.json`
2. The container scripts validate availability and generate per-tool configs
3. You restart your AI tool so it picks up the generated config

## Setup

1. Create the MCP config file in your workspace:

```bash
mkdir -p .mcp
cat > .mcp/config.json <<'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/workspace"],
      "enabled": true,
      "description": "Expose the workspace filesystem"
    }
  }
}
EOF
```

2. Validate and generate configs (inside the container):

```bash
validate-mcp.sh
generate-configs.sh
```

## Configuration

Environment variables should be referenced, not inlined:

```json
{
  "mcpServers": {
    "example": {
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "env": {
        "EXAMPLE_API_KEY": "${EXAMPLE_API_KEY}"
      },
      "enabled": false,
      "description": "Example server (disabled by default)"
    }
  }
}
```

## Verification

Inside the container:

```bash
validate-mcp.sh --json | jq '.servers'
```

Then open your AI tool and confirm MCP tools appear/are usable.

## Troubleshooting

- Config generation fails: validate JSON: `jq . /workspace/.mcp/config.json`
- "binary not found": install the referenced command in the image or use an `npx` server
- "VARIABLE not set": ensure the referenced env var exists in the container environment

## Related

- [Configuration Reference](../reference/configuration.md)
- `src/mcp/defaults/README.md`

## Next steps

- Add persistent memory: [Persistent Memory](persistent-memory.md)
