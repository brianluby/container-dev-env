# Spike 011: MCP Integration Results

**Date**: 2026-01-21
**Status**: Complete

## Executive Summary

MCP (Model Context Protocol) servers can be successfully installed and configured within Docker
containers using Node.js and npm. The containerized approach provides isolation while maintaining
full compatibility with AI coding tools like Claude Code, Cline, and Continue.

**Key Finding**: MCP servers are npm packages that communicate via stdio. Installation via
`npm install -g` or invocation via `npx` works identically inside containers as on the host.

## Test Environment

| Component | Version |
|-----------|---------|
| Node.js | 25.4.0 (host), 22.x LTS (container) |
| npm | Bundled with Node.js |
| @modelcontextprotocol/server-filesystem | 2026.1.14 |
| @upstash/context7-mcp | 2.1.0 |
| Docker | 29.1.3 |
| Platform | macOS Darwin 24.6.0 |

## MCP Server Compatibility Matrix

| Server | npm Package | Container Compatible | API Key Required | Priority |
|--------|-------------|---------------------|------------------|----------|
| Filesystem | @modelcontextprotocol/server-filesystem | **Yes** | No | Must |
| Context7 | @upstash/context7-mcp | **Yes** | Optional (rate limits) | Must |
| Memory | @modelcontextprotocol/server-memory | **Yes** | No | Should |
| Sequential Thinking | @modelcontextprotocol/server-sequential-thinking | **Yes** | No | Should |
| GitHub | @modelcontextprotocol/server-github | **Yes** | Yes (PAT) | Should |
| Playwright | @playwright/mcp | **Yes** (needs Chromium) | No | Could |

## Installation Methods

### Method 1: Global npm Install (Recommended for Containers)

```dockerfile
# In Dockerfile
RUN npm install -g \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-memory \
    @upstash/context7-mcp
```

**Pros**: Faster startup, no network dependency at runtime
**Cons**: Requires image rebuild for updates

### Method 2: npx Invocation (Recommended for Development)

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

**Pros**: Always latest version, no pre-installation needed
**Cons**: Slower first invocation, requires network

### Method 3: Claude Code CLI

```bash
# Add server to user scope (persists across projects)
claude mcp add filesystem --scope user -- npx -y @modelcontextprotocol/server-filesystem /workspace

# Add to project scope (shared via .mcp.json)
claude mcp add context7 --scope project -- npx -y @upstash/context7-mcp
```

## Configuration Architecture

### Recommended Directory Structure

```
container/
├── /workspace/              # Project files (volume mount)
├── /home/dev/
│   ├── .mcp/
│   │   └── config.json     # MCP server configuration
│   ├── .claude/
│   │   └── settings.local.json  # Claude Code settings
│   └── .npm-global/        # Global npm packages
```

### Configuration File Locations

| Tool | Location | Scope |
|------|----------|-------|
| Claude Code | ~/.claude/settings.local.json | User |
| Claude Code | .claude/settings.local.json | Project |
| Claude Code | .mcp.json | Project (shared) |
| Claude Desktop | ~/Library/Application Support/Claude/claude_desktop_config.json | User |

### Sample MCP Configuration

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"],
      "type": "stdio"
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      },
      "type": "stdio"
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "type": "stdio"
    }
  }
}
```

## Security Considerations

### Filesystem Server Security

The filesystem MCP server supports directory allowlisting:

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace", "/home/dev"]
  }
}
```

**Security boundaries**:
- Only specified directories are accessible
- Path traversal is prevented by the server
- Container isolation adds second layer of protection

### Credential Management

| Server | Credential | Environment Variable | Required |
|--------|-----------|---------------------|----------|
| Context7 | API Key | CONTEXT7_API_KEY | Optional |
| GitHub | PAT | GITHUB_PERSONAL_ACCESS_TOKEN | Yes |

**Best practice**: Pass credentials via environment variables at runtime, never bake into images.

```bash
docker run -e CONTEXT7_API_KEY="${CONTEXT7_API_KEY}" mcp-container
```

## Claude Code Integration Verification

Current host MCP configuration verified working:

```
filesystem: npx -y @modelcontextprotocol/server-filesystem /Users/bluby - ✓ Connected
sequential-thinking: npx -y @modelcontextprotocol/server-sequential-thinking - ✓ Connected
memory: npx -y @modelcontextprotocol/server-memory - ✓ Connected
context7: npx -y @upstash/context7-mcp@latest - ✓ Connected
playwright: npx -y @playwright/mcp@latest - ✓ Connected
MCP_DOCKER: docker mcp gateway run - ✓ Connected
```

## Dockerfile Implementation

A complete Dockerfile for MCP-enabled containers is provided at:
`spikes/011-mcp-integration/Dockerfile`

Key implementation details:

1. **Base image**: Debian Bookworm-slim (matches existing project pattern)
2. **Node.js**: 22.x LTS via NodeSource
3. **npm global prefix**: Set to user-writable directory
4. **MCP servers**: Pre-installed for faster startup
5. **Health check**: Script verifies MCP server availability

## PRD Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| MCP server runtime within container | **PASS** | Node.js + npm works |
| Configuration via env vars or config files | **PASS** | Both supported |
| Support for essential MCP servers | **PASS** | Filesystem, Context7 verified |
| Works with Claude Code | **PASS** | Verified on host |
| Works with Cline | **Expected PASS** | Same config format |
| Works with Continue | **Expected PASS** | Same config format |
| Secure handling of credentials | **PASS** | Environment variables |
| Documentation for custom MCP servers | **PASS** | Included in results |

## Recommendations

### For Container Integration

1. **Pre-install core MCP servers** in the Dockerfile for faster startup
2. **Use npx for optional servers** that may not always be needed
3. **Mount workspace as volume** for filesystem MCP access
4. **Pass credentials at runtime** via environment variables

### For PRD Implementation

1. Add MCP server installation to the base Dockerfile (001-container-base)
2. Create a `.mcp.json` template in the container for easy customization
3. Document MCP server usage in project README
4. Consider adding a `docker mcp` integration for remote MCP server access

### MCP Server Priority for Implementation

1. **Filesystem** - Essential for file operations (Must)
2. **Context7** - Up-to-date documentation (Must)
3. **Memory** - Persistent context across sessions (Should)
4. **Sequential Thinking** - Already integrated (Should)
5. **GitHub** - Platform integration (Should, needs token)
6. **Playwright** - Web automation (Could, adds image size)

## Artifacts

| File | Purpose |
|------|---------|
| `Dockerfile` | Container image with MCP servers |
| `docker-compose.yml` | Easy testing setup |
| `config/mcp-config.json` | Sample MCP configuration |
| `config/claude-code-mcp.json` | Claude Code specific config |
| `scripts/health-check-mcp.sh` | Health check for containers |
| `scripts/test-mcp-servers.sh` | Functional tests for container |
| `scripts/test-mcp-local.sh` | Local host tests |

## References

- [MCP Filesystem Server npm](https://www.npmjs.com/package/@modelcontextprotocol/server-filesystem)
- [Context7 MCP Server](https://github.com/upstash/context7)
- [Claude Code MCP Docs](https://code.claude.com/docs/en/mcp)
- [MCP Specification](https://modelcontextprotocol.io/specification/2025-11-25)
- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)

## Conclusion

MCP integration in containers is straightforward and fully compatible with the containerized
development environment design. The recommended approach is:

1. Pre-install essential MCP servers (filesystem, context7, memory) in the Dockerfile
2. Use environment variables for credentials
3. Provide a sample `.mcp.json` configuration for users to customize
4. Document usage patterns for Claude Code and other AI tools

**No blockers identified** for proceeding with full implementation.
