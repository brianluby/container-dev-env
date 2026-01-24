# Research: MCP Integration

**Feature**: 012-mcp-integration
**Date**: 2026-01-23
**Source**: Spike 011 results + npm package documentation + AI tool config specs

## R-1: MCP Server Package Versions and Compatibility

**Decision**: Pin to specific versions validated in spike 011.

**Packages**:

| Package | Version | Size (installed) | Arch Support |
|---------|---------|-----------------|--------------|
| @modelcontextprotocol/server-filesystem | 2026.1.14 | ~2MB | Universal (pure JS) |
| @modelcontextprotocol/server-memory | latest (pin at install) | ~1MB | Universal (pure JS) |
| @modelcontextprotocol/server-sequential-thinking | latest (pin at install) | ~1MB | Universal (pure JS) |
| @upstash/context7-mcp | 2.1.0 | ~5MB | Universal (pure JS) |
| @modelcontextprotocol/server-github | latest (pin at install) | ~2MB | Universal (pure JS) |
| @playwright/mcp | latest (pin at install) | ~3MB + Chromium ~150MB | Arch-specific binary |
| mcp-server-git | latest (pip) | ~2MB | Universal (Python) |

**Total estimated**: ~16MB npm packages + ~2MB pip (without Playwright Chromium)

**Rationale**: All packages are pure JavaScript except Playwright (requires Chromium). Total well within 150MB budget. Playwright's Chromium is the largest component and should be opt-in at image build time.

**Alternatives considered**:
- npx at runtime: Slower startup, network dependency, non-deterministic
- Docker MCP gateway: Adds complexity, not needed for stdio transport

## R-2: AI Tool Configuration Formats

**Decision**: Generate three distinct config formats from single source.

### Claude Code Format

Location: `/workspace/.claude/settings.local.json` (project scope)

```json
{
  "mcpServers": {
    "server-name": {
      "command": "binary-or-npx",
      "args": ["arg1", "arg2"],
      "env": {
        "KEY": "value"
      }
    }
  }
}
```

Notes:
- Uses `mcpServers` object at top level (alongside `permissions`)
- No `enabled`/`disabled` field — absence means disabled
- Project-scoped file takes precedence over user-scoped

### Cline Format

Location: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

```json
{
  "mcpServers": {
    "server-name": {
      "command": "binary-or-npx",
      "args": ["arg1", "arg2"],
      "env": {
        "KEY": "value"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

Notes:
- Uses `disabled: true/false` (inverted from source config's `enabled`)
- Has `autoApprove` array for tool-level auto-approval
- Path may vary; VS Code extension storage location is consistent

### Continue Format

Location: `~/.continue/config.yaml`

```yaml
mcpServers:
  - name: server-name
    command: binary-or-npx
    args:
      - arg1
      - arg2
    env:
      KEY: value
```

Notes:
- Uses YAML array (not object) for mcpServers
- Each entry has explicit `name` field
- No disabled/enabled concept — absence means disabled
- File contains other config (models, etc.) — only update mcpServers section

**Rationale**: Each tool has its own established format. Generating all three from one source eliminates manual duplication and drift.

**Alternatives considered**:
- Symlinks to shared config: Not possible; formats differ
- MCP config registry file: Non-standard, tools wouldn't read it

## R-3: Environment Variable Substitution Patterns

**Decision**: Use `${VARIABLE_NAME}` syntax in source config, resolved by `envsubst`-style processing during generation.

**Implementation approach**:
```bash
# For each env reference in JSON values, substitute with actual value
# Use jq + env to perform substitution safely
jq --arg key "$ENV_VAR_NAME" --arg val "$ENV_VAR_VALUE" \
  '(.env[$key]) = $val' config.json
```

**Edge cases handled**:
- Missing env var → log warning, skip server (don't fail entire generation)
- Empty env var → substitute empty string, log warning
- Special characters in values → jq handles JSON escaping automatically
- Nested `${...}` → not supported, literal text preserved

**Rationale**: `envsubst` is a well-known pattern; jq handles JSON escaping correctly for values containing quotes, newlines, etc.

**Alternatives considered**:
- Runtime substitution by tools: Tools don't support `${...}` natively in all config locations
- sed/awk replacement: Unsafe for JSON (can corrupt structure on special chars)

## R-4: Filesystem MCP Security Model

**Decision**: Directory allowlist passed as positional arguments to server binary.

**How it works**:
```json
{
  "filesystem": {
    "command": "mcp-server-filesystem",
    "args": ["/workspace", "/home/dev/.local/share/mcp-memory"]
  }
}
```

The `@modelcontextprotocol/server-filesystem` package:
- Resolves all paths to absolute form before checking
- Rejects any path not under an allowed directory
- Blocks symlink escape (resolves symlinks before checking)
- Blocks `../` traversal (canonicalizes path)
- Returns clear error message on denied access

**Container provides second layer**:
- Container filesystem isolation limits blast radius
- Non-root user cannot access system files
- Volume mounts define what's even visible

**Rationale**: Defense in depth — MCP server allowlist + container isolation + user permissions.

## R-5: Memory Server Persistence Strategy

**Decision**: `@modelcontextprotocol/server-memory` stores knowledge graph as JSON at a configurable path, backed by Docker named volume.

**Configuration**:
```json
{
  "memory": {
    "command": "mcp-server-memory",
    "env": {
      "MEMORY_FILE_PATH": "/home/dev/.local/share/mcp-memory/memory.json"
    }
  }
}
```

**Docker volume mount**:
```yaml
volumes:
  mcp-memory:
    driver: local

services:
  dev:
    volumes:
      - mcp-memory:/home/dev/.local/share/mcp-memory
```

**Rationale**: Named volumes persist across `docker compose down/up` cycles. XDG-compliant path. Separate from workspace to avoid accidental commits.

**Alternatives considered**:
- Workspace-local storage: Risk of committing knowledge graph to version control
- SQLite: Over-engineered for single-file knowledge graph
- Redis/external DB: Violates container-first (external dependency)

## R-6: Startup Validation Approach

**Decision**: Validate at container startup via `validate-mcp.sh`, called from entrypoint before config generation.

**Validation checks**:
1. Node.js available and correct version
2. Each enabled server's command binary exists on PATH
3. Source config file parseable as valid JSON
4. Required env vars present for enabled servers that declare them
5. Memory volume directory writable (if memory server enabled)

**Output format** (structured logging, matches entrypoint pattern):
```
[mcp-validate] === MCP Server Validation ===
[mcp-validate]   filesystem: OK (mcp-server-filesystem found)
[mcp-validate]   context7: OK (npx available, CONTEXT7_API_KEY set)
[mcp-validate]   memory: OK (mcp-server-memory found, volume writable)
[mcp-validate]   github: SKIP (disabled in config)
[mcp-validate] === Validation Complete (3/4 servers ready) ===
```

**Non-blocking**: Validation failures for individual servers produce warnings but don't prevent container startup. Only a completely unparseable config file is fatal.

**Rationale**: Aligns with Constitution Principle VI (Observability) and FR-008 (clear error messages). Matches existing entrypoint logging style.

## R-7: Playwright MCP Server Considerations

**Decision**: Pre-install npm package but NOT Chromium by default. Chromium installation is opt-in via build arg.

**Rationale**:
- Chromium adds ~150MB to image size (significant)
- Most users won't need browser automation
- Package itself is small (~3MB)
- Users can install Chromium at runtime if needed: `npx playwright install chromium`

**Build-time opt-in**:
```dockerfile
ARG INSTALL_PLAYWRIGHT_BROWSER=false
RUN if [ "$INSTALL_PLAYWRIGHT_BROWSER" = "true" ]; then \
      npx playwright install --with-deps chromium; \
    fi
```

## R-8: Git MCP Server (Python-based)

**Decision**: Install `mcp-server-git` via pip in the container (Python already available in base image).

**Installation**:
```dockerfile
RUN pip install --no-cache-dir mcp-server-git
```

**Configuration**:
```json
{
  "git": {
    "command": "python3",
    "args": ["-m", "mcp_server_git", "--repository", "/workspace"],
    "enabled": false
  }
}
```

**Rationale**: Git MCP provides repository introspection beyond what the filesystem server offers (diffs, history, branches). Python is already in the base image. Disabled by default since filesystem + CLI git cover most needs.
