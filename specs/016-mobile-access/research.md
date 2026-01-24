# Research: Mobile Push Notifications for AI Agent Events

**Feature**: 016-mobile-access | **Date**: 2026-01-23

## Decision Log

### D-1: ntfy.sh API Integration

**Decision**: Use ntfy.sh HTTP POST API with Bearer token authentication and X-Priority header for priority levels.

**Rationale**: ntfy.sh provides a simple, well-documented HTTP API that maps directly to our requirements. Bearer tokens provide topic-level access control. Priority levels 1-5 map exactly to ntfy.sh's native priority system with distinct mobile behavior per level.

**Key Details**:
- **Endpoint**: `POST https://<server>/<topic>` (configurable server, default `https://ntfy.sh`)
- **Auth Header**: `Authorization: Bearer <token>` (token format: `tk_<random>`)
- **Priority Header**: `X-Priority: <1-5>` (maps to min/low/default/high/urgent)
- **Title Header**: `X-Title: <title>`
- **Message**: Plain text in request body
- **Size Limit**: 4,096 bytes (ntfy.sh limit); our 200-char spec constraint is well within this
- **Rate Limits** (public ntfy.sh): 60 burst, then 1/10s sustained; self-hosted configurable

**Alternatives Considered**:
- Pushover ($5/platform, proprietary) — rejected for cost and vendor lock-in
- Firebase Cloud Messaging (complex setup, Google dependency) — rejected for complexity
- Custom WebSocket server — rejected per outbound-only constraint

### D-2: Slack Webhook Integration

**Decision**: Use Slack Incoming Webhooks API with JSON payload and Block Kit formatting for rich priority indicators.

**Rationale**: Slack webhooks are simple HTTP POSTs with JSON payloads. No SDK needed, just curl. Priority conveyed via emoji indicators in message text.

**Key Details**:
- **Endpoint**: `POST https://hooks.slack.com/services/T.../B.../XXX` (from env var)
- **Content-Type**: `application/json`
- **Payload**: `{"text": "<emoji> <message>"}` (minimal format)
- **Rate Limit**: 1 message/second/channel; `429` with `Retry-After` header
- **Max Length**: 40,000 chars (our 200-char limit is fine)
- **Error Codes**: 200=ok, 400=bad payload (don't retry), 429=rate limited (retry), 5xx=server error (retry)

**Priority Emoji Mapping**:
- Priority 5 (urgent): `🔴`
- Priority 4 (high): `🟠`
- Priority 3 (default): `🟢`
- Priority 2 (low): `⬜`
- Priority 1 (min): `⬜`

**Alternatives Considered**:
- Slack API with Bot token (more powerful but needs OAuth app setup) — rejected for complexity
- Discord webhooks (similar simplicity) — not in spec, could be future extension

### D-3: Testing Framework

**Decision**: Use bats-core v1.13.0 for Bash script testing, installed via git clone with version pinning.

**Rationale**: bats-core is the standard Bash testing framework, provides isolated test execution, and supports mocking external commands via function override. v1.13.0 is the latest stable release with fail-fast support and improved test isolation.

**Key Details**:
- **Installation**: `git clone --branch v1.13.0 https://github.com/bats-core/bats-core.git && ./install.sh /usr/local`
- **Test Format**: `.bats` files with `@test "description" { ... }` blocks
- **Assertions**: Standard bash conditionals: `[ "$status" -eq 0 ]`, `[[ "$output" =~ pattern ]]`
- **Mocking curl**: Override with shell function + `export -f curl` to mock HTTP calls
- **Test Isolation**: Each `@test` runs in its own subprocess
- **Hooks**: `setup()`/`teardown()` per-test, `setup_file()`/`teardown_file()` per-file
- **Run Command**: `run my_function` captures `$status`, `$output`, `$lines[@]`

**Alternatives Considered**:
- shunit2 (less maintained, fewer features) — rejected
- Plain bash assertions (no framework, hard to organize) — rejected
- apt install bats (may be outdated version) — rejected for version pinning requirement

### D-4: Agent Hook Mechanism

**Decision**: Use Claude Code's `Stop` and `Notification` hook events to trigger notify.sh. Cline/Continue lack native hook support — provide manual integration guidance.

**Rationale**: Claude Code has first-class hook support with JSON stdin data, configurable timeouts, and parallel execution. The `Stop` event fires when the agent finishes responding (task completion), and `Notification` fires for agent-initiated alerts. Cline and Continue don't support post-task hooks natively.

**Key Details**:

**Claude Code Hooks** (primary):
- Config location: `.claude/settings.local.json` (per-developer, not committed)
- Hook events: `Stop` (task done), `PostToolUse` (after tool), `Notification` (agent alert)
- Input: JSON on stdin with `session_id`, `hook_event_name`, `tool_name`, etc.
- Timeout: 10s recommended for notification hooks (non-blocking)
- Exit code 0 = success, 2 = blocking error

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "notify.sh \"Agent task completed\" 3 \"Task Done\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Cline** (manual integration):
- No native post-task hooks
- Workaround: User manually runs notify.sh after reviewing Cline output
- MCP server could potentially bridge, but adds complexity beyond scope

**Continue** (manual integration):
- No native task hooks
- Agent mode only for MCP tool execution
- Same manual workaround as Cline

**Alternatives Considered**:
- File watcher daemon (watches for sentinel files) — rejected for complexity
- Log parsing (tail agent logs) — rejected for fragility and parsing complexity
- MCP-based notification server — rejected per outbound-only constraint (no inbound)

### D-5: Content Sanitization Approach

**Decision**: Regex-based pattern matching to strip file paths, API key patterns, and code snippets. Applied before message truncation.

**Rationale**: Simple regex patterns cover the common cases (absolute paths, common key formats, code-like patterns). Runs in Bash using `sed` — no external dependencies.

**Key Patterns**:
- File paths: `/[a-zA-Z0-9_/.~-]+` (absolute paths)
- API keys: Common patterns like `sk-[a-zA-Z0-9]+`, `[A-Z0-9]{20,}`, `token_[a-z0-9]+`
- Code snippets: Lines with common code patterns (curly braces, semicolons, `function`, `class`, `import`)
- Environment variables: `[A-Z_]+=\S+` (key=value patterns)

**Processing Order**:
1. Strip file paths
2. Strip API key patterns
3. Strip code-like content
4. Collapse whitespace
5. Truncate to 200 characters

### D-6: Quiet Hours Implementation

**Decision**: Time-window comparison using container-local time (24-hour format). Notifications below threshold priority are dropped silently.

**Rationale**: Simple integer comparison of current hour against configured start/end hours. Uses `date +%H%M` for current time. Handles overnight windows (e.g., 22:00-08:00) by checking if start > end.

**Key Details**:
- Config: `quiet_start: "22:00"`, `quiet_end: "08:00"`, `quiet_min_priority: 5`
- Time source: Container-local `date` command
- Overnight handling: If start > end, quiet when (now >= start OR now < end)
- Suppressed notifications: Dropped, not queued (per clarification)

### D-7: Retry Strategy

**Decision**: Exponential backoff with base 2s, max 3 retries, then discard.

**Rationale**: Simple formula: `sleep $((2 ** attempt))` gives waits of 2s, 4s, 8s. Total max wait: 14s. After 3 failures, log and discard per clarification.

**Key Details**:
- Retry delays: 2s, 4s, 8s
- Total max time: ~14s additional latency
- Only retry on: HTTP 429 (rate limited), 5xx (server error), connection timeout
- Don't retry on: 400 (bad payload), 401 (auth failure)
- After exhaustion: Log to stderr with timestamp, exit 0 (don't block agent)

## Technology Summary

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Script language | Bash | 5.x | Wrapper script and sanitization |
| HTTP client | curl | (in base image) | Outbound HTTP POST calls |
| JSON processing | jq | (in base image) | Slack payload formatting (optional) |
| Config format | YAML | N/A | notify.yaml service configuration |
| YAML parsing | grep/sed | (built-in) | Simple key-value extraction from YAML |
| Testing | bats-core | 1.13.0 | Unit and integration tests |
| Linting | shellcheck | (apt) | Bash static analysis |
| Formatting | shfmt | (apt/binary) | Bash code formatting |
| Primary service | ntfy.sh | API v1 | Push notification delivery |
| Secondary service | Slack | Webhooks API | Alternative notification channel |
