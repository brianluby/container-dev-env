# Technical Specification Document: 011-mcp-integration

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/011-mcp-integration/` and `prds/011-prd-mcp-integration.md`

## 1. Executive Summary

This document specifies the architecture for Model Context Protocol (MCP) servers within the container. It defines how servers are configured, secured, and exposed to agents.

## 2. Technical Specifications

### 2.1 Server Hosting
*   **Runtime**: Node.js (via `npx` or global install).
*   **Transport**: Stdio (Standard Input/Output) over local process execution.
*   **Configuration**: `~/.mcp/config.json`.

### 2.2 Core Servers
*   **Filesystem**: `@modelcontextprotocol/server-filesystem`.
    *   **Scope**: Restricted to `/workspace` and `/home/dev`.
*   **Memory**: `@modelcontextprotocol/server-memory` (Knowledge Graph).

## 3. Data Models

### 3.1 Configuration Schema (`config.json`)
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"],
      "env": {}
    }
  }
}
```

## 4. API Contracts & Interfaces

### 4.1 Environment Isolation
Each MCP server runs as a subprocess of the Agent (Claude/Cline).
*   **Security**: Servers inherit the environment variables of the parent agent but should rely on explicit config for sensitive tokens.

## 5. Architectural Improvements

### 5.1 Server Lazy Loading
**Problem**: Running all MCP servers consumes RAM.
**Solution**: Agents trigger server startup only upon first request (standard MCP behavior). Ensure `npx` caching (`~/.npm`) is persisted via volume to prevent re-downloading servers on every start.

## 6. Testing Strategy
*   **Connectivity**: Use a simple MCP Client CLI (`mcp-cli-tester`) to connect to the configured servers via stdio and list tools.
*   **Permissions**: Verify Filesystem server rejects access to `/etc/shadow`.
