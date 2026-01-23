# Research: AI IDE Extensions

**Feature Branch**: `009-ai-ide-extensions`
**Date**: 2026-01-23
**Status**: Complete

## Research Questions & Findings

### 1. Continue Extension — Version & Configuration

**Decision**: Pin Continue to v1.2.14 (latest stable on Open VSX as of 2026-01-14).

**Rationale**: This is the latest non-pre-release version. The 1.3.x line is entirely pre-release. Pinning to stable ensures reliability.

**Key findings**:
- Extension ID: `Continue.continue`
- Config location: `~/.continue/config.yaml` (schema v1)
- Secrets: `~/.continue/.env` file (NOT OS environment variables directly)
- Secret syntax in config: `${{ secrets.VAR_NAME }}` references `~/.continue/.env`
- Autocomplete uses `roles: [autocomplete]` on a separate model entry
- MCP tools only available in Continue's agent mode
- License: Apache-2.0

**Alternatives considered**:
- v1.3.29 (pre-release) — rejected for stability
- Floating latest — rejected per FR-017 (version pinning requirement)

---

### 2. Continue Autocomplete — Model Selection

**Decision**: Use a FIM-trained model for autocomplete (Codestral via Mistral API, or local Qwen 2.5 Coder via Ollama). Use Claude Sonnet for chat.

**Rationale**: General-purpose models (GPT-4o, Claude) are NOT recommended for autocomplete because they lack fill-in-the-middle (FIM) training. FIM-specific models provide faster, more relevant completions.

**Recommended models**:
- Remote: `codestral-latest` (Mistral, requires MISTRAL_API_KEY)
- Local: `qwen2.5-coder:1.5b` or `starcoder2:3b` (Ollama)
- Fallback: `claude-haiku-4-20250514` (Anthropic, works but suboptimal for FIM)

**Alternatives considered**:
- Claude Haiku for autocomplete — works but not FIM-trained, less relevant completions
- Same model for both chat and autocomplete — rejected per FR-018 (separate models)

---

### 3. Continue Secrets Mechanism

**Decision**: Use `~/.continue/.env` file for API key injection, populated from container environment variables at startup via an entrypoint script.

**Rationale**: Continue does NOT natively read OS environment variables. It reads from `~/.continue/.env` using `${{ secrets.VAR_NAME }}` syntax. The container entrypoint must bridge the gap by writing env vars to this file.

**Implementation pattern**:
```bash
# In container entrypoint (after secret injection from 003)
mkdir -p ~/.continue
cat > ~/.continue/.env <<EOF
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
MISTRAL_API_KEY=${MISTRAL_API_KEY}
EOF
chmod 600 ~/.continue/.env
```

**Alternatives considered**:
- Direct env var reference (`$ANTHROPIC_API_KEY`) — not supported by Continue
- `localEnv:` syntax — reported as unreliable (GitHub issues #4323, #5902, #6648)
- Hard-coding in config.yaml — rejected per security requirements

---

### 4. Cline Extension — Version & Configuration

**Decision**: Pin Cline to v3.51.0 (latest on Open VSX as of 2026-01-15).

**Key findings**:
- Extension ID: `saoudrizwan.claude-dev`
- API keys: Uses VS Code SecretStorage (UI-only setup) OR `ANTHROPIC_API_KEY` env var as workaround
- Auto-approve settings: GlobalState only — cannot be set via settings.json
- MCP config: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`
- Telemetry: Disabled via `"telemetry.telemetryLevel": "off"` in settings.json (VS Code global setting)
- Telemetry concerns: Known bugs where telemetry was sent despite being disabled (Issues #7068, #3361)
- License: Apache-2.0

**Architecture implications**:
- Cline's API key setup requires either UI interaction on first launch OR the `ANTHROPIC_API_KEY` env var workaround
- Auto-approve settings default to requiring approval for all actions (safe default, matches FR-009)
- MCP config must be pre-populated at the globalStorage path
- Network-level blocking of `data.cline.bot` and `*.posthog.com` recommended for telemetry defense-in-depth

**Alternatives considered**:
- Roo-Code fork (headless config support) — less mature, smaller community
- Declarative settings.json config — not supported by Cline architecture

---

### 5. MCP Filesystem Server — Package & Security

**Decision**: Use `@modelcontextprotocol/server-filesystem` version >= 0.6.4 (npm date version 2025.7.01+), pre-installed in container image.

**Rationale**: The correct package name is `@modelcontextprotocol/server-filesystem` (NOT `@anthropic/mcp-server-filesystem` as referenced in PRD/ARD). Versions prior to 0.6.4 have two critical CVEs.

**Security CVEs (patched in >= 0.6.4)**:
- **CVE-2025-53109** (CVSS 8.4): Symlink bypass — crafted symlink escapes directory sandbox for full filesystem access
- **CVE-2025-53110** (CVSS 7.3): Directory containment bypass — naive prefix matching allows reads/writes outside allowed paths

**Implementation**:
```bash
# Pre-install in Dockerfile (pinned version, avoid npx runtime download)
RUN npm install -g @modelcontextprotocol/server-filesystem@2026.1.14
```

**Alternatives considered**:
- `npx -y` at runtime — rejected per SEC finding F4 (supply chain risk from runtime downloads)
- `@anthropic/mcp-server-filesystem` — does not exist; incorrect package name in PRD

---

### 6. MCP Git Server — Package & Limitations

**Decision**: Use `mcp-server-git` from PyPI (Python package, NOT npm), installed via pip in the container.

**Rationale**: The official git MCP server is Python-only. There is no npm equivalent.

**Known limitation**: The `--repository` argument is NOT enforced at runtime (GitHub Issue #604). All git commands accept a `repo_path` parameter that can point anywhere on the filesystem. Container isolation mitigates this risk.

**Implementation**:
```bash
# Pre-install in Dockerfile
RUN pip install mcp-server-git==2026.1.14
```

**Runtime command**:
```bash
python -m mcp_server_git --repository /workspace
```

**Alternatives considered**:
- `uvx mcp-server-git` — works but adds uv dependency; pip is simpler
- npm-based git server — does not exist
- Skip git MCP entirely — reduces context quality; acceptable risk with container isolation

---

### 7. Extension Installation Method

**Decision**: Use OpenVSCode-Server CLI (`openvscode-server --install-extension`) with pinned VSIX files pre-downloaded in the Dockerfile.

**Rationale**: Pre-downloading VSIX files in the Dockerfile ensures reproducible builds (no runtime dependency on Open VSX registry availability) and enables version pinning with integrity verification.

**Implementation**:
```bash
# In Dockerfile
RUN curl -L -o /tmp/continue.vsix \
    "https://open-vsx.org/api/Continue/continue/1.2.14/file/Continue.continue-1.2.14.vsix" && \
    curl -L -o /tmp/cline.vsix \
    "https://open-vsx.org/api/saoudrizwan/claude-dev/3.51.0/file/saoudrizwan.claude-dev-3.51.0.vsix" && \
    openvscode-server --install-extension /tmp/continue.vsix && \
    openvscode-server --install-extension /tmp/cline.vsix && \
    rm /tmp/*.vsix
```

**Alternatives considered**:
- Runtime install from Open VSX — fragile, depends on registry availability
- Extension ID install (`--install-extension Continue.continue`) — may not support version pinning

---

### 8. Telemetry Defense-in-Depth

**Decision**: Three layers of telemetry prevention.

**Implementation**:
1. VS Code setting: `"telemetry.telemetryLevel": "off"`
2. Continue setting: extension respects VS Code telemetry setting
3. Network blocking: Add to container `/etc/hosts` or firewall rules:
   - `0.0.0.0 data.cline.bot`
   - `0.0.0.0 us.posthog.com`
   - `0.0.0.0 eu.posthog.com`

**Rationale**: Cline has known bugs where telemetry was sent despite being disabled (Issues #7068, #3361). Network-level blocking provides defense-in-depth.

---

## Corrections to PRD/ARD Assumptions

| PRD/ARD Assumption | Actual Finding | Impact |
|--------------------|----------------|--------|
| `@anthropic/mcp-server-filesystem` | Correct package: `@modelcontextprotocol/server-filesystem` | Update all config references |
| Git MCP is npm-based (`npx @anthropic/mcp-server-git`) | Python-only: `mcp-server-git` (PyPI) | Need Python + pip in container (already available per 001) |
| Cline configured via `.vscode/settings.json` | API keys via SecretStorage/env var; MCP via globalStorage JSON | Different config path and mechanism |
| Continue reads OS env vars for API keys | Reads from `~/.continue/.env` file | Need entrypoint bridge script |
| `autoApproveWrites: false` in settings.json | Auto-approve is GlobalState only (defaults to false) | No explicit config needed; safe by default |
| MCP servers downloaded via npx at runtime | Pre-install in Dockerfile for security and reproducibility | Dockerfile changes needed |
| Tab autocomplete uses Claude Haiku | FIM-trained models recommended (Codestral/Qwen) | Different model selection strategy |

## Open Items (Non-Blocking)

- Continue MCP tools only work in "agent mode" — verify this covers the use cases in User Stories 5
- Cline's `ANTHROPIC_API_KEY` env var workaround may require first-launch UI interaction to fully activate — need to test in container
- Git MCP server's `--repository` restriction is unenforced — acceptable given container isolation, but document as known limitation
