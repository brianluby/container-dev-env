# Implementation Plan: AI IDE Extensions

**Branch**: `009-ai-ide-extensions` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-ai-ide-extensions/spec.md`

## Summary

Install and configure Continue (primary, tab autocomplete + chat) and Cline (secondary, agentic tasks with human approval) as AI coding extensions within the containerized IDE (OpenVSCode-Server). Extensions authenticate to LLM providers via environment variable bridge to Continue's `.env` file and Cline's env var workaround. MCP servers (filesystem + git) are pre-installed in the container image for security. Extension versions are pinned, telemetry is blocked at both application and network levels.

## Technical Context

**Language/Version**: Bash 5.x (scripts), Dockerfile (container layer), Go templates (Chezmoi configs)
**Primary Dependencies**: Continue v1.2.14, Cline v3.51.0, @modelcontextprotocol/server-filesystem 2026.1.14, mcp-server-git 2026.1.14 (Python)
**Storage**: File-based (YAML, JSON, dotenv) persisted via Docker volumes
**Testing**: Bash integration tests (container-based), contract validation scripts
**Target Platform**: Docker container (Debian Bookworm-slim, arm64 + amd64), OpenVSCode-Server
**Project Type**: Infrastructure/configuration (Dockerfile additions, config templates, entrypoint scripts)
**Performance Goals**: Completions <5s latency (provider-dependent), chat <10s (provider-dependent)
**Constraints**: 512MB container memory, Open VSX registry only, no host dependencies, API keys never in image layers
**Scale/Scope**: Single developer per container instance

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Container-First Architecture | PASS | All extensions run inside container; no host installations; VSIX pre-downloaded in Dockerfile; MCP servers pre-installed |
| II. Multi-Language Standards | PASS | Bash scripts follow conventions; feature enables AI for Python/TS/Rust/Go |
| III. Test-First Development | PASS | Integration tests defined for activation, auth, completions, MCP scope, telemetry |
| IV. Security-First Design | PASS | API keys via env vars (never committed); telemetry disabled + network-blocked; MCP scoped to /workspace; extension versions pinned; CVE-patched MCP server |
| V. Reproducibility & Portability | PASS | Pinned extension versions (VSIX in Dockerfile); pinned MCP package versions; multi-arch compatible; deterministic builds |
| VI. Observability & Debuggability | PASS | Extension Output panel for diagnostics; non-blocking error notifications; extension activation logged |
| VII. Simplicity & Pragmatism | PASS | Two extensions justified (complementary use cases); file-based config; no custom application code beyond scripts |

**Post-Phase 1 Re-check**: All principles still pass. The secrets bridge script adds minimal complexity (5 lines of bash) justified by Continue's architecture requiring `.env` file rather than OS env vars.

## Project Structure

### Documentation (this feature)

```text
specs/009-ai-ide-extensions/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: technology research
├── data-model.md        # Phase 1: configuration entities
├── quickstart.md        # Phase 1: implementation guide
├── contracts/
│   └── file-interfaces.md   # Phase 1: file format contracts
├── checklists/
│   └── requirements.md      # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
src/
├── docker/
│   └── Dockerfile.ai-extensions     # Extension install + MCP layer
├── scripts/
│   ├── install-extensions.sh        # Download + install pinned VSIX files
│   └── bridge-secrets.sh            # Env var → ~/.continue/.env bridge
├── config/
│   ├── continue/
│   │   └── config.yaml.tmpl         # Chezmoi template for Continue config
│   ├── cline/
│   │   └── cline_mcp_settings.json  # Cline MCP server declarations
│   └── vscode/
│       └── settings.json            # VS Code user settings (telemetry off)
└── hosts.d/
    └── telemetry-block.conf         # /etc/hosts entries for telemetry blocking

tests/
├── contract/
│   ├── test_continue_config_valid.sh    # Validate config.yaml syntax
│   ├── test_cline_mcp_valid.sh          # Validate MCP settings JSON
│   └── test_no_hardcoded_keys.sh        # Scan for literal API keys
├── integration/
│   ├── test_extension_activation.sh     # Both extensions activate clean
│   ├── test_api_key_bridge.sh           # Env vars → .env → extension auth
│   ├── test_completions.sh              # Ghost text appears for .py/.ts/.rs/.go
│   ├── test_chat_response.sh            # Chat panel returns response
│   ├── test_mcp_scope.sh               # Filesystem MCP reads /workspace, blocked outside
│   ├── test_provider_switch.sh          # Switch providers without restart
│   └── test_telemetry_block.sh          # No egress to PostHog domains
└── unit/
    └── test_bridge_secrets.sh           # Bridge script handles missing/empty vars
```

**Structure Decision**: Single project structure with `src/` for Dockerfile additions, scripts, and config templates. Tests use Bash integration tests run inside the container. No application code — this is purely infrastructure/configuration.

## Complexity Tracking

No constitution violations. No complexity justification needed.

## Key Design Decisions (from Research)

| Decision | Rationale | Reference |
|----------|-----------|-----------|
| Pre-install VSIX in Dockerfile (not runtime Open VSX) | Reproducible builds; no registry dependency at startup | research.md §7 |
| Bridge env vars to `~/.continue/.env` | Continue doesn't read OS env vars directly | research.md §3 |
| Use FIM model for autocomplete (Codestral/Qwen) | General models (Claude/GPT) poor for fill-in-the-middle | research.md §2 |
| Pre-install MCP servers (not npx runtime) | Supply chain security; CVE mitigation; reproducibility | research.md §5, §6 |
| Network-level telemetry blocking | Cline has known bugs sending telemetry when disabled | research.md §8 |
| Git MCP uses Python (not Node.js) | Official package is Python-only | research.md §6 |
| Correct package: `@modelcontextprotocol/server-filesystem` | PRD referenced incorrect `@anthropic/` scope | research.md §5 |
| Cline API key via `ANTHROPIC_API_KEY` env var workaround | No declarative settings.json support for API keys | research.md §4 |

## Implementation Phases

### Phase 1: Dockerfile Extension Layer

- Download pinned VSIX files (Continue v1.2.14, Cline v3.51.0)
- Install extensions into OpenVSCode-Server
- Install MCP packages globally (npm for filesystem, pip for git)
- Add telemetry blocklist to /etc/hosts
- Verify build succeeds on both arm64 and amd64

### Phase 2: Configuration Templates

- Create Continue `config.yaml` Chezmoi template with provider definitions
- Create Cline MCP settings JSON file
- Create VS Code user settings with telemetry disabled
- Create bridge-secrets.sh entrypoint script

### Phase 3: Entrypoint Integration

- Add bridge-secrets.sh to container startup sequence
- Ensure config directories exist before extension activation
- Populate Cline globalStorage path with MCP settings
- Integrate with existing 008 entrypoint

### Phase 4: Testing

- Write contract tests (config file validation, no hardcoded keys)
- Write integration tests (activation, auth, completions, MCP, telemetry)
- Write unit tests for bridge script edge cases
- Run full test suite in CI

## Risk Mitigations

| Risk | Mitigation | Verification |
|------|------------|--------------|
| CVE-2025-53109/53110 in filesystem MCP | Pin to >= 0.6.4; container isolation | Version check in contract test |
| Git MCP --repository bypass | Container filesystem isolation limits blast radius | Integration test: MCP can't read /etc/shadow |
| Cline telemetry despite setting | Network-level blocking in /etc/hosts | Integration test: no PostHog egress |
| Continue .env file permission leak | chmod 600 in bridge script; never in image layer | Contract test: file permissions |
| Extension version drift | Pinned VSIX in Dockerfile; explicit upgrade process | Manifest lists exact versions |
