# 011-prd-mcp-integration

## Problem Statement

AI coding agents need access to external tools, data sources, and services to be effective.
The Model Context Protocol (MCP) provides a standardized way to connect AI models to these
resources. The containerized development environment should support MCP servers that extend
agent capabilities—providing access to documentation, databases, APIs, file systems, and
specialized tools.

**Critical constraint**: MCP servers must run within the container environment or be accessible
from within containers. Configuration should work with environment variables and not require
host-side setup.

## Requirements

### Must Have (M)

- [ ] MCP server runtime within container
- [ ] Configuration via environment variables or config files
- [ ] Support for essential MCP servers (filesystem, documentation)
- [ ] Works with Claude Code, Cline, Continue, and other MCP-compatible tools
- [ ] Secure handling of credentials for external services
- [ ] Documentation for adding custom MCP servers

### Should Have (S)

- [ ] Pre-configured common MCP servers (Context7, filesystem, Git)
- [ ] MCP server for project-specific tools (test runners, linters)
- [ ] Browser/web access MCP server (Playwright, Puppeteer)
- [ ] Database access MCP servers
- [ ] Easy enable/disable of individual servers
- [ ] Health checks for MCP server availability

### Could Have (C)

- [ ] Custom MCP server development framework
- [ ] MCP server marketplace/registry integration
- [ ] Containerized MCP servers (isolated from main container)
- [ ] MCP server monitoring and logging
- [ ] Rate limiting for expensive operations
- [ ] Caching layer for repeated queries

### Won't Have (W)

- [ ] MCP servers requiring GUI
- [ ] MCP servers with hard dependencies on specific cloud providers
- [ ] Self-hosted LLM inference via MCP (users provide API keys)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Container compatibility | Must | Runs in Docker without host dependencies |
| Tool compatibility | Must | Works with Claude Code, Cline, Continue |
| Security | Must | Safe credential handling, sandboxed execution |
| Documentation quality | High | Clear setup and usage instructions |
| Maintenance status | High | Active development, recent updates |
| Usefulness | High | Provides real value for development workflows |
| Performance | Medium | Reasonable latency, doesn't slow down agents |
| License | Medium | Open source preferred |

## MCP Server Candidates

| Server | Category | Pros | Cons | Priority | Spike Result |
|--------|----------|------|------|----------|--------------|
| Filesystem | Core | Essential file operations, official | Basic functionality | Must | Pending |
| Context7 | Documentation | Up-to-date library docs, widely used | External dependency | Must | Pending |
| Git | Version Control | Git operations, history, diffs | Overlap with native Git | Should | Pending |
| Playwright | Browser | Web automation, testing, scraping | Heavier dependency | Should | Pending |
| PostgreSQL/SQLite | Database | Query execution, schema inspection | Security considerations | Should | Pending |
| Sentry | Observability | Error tracking, debugging context | Requires Sentry account | Could | Pending |
| GitHub | Platform | Issues, PRs, repo management | Requires GitHub token | Should | Pending |
| Memory (Knowledge Graph) | Memory | Persistent context, relationships | Complexity, storage | Could | Pending |

## Detailed Server Analysis

### Filesystem MCP Server

**Source**: [Official MCP Servers](https://github.com/modelcontextprotocol/servers)

Core functionality for file operations:

- **Capabilities**: Read, write, list, search files
- **Security**: Configurable allowed directories
- **Use case**: Essential for any coding agent

Container compatibility: Excellent—operates on container filesystem.

### Context7

**Source**: [Context7](https://context7.com/) | [MCP Server](https://glama.ai/mcp/servers/context7)

Up-to-date documentation for libraries:

- **Capabilities**: Query documentation for any library, get code examples
- **Coverage**: Wide range of popular libraries and frameworks
- **Use case**: Ensures AI has current documentation, not outdated training data

Container compatibility: API-based, works from container with internet access.

### Playwright MCP Server

**Source**: [Playwright MCP](https://github.com/anthropics/anthropic-cookbook)

Browser automation for testing and web access:

- **Capabilities**: Navigate, click, fill forms, screenshot, scrape
- **Use case**: Testing, web research, UI verification

Container compatibility: Requires headless browser in container (Chromium).

### GitHub MCP Server

**Source**: [Official MCP Servers](https://github.com/modelcontextprotocol/servers)

GitHub platform integration:

- **Capabilities**: Issues, PRs, repo info, actions
- **Authentication**: GitHub token required
- **Use case**: Workflow automation, issue tracking

Container compatibility: API-based, works with token in environment.

### Database MCP Servers

**Source**: Various (PostgreSQL, SQLite implementations)

Database access for AI agents:

- **Capabilities**: Query execution, schema introspection
- **Security**: Read-only modes, query validation
- **Use case**: Data exploration, query generation

Container compatibility: Connect to containerized or external databases.

### Memory/Knowledge Graph

**Source**: [Anthropic Knowledge Graph Memory](https://github.com/modelcontextprotocol/servers)

Persistent memory for AI context:

- **Capabilities**: Store entities, relationships, facts
- **Persistence**: Survives across sessions
- **Use case**: Long-term project memory (related to PRD 012)

Container compatibility: Requires persistent storage volume.

## Selected Approach

[Filled after spike]

## Configuration Architecture

```
container/
├── .mcp/
│   ├── config.json           # MCP server configuration
│   └── servers/              # Custom MCP server scripts
├── mcp-servers/
│   ├── filesystem/           # Containerized filesystem server
│   ├── context7/             # Context7 client
│   └── custom/               # Project-specific servers
```

### config.json Structure

```json
{
  "servers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["--allowed-dirs", "/workspace"],
      "enabled": true
    },
    "context7": {
      "command": "mcp-server-context7",
      "env": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      },
      "enabled": true
    },
    "github": {
      "command": "mcp-server-github",
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "enabled": false
    }
  }
}
```

## Acceptance Criteria

- [ ] Given the container, when I start Claude Code, then configured MCP servers are available
- [ ] Given Context7 MCP server, when I ask about a library, then current documentation is retrieved
- [ ] Given filesystem MCP server, when agent reads files, then operations are scoped to allowed directories
- [ ] Given GitHub MCP server configured, when I query issues, then results are returned
- [ ] Given credentials in environment, when MCP servers start, then they authenticate correctly
- [ ] Given a custom MCP server, when I add it to config, then it becomes available to agents
- [ ] Given MCP server failure, when agent tries to use it, then graceful error handling occurs
- [ ] Given security constraints, when agent requests file outside allowed dirs, then request is denied

## Dependencies

- Requires: 001-prd-container-base, 003-prd-secret-injection, 005-prd-terminal-ai-agent, 006-prd-agentic-assistant
- Blocks: 012-prd-persistent-memory (may use MCP for memory)

## Spike Tasks

### Core Setup

- [ ] Install MCP runtime in container
- [ ] Configure filesystem MCP server with security boundaries
- [ ] Configure Context7 MCP server
- [ ] Test MCP with Claude Code
- [ ] Test MCP with Cline
- [ ] Test MCP with Continue

### Extended Servers

- [ ] Set up Playwright MCP server with headless browser
- [ ] Configure GitHub MCP server with token auth
- [ ] Test database MCP server (SQLite for simplicity)
- [ ] Evaluate Knowledge Graph memory server

### Security & Operations

- [ ] Document credential management for MCP servers
- [ ] Implement allowed directory restrictions
- [ ] Test error handling and graceful degradation
- [ ] Measure performance impact of MCP servers
- [ ] Create health check scripts for MCP servers

### Documentation

- [ ] Write setup guide for each MCP server
- [ ] Document custom MCP server creation
- [ ] Create troubleshooting guide
- [ ] Document security best practices

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io/specification/2025-11-25)
- [Official MCP Servers Repository](https://github.com/modelcontextprotocol/servers)
- [Anthropic MCP Introduction](https://www.anthropic.com/news/model-context-protocol)
- [Top 10 MCP Servers 2026](https://cybersecuritynews.com/best-model-context-protocol-mcp-servers/)
- [MCP Developer Guide](https://publicapis.io/blog/mcp-model-context-protocol-guide)
- [MCP Security Analysis](https://en.wikipedia.org/wiki/Model_Context_Protocol)
