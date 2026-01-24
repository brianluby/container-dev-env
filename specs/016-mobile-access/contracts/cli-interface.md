# CLI Interface Contract: notify.sh

**Feature**: 016-mobile-access | **Date**: 2026-01-23

## Command Signature

```bash
notify.sh <message> [priority] [title]
```

## Parameters

| Position | Name | Type | Required | Default | Description |
|----------|------|------|----------|---------|-------------|
| 1 | message | string | yes | — | Notification body text (sanitized before sending) |
| 2 | priority | integer | no | 3 | Priority level 1-5 |
| 3 | title | string | no | "Agent Notification" | Notification title/subject |

## Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 0 | Success | Notification sent (or suppressed by quiet hours, or discarded after retry exhaustion) |
| 1 | Configuration Error | notify.yaml missing/malformed, or required env vars not set |
| 2 | Invalid Arguments | Missing message argument or invalid priority value |

**Design Note**: Exit 0 for delivery failures (after retries) to avoid blocking AI agent hooks. Failures are logged to stderr.

## Standard Streams

| Stream | Content |
|--------|---------|
| stdout | Nothing (silent on success) |
| stderr | Log messages: timestamps, delivery status, errors, warnings |

## Environment Variables (Required)

| Variable | When Required | Format |
|----------|---------------|--------|
| `NTFY_TOPIC` | ntfy enabled | Alphanumeric string |
| `NTFY_TOKEN` | ntfy enabled | Bearer token (e.g., `tk_...`) |
| `NTFY_SERVER` | optional | URL (default: `https://ntfy.sh`) |
| `SLACK_WEBHOOK` | slack enabled | Full webhook URL |

## Configuration File

**Path**: `~/.config/notify/notify.yaml` (or `$NOTIFY_CONFIG` override)

See data-model.md for full schema.

## Usage Examples

### Basic task completion notification
```bash
notify.sh "Refactoring complete: 12 files updated"
```

### High-priority failure alert
```bash
notify.sh "Build failed: 3 type errors in auth.ts" 4 "Build Failed"
```

### Urgent approval request
```bash
notify.sh "Delete 47 test files? Awaiting approval" 5 "Approval Needed"
```

### Low-priority progress update
```bash
notify.sh "Generating tests: 5/12 complete" 2 "Progress"
```

## HTTP Contracts (Outbound)

### ntfy.sh POST

```http
POST https://<NTFY_SERVER>/<NTFY_TOPIC>
Authorization: Bearer <NTFY_TOKEN>
X-Priority: <1-5>
X-Title: <title>
Content-Type: text/plain

<sanitized message body, max 200 chars>
```

**Expected Responses**:
- `200 OK`: Message published
- `401 Unauthorized`: Bad token (don't retry)
- `429 Too Many Requests`: Rate limited (retry with backoff)
- `5xx`: Server error (retry with backoff)

### Slack Webhook POST

```http
POST <SLACK_WEBHOOK>
Content-Type: application/json

{
  "text": "<priority_emoji> *<title>*\n<sanitized message>"
}
```

**Priority Emoji Mapping**:
- Priority 5: `🔴`
- Priority 4: `🟠`
- Priority 3: `🟢`
- Priority 2: `⬜`
- Priority 1: `⬜`

**Expected Responses**:
- `200 OK`: Message posted
- `400 Bad Request`: Malformed payload (don't retry)
- `429 Too Many Requests`: Rate limited (retry per `Retry-After` header)
- `5xx`: Server error (retry with backoff)

## Retry Behavior

| Attempt | Delay | Condition |
|---------|-------|-----------|
| 1 | 0s | Initial attempt |
| 2 | 2s | After HTTP 429, 5xx, or connection timeout |
| 3 | 4s | After HTTP 429, 5xx, or connection timeout |
| 4 | 8s | After HTTP 429, 5xx, or connection timeout |
| — | — | Log failure to stderr, exit 0 |

**Non-retryable**: HTTP 400, 401 (configuration errors — fail immediately, log, exit 0)
