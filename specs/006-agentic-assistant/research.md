# Research: Agentic Assistant

**Feature Branch**: `006-agentic-assistant`
**Date**: 2026-01-22
**Status**: Complete

## Research Topics

### R1: Primary Agent Tool — OpenCode

**Decision**: OpenCode (https://opencode.ai, GitHub: anomalyco/opencode) is actively maintained, supports 75+ LLM providers, and provides TUI, CLI, Web, IDE, and headless server modes. MIT license. Suitable as primary agent.

**Rationale**: OpenCode satisfies all must-have requirements:
- Headless operation via `opencode run "prompt"` (non-interactive) and `opencode serve` (headless server)
- 75+ LLM providers including Anthropic, OpenAI, Google, AWS Bedrock, and any OpenAI-compatible endpoint
- Permission system: `allow` / `ask` / `deny` per tool — maps directly to manual/autonomous/hybrid approval modes
- MCP server support built-in
- Config via JSON/JSONC with environment variable interpolation (`{env:VARIABLE_NAME}`)
- Active development (docs updated 2026-01-22)

**Installation**: `curl -fsSL https://opencode.ai/install | bash`

**Configuration paths**:
- Global config: `~/.config/opencode/opencode.json`
- Project config: `opencode.json` (project root)
- Auth/state: `~/.local/share/opencode/auth.json`
- Remote config: `.well-known/opencode` (organizational defaults)
- Env var override: `OPENCODE_CONFIG` (path) or `OPENCODE_CONFIG_CONTENT` (inline)

**Alternatives considered**:
- Continue (headless daemon) — less mature agent mode
- Cline CLI — primarily VS Code extension, CLI is secondary
- Roo-Code — requires code-server

---

### R2: Secondary Agent Tool — Claude Code

**Decision**: Use the native installer (`curl -fsSL https://claude.ai/install.sh | bash`) rather than deprecated npm installation. The native binary is self-contained and does not require Node.js at runtime.

**Rationale**: Anthropic deprecated npm installation in favor of a native binary installer. The native binary:
- Is self-contained (no Node.js runtime dependency)
- Supports arm64 and amd64 Linux
- State stored in `~/.claude/` (projects, settings, sessions in JSONL format)
- Requires `ANTHROPIC_API_KEY` environment variable
- Autonomous mode via `--dangerously-skip-permissions` flag
- Session resume via `--continue` flag

**Key operational flags**:
- `-p, --prompt` — pass prompt directly (non-interactive)
- `-c, --continue` — resume previous conversation
- `--dangerously-skip-permissions` — autonomous mode (skip approval prompts)

**Alternatives considered**:
- npm global install (`npm install -g @anthropic-ai/claude-code`) — deprecated by Anthropic
- Docker sandbox (`docker sandbox run claude`) — not suitable for embedding in our container

---

### R3: Agent Binary Integrity Verification

**Decision**: Use HTTPS trust chain for official installer scripts; pin versions where possible.

**Rationale**:
- OpenCode: Official installer from `opencode.ai/install` over HTTPS
- Claude Code: Official installer from `claude.ai/install.sh` over HTTPS
- Both domains are controlled by their respective organizations
- Version pinning via config or installer flags where available
- Constitution requires: vulnerability scanning and version pinning

**Verification approach**:
```bash
# OpenCode: Install from official domain
curl -fsSL https://opencode.ai/install | bash

# Claude Code: Install from official domain
curl -fsSL https://claude.ai/install.sh | bash

# Post-install: Verify binaries exist and report version
opencode --version
claude --version
```

---

### R4: Agent State Persistence Strategy

**Decision**: Mount dedicated volumes for agent state directories; separate from project volume.

**Rationale**:
- OpenCode stores state in `~/.local/share/opencode/` (auth, sessions) and config in `~/.config/opencode/`
- Claude Code stores state in `~/.claude/` (projects, settings, sessions in JSONL)
- Both need persistence across container restarts (FR-015)
- Separation from project volume prevents agent state from polluting git repos

**Volume mapping**:
```
$STATE_VOLUME/opencode/share/ → $HOME/.local/share/opencode/
$STATE_VOLUME/opencode/config/ → $HOME/.config/opencode/
$STATE_VOLUME/claude/          → $HOME/.claude/
$PROJECT_VOLUME/               → /workspace/
```

---

### R5: File Exclusion Patterns (FR-023)

**Decision**: Use tool-native ignore mechanisms plus a shared `.agentignore` file.

**Rationale**:
- OpenCode supports `watcher` ignore patterns in config and permission-based file access control
- Claude Code supports `.claude/settings.json` with file ignore patterns
- A shared `.agentignore` file provides a tool-agnostic configuration point
- The wrapper script translates `.agentignore` patterns to tool-specific configs

**Implementation**:
- `.agentignore` at project root (patterns like `.env*`, `credentials/`, `*.key`)
- Wrapper script reads `.agentignore` and configures each tool's native ignore mechanism
- Default patterns: `.env`, `.env.*`, `*.pem`, `*.key`, `credentials/`, `secrets/`

---

### R6: Agent Wrapper Script Design

**Decision**: Create an `agent` CLI wrapper that selects and configures the appropriate tool.

**Rationale**: The ARD specifies a wrapper script (`agent` command) that abstracts tool selection. This provides:
- Consistent interface regardless of backend tool
- Automatic configuration from environment variables
- File exclusion pattern application
- Usage metrics aggregation

**Interface**:
```bash
agent [options] [task description]
  --claude              # Force Claude Code backend
  --mode manual|auto|hybrid  # Approval mode (maps to tool-native permissions)
  --resume              # Resume previous session
  --log                 # View action log
  --checkpoints         # List/manage checkpoints
  --usage               # Display token/cost metrics
  --serve               # Start headless server (OpenCode only)
```

**Selection logic**:
1. If `--claude` flag → use Claude Code (requires ANTHROPIC_API_KEY)
2. If `AGENT_BACKEND=claude` env var → use Claude Code
3. Otherwise → use OpenCode with configured provider
4. If no API keys configured → error with guidance

**Approval mode mapping**:
- `manual` → OpenCode: `"*": "ask"` / Claude Code: default (prompts for each action)
- `auto` → OpenCode: `"*": "allow"` / Claude Code: `--dangerously-skip-permissions`
- `hybrid` → OpenCode: per-tool permissions / Claude Code: settings-based policies

---

### R7: Headless Operation Modes

**Decision**: Support both non-interactive single-task and headless server modes.

**Rationale**:
- OpenCode provides: `opencode run "prompt"` (single task, exits on completion) and `opencode serve` (persistent headless server with API)
- Claude Code provides: `claude -p "prompt"` (single task) and session-based operation
- Headless server mode enables CI/CD integration and remote triggering (Could-Have C-2, C-3)
- Server mode supports authentication via `OPENCODE_SERVER_PASSWORD`

**Use cases**:
- `agent "fix all lint errors"` → non-interactive, runs to completion
- `agent --serve` → headless server for API access
- `agent --resume` → resume previous interactive session

---

### R8: Multi-Architecture Build Strategy

**Decision**: Use Docker buildx with `TARGETARCH` build arg for platform-specific binary downloads.

**Rationale**: Constitution mandates arm64 + amd64 support. Both tools support both architectures:
- OpenCode: Installer auto-detects architecture
- Claude Code: Native installer auto-detects architecture

**Dockerfile pattern**:
```dockerfile
# OpenCode: Pin to specific version, download binary directly
ARG OPENCODE_VERSION=0.5.2
RUN ARCH="$(uname -m)" && \
    curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${ARCH}" \
      -o /usr/local/bin/opencode && chmod +x /usr/local/bin/opencode && \
    opencode --version

# Claude Code (optional, pinned version)
ARG INSTALL_CLAUDE_CODE=false
ARG CLAUDE_CODE_VERSION=1.0.23
RUN if [ "$INSTALL_CLAUDE_CODE" = "true" ]; then \
      curl -fsSL "https://claude.ai/install.sh" | CLAUDE_VERSION="${CLAUDE_CODE_VERSION}" bash && \
      claude --version; \
    fi
```

---

### R9: Checkpoint Implementation

**Decision**: Use git-based checkpoints as the primary mechanism for both tools.

**Rationale**:
- OpenCode: Does not have a native checkpoint system; git commits/stashes serve as checkpoints
- Claude Code: Has native checkpoint system that automatically saves code state before changes
- The wrapper script can implement a uniform checkpoint layer using git:
  - `git stash` or `git commit` before each logical operation
  - Tag checkpoints with metadata (timestamp, operation description)
  - Rollback via `git checkout` or `git stash pop`
- This approach works regardless of which backend tool is active

**Checkpoint strategy**:
```bash
# Before each agent operation:
git add -A && git stash push -m "checkpoint: $(date -u +%Y%m%dT%H%M%SZ) - ${OPERATION}"

# On rollback:
git stash pop  # or git stash apply stash@{N}

# List checkpoints:
git stash list --format="%gd: %gs"
```

---

### R10: Action Log Implementation

**Decision**: Aggregate tool-native session logs into a standardized action log format.

**Rationale**:
- OpenCode: Sessions stored in `~/.local/share/opencode/` with conversation history
- Claude Code: Sessions stored in `~/.claude/projects/` as JSONL with full action history
- Both tools log their operations natively
- The wrapper script can extract and format a unified action log

**Log format** (JSON Lines):
```jsonl
{"timestamp":"2026-01-22T10:00:00Z","action":"file_edit","target":"src/main.rs","details":"Added error handling"}
{"timestamp":"2026-01-22T10:00:05Z","action":"command","target":"cargo test","result":"pass"}
{"timestamp":"2026-01-22T10:00:10Z","action":"checkpoint","id":"stash@{0}","description":"After error handling"}
```

**Storage**: `$AGENT_STATE_DIR/logs/{session-id}.jsonl`
