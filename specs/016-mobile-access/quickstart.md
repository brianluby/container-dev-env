# Quickstart: Mobile Push Notifications

**Feature**: 016-mobile-access | **Goal**: First notification on your phone in under 15 minutes

## Prerequisites

- Container dev environment running (per 001-container-base-image)
- iOS or Android device
- Internet access from container (outbound HTTPS)

## Step 1: Set Up ntfy.sh (Mobile App)

1. Install the ntfy app on your phone:
   - **iOS**: [App Store](https://apps.apple.com/app/ntfy/id1625396347)
   - **Android**: [Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy) or [F-Droid](https://f-droid.org/packages/io.heckel.ntfy/)

2. Create an account at https://ntfy.sh (or your self-hosted instance)

3. Create a topic and generate an access token:
   - Go to Account → Access Tokens → Create Token
   - Subscribe to your topic in the mobile app

## Step 2: Configure Environment Variables

Add to your container's secret injection (per 003-secret-injection):

```bash
export NTFY_SERVER="https://ntfy.sh"        # Or your self-hosted URL
export NTFY_TOPIC="your-unique-topic-name"
export NTFY_TOKEN="tk_your_access_token_here"
```

## Step 3: Create notify.yaml

```bash
mkdir -p ~/.config/notify
cat > ~/.config/notify/notify.yaml << 'EOF'
services:
  ntfy:
    enabled: true
  slack:
    enabled: false

priorities:
  progress: 2
  completed: 3
  failed: 4
  approval_needed: 5

quiet_hours:
  enabled: false
  start: "22:00"
  end: "08:00"
  min_priority: 5

retry:
  max_attempts: 3
  base_delay: 2
EOF
```

## Step 4: Test Notification

```bash
# Send a test notification
notify.sh "Hello from container!" 3 "Test"
```

Check your phone — you should see the notification within seconds.

## Step 5: Configure Claude Code Hook

Add to `.claude/settings.local.json` in your project:

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

## Step 6: Verify End-to-End

1. Start a Claude Code task (e.g., "explain this file")
2. Wait for task completion
3. Verify notification arrives on your phone

## Optional: Add Slack

```bash
export SLACK_WEBHOOK="https://hooks.slack.com/services/T.../B.../XXX"
```

Update notify.yaml:
```yaml
services:
  ntfy:
    enabled: true
  slack:
    enabled: true
```

## Troubleshooting

| Symptom | Check |
|---------|-------|
| No notification received | Verify `NTFY_TOPIC` and `NTFY_TOKEN` are set: `echo $NTFY_TOPIC` |
| 401 Unauthorized in logs | Token expired or wrong — regenerate at ntfy.sh |
| Notification delayed | Check if quiet hours are active in notify.yaml |
| "Configuration Error" exit | Run `cat ~/.config/notify/notify.yaml` to verify format |
| Works manually but not from hook | Check Claude Code hook timeout (should be >= 10s) |

## Development: Running Tests

```bash
# Install bats-core (if not in image)
git clone --branch v1.13.0 https://github.com/bats-core/bats-core.git /tmp/bats && \
  /tmp/bats/install.sh /usr/local && rm -rf /tmp/bats

# Run all tests
bats tests/

# Run unit tests only
bats tests/unit/

# Run with verbose output
bats tests/ --verbose-run
```
