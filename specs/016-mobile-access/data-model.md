# Data Model: Mobile Push Notifications

**Feature**: 016-mobile-access | **Date**: 2026-01-23

## Entities

### NotificationEvent

Represents an occurrence from an AI agent that triggers a notification.

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| type | enum | yes | One of: `completed`, `failed`, `approval_needed`, `progress` | Event category |
| agent_name | string | no | Max 50 chars, alphanumeric + hyphens | Source AI agent identifier (reserved for future multi-agent support; not exposed in CLI v1) |
| message | string | yes | Max 200 chars (after sanitization) | Human-readable event summary |
| priority | integer | no | 1-5 (default: 3) | Mapped from event type if not explicit |
| title | string | no | Max 50 chars | Notification title/subject |
| timestamp | string | yes | ISO 8601 or Unix epoch | When event occurred |

**Priority Mapping** (default, configurable in notify.yaml):

| Event Type | Default Priority | Level Name |
|------------|-----------------|------------|
| progress | 2 | low |
| completed | 3 | default |
| failed | 4 | high |
| approval_needed | 5 | urgent |

### NotificationService

Represents an external delivery platform configuration.

| Field | Type | Required | Source | Description |
|-------|------|----------|--------|-------------|
| name | enum | yes | notify.yaml | One of: `ntfy`, `slack` |
| enabled | boolean | yes | notify.yaml | Whether service is active |
| server_url | string | conditional | env var (`NTFY_SERVER`) | Base URL (ntfy only, default: `https://ntfy.sh`) |
| topic | string | conditional | env var (`NTFY_TOPIC`) | Topic name (ntfy only) |
| access_token | string | conditional | env var (`NTFY_TOKEN`) | Bearer token (ntfy only) |
| webhook_url | string | conditional | env var (`SLACK_WEBHOOK`) | Webhook endpoint (Slack only) |

**Validation Rules**:
- If `enabled: true`, the corresponding env vars MUST be set
- `server_url` MUST start with `https://`
- `topic` MUST be non-empty alphanumeric string
- `access_token` MUST be non-empty when ntfy auth is configured

### QuietHours

Time window during which low-priority notifications are dropped.

| Field | Type | Required | Source | Description |
|-------|------|----------|--------|-------------|
| enabled | boolean | yes | notify.yaml | Whether quiet hours are active |
| start | string | conditional | notify.yaml | Start time in HH:MM format (24h) |
| end | string | conditional | notify.yaml | End time in HH:MM format (24h) |
| min_priority | integer | no | notify.yaml | Minimum priority to pass through (default: 5) |

**State Logic**:
- If `start > end` (overnight): quiet when `now >= start OR now < end`
- If `start < end` (same day): quiet when `now >= start AND now < end`
- Suppressed notifications are **dropped** (not queued)

### ContentSanitizer

Processing rules applied to notification messages before sending.

| Rule | Pattern | Action | Order |
|------|---------|--------|-------|
| File paths | `/[a-zA-Z0-9_/.~-]+` | Strip match | 1 |
| API keys | `sk-[a-zA-Z0-9]+`, `[A-Z0-9]{20,}`, `tk_[a-z0-9]+` | Strip match | 2 |
| Env var assignments | `[A-Z_]+=\S+` | Strip match | 3 |
| Code patterns | Lines with `{`, `}`, `;`, `function `, `class `, `import ` | Strip line | 4 |
| Whitespace | Multiple spaces/newlines | Collapse to single space | 5 |
| Length | >200 chars | Truncate to 200 chars | 6 |

## Configuration File Schema

### notify.yaml

```yaml
# Notification services configuration
services:
  ntfy:
    enabled: true           # boolean, required
    # server_url from env: NTFY_SERVER (default: https://ntfy.sh)
    # topic from env: NTFY_TOPIC
    # access_token from env: NTFY_TOKEN

  slack:
    enabled: false          # boolean, required
    # webhook_url from env: SLACK_WEBHOOK

# Priority mapping (event_type -> priority level 1-5)
priorities:
  progress: 2
  completed: 3
  failed: 4
  approval_needed: 5

# Quiet hours configuration
quiet_hours:
  enabled: false            # boolean, required
  start: "22:00"           # HH:MM format
  end: "08:00"             # HH:MM format
  min_priority: 5          # 1-5, notifications >= this priority bypass quiet hours

# Retry configuration
retry:
  max_attempts: 3          # integer, 1-10
  base_delay: 2            # seconds, exponential backoff base
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NTFY_SERVER` | no | `https://ntfy.sh` | ntfy.sh server base URL |
| `NTFY_TOPIC` | if ntfy enabled | — | Topic name for publishing |
| `NTFY_TOKEN` | if ntfy enabled | — | Bearer access token |
| `SLACK_WEBHOOK` | if slack enabled | — | Slack incoming webhook URL |

## Relationships

```text
NotificationEvent ──triggers──> notify.sh
notify.sh ──reads──> notify.yaml (config)
notify.sh ──reads──> Environment Variables (secrets)
notify.sh ──applies──> ContentSanitizer (processing)
notify.sh ──checks──> QuietHours (gating)
notify.sh ──sends to──> NotificationService[ntfy] (delivery)
notify.sh ──sends to──> NotificationService[slack] (delivery)
```

## State Transitions

### Notification Lifecycle

```text
[Event Received] → [Sanitize Content] → [Check Quiet Hours]
                                              │
                                    ┌─────────┴─────────┐
                                    │                     │
                              [Suppressed]          [Send to Services]
                              (dropped)                   │
                                                ┌─────────┴─────────┐
                                                │                     │
                                          [Success]            [Retry (1-3)]
                                          (log, exit 0)              │
                                                              ┌──────┴──────┐
                                                              │              │
                                                        [Success]      [Exhausted]
                                                        (log, exit 0)  (log, discard, exit 0)
```

Note: notify.sh always exits 0 to avoid blocking the calling AI agent hook. Failures are logged to stderr.
