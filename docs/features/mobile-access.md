# Mobile Access (Notifications)

Mobile notifications let you run long AI tasks and get alerted when they finish.
The implementation uses a notification script inside the container and a push service/app on your phone.

Applies to: `main`

## Prerequisites

- [Getting Started](../getting-started/index.md)
- Internet access from the container (outbound HTTPS)
- A mobile push app/service (example: ntfy)
- Secrets management for notification tokens: [Secrets Management](secrets-management.md)

## Setup

1. Install a push notification client on your phone and create a topic.

Example service (public): `https://ntfy.sh`

2. Configure required environment variables via secrets injection (placeholders):

```env
NTFY_SERVER=https://ntfy.sh
NTFY_TOPIC=example-topic-name
NTFY_TOKEN=EXAMPLE_NTFY_TOKEN_VALUE
```

3. Create the notifier config in the container:

```bash
mkdir -p ~/.config/notify
cat > ~/.config/notify/notify.yaml <<'EOF'
services:
  ntfy:
    enabled: true

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

## Configuration

- `NTFY_*` settings are environment variables (prefer secrets injection for tokens)
- `~/.config/notify/notify.yaml` controls priorities, retries, and quiet hours

## Verification

Send a test notification:

```bash
notify.sh "Hello from container" 3 "Test"
```

## Troubleshooting

- 401 unauthorized: rotate your token and update secrets
- no notification: verify `NTFY_TOPIC` and `NTFY_TOKEN` exist in the container environment

## Related

- [AI Assistants](ai-assistants.md)
- [Secret Rotation](../operations/secret-rotation.md)

## Next steps

- Add a hook from your AI tool to call `notify.sh` on task completion
