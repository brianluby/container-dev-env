# Quickstart: AI IDE Extensions

**Feature Branch**: `009-ai-ide-extensions`
**Date**: 2026-01-23

## Prerequisites

1. Container base image (001) built and operational
2. OpenVSCode-Server (008) running and accessible
3. Secret injection (003) configured with at least `ANTHROPIC_API_KEY`
4. Volume architecture (004) in place for extension and config persistence
5. Node.js 22.x and Python 3.11+ available in container (from 001)

## Implementation Order

### Phase 1: Extension Installation (Dockerfile Layer)

1. Download pinned VSIX files for Continue (v1.2.14) and Cline (v3.51.0) in Dockerfile
2. Install extensions via `openvscode-server --install-extension`
3. Pre-install MCP server packages:
   - `npm install -g @modelcontextprotocol/server-filesystem@2026.1.14`
   - `pip install mcp-server-git==2026.1.14`
4. Add telemetry blocklist entries to `/etc/hosts`

### Phase 2: Configuration Templates (Chezmoi)

1. Create Continue config template at `~/.continue/config.yaml`
   - Define Anthropic model for chat (Claude Sonnet)
   - Define autocomplete model (Codestral or local Qwen)
   - Configure filesystem MCP server pointing to `/workspace`
2. Create Cline MCP settings template at the globalStorage path
3. Create VS Code user settings with `telemetry.telemetryLevel: "off"`

### Phase 3: Entrypoint Bridge Script

1. Write script that creates `~/.continue/.env` from OS environment variables
2. Ensure directory structure exists for Cline globalStorage
3. Integrate into existing container entrypoint (from 008)

### Phase 4: Integration Testing

1. Test extension activation (both extensions start without errors)
2. Test API key flow (env var → .env file → extension auth)
3. Test inline completions (type code, verify ghost text appears)
4. Test chat interface (ask question, verify response)
5. Test MCP filesystem (reference file not in editor)
6. Test provider switching (Anthropic → OpenAI)
7. Test telemetry blocking (verify no egress to PostHog)

## Key Files to Create/Modify

```
src/
├── docker/
│   └── Dockerfile.ai-extensions    # Extension install layer
├── scripts/
│   ├── install-extensions.sh       # Extension download + install
│   └── bridge-secrets.sh           # Env var → .env file bridge
├── config/
│   ├── continue/
│   │   └── config.yaml.tmpl        # Chezmoi template for Continue
│   ├── cline/
│   │   └── mcp-settings.json       # Cline MCP config
│   └── vscode/
│       └── settings.json           # VS Code user settings
└── hosts.d/
    └── telemetry-block.conf        # /etc/hosts additions

tests/
├── integration/
│   ├── test_extension_activation.sh
│   ├── test_api_key_bridge.sh
│   ├── test_completions.sh
│   ├── test_mcp_scope.sh
│   └── test_telemetry_block.sh
└── contract/
    ├── test_continue_config_valid.sh
    ├── test_cline_mcp_valid.sh
    └── test_no_hardcoded_keys.sh
```

## Verification Checklist

- [ ] `docker build` succeeds with extensions layer
- [ ] Container starts and both extensions show in Extensions panel
- [ ] Continue shows "connected" status with valid API key
- [ ] Typing Python code produces ghost text completions
- [ ] Chat panel returns response to code question
- [ ] MCP filesystem can list files in /workspace
- [ ] MCP filesystem CANNOT access files outside /workspace
- [ ] Cline prompts for approval before file writes
- [ ] Provider can be switched without container restart
- [ ] No network traffic to PostHog domains
- [ ] Extensions survive container rebuild (volume persistence)
- [ ] API keys do NOT appear in extension Output panel logs

## Common Issues

| Issue | Cause | Solution |
|-------|-------|---------|
| Continue shows "No API key" | `~/.continue/.env` not created | Check entrypoint script ran bridge-secrets.sh |
| Completions not appearing | Autocomplete model not configured | Verify model with `roles: [autocomplete]` exists |
| Cline can't find MCP servers | globalStorage path incorrect | Verify path matches `saoudrizwan.claude-dev` extension ID |
| MCP filesystem error | Node.js not available | Ensure Node.js 22.x in container |
| Git MCP error | Python not available | Ensure Python 3.11+ and mcp-server-git installed |
| Telemetry still sending | /etc/hosts not applied | Rebuild container image; check hosts entries |
