# 015-prd-mobile-access

## Problem Statement

Developers want to monitor and interact with AI coding agents from mobile devices—checking
progress on long-running tasks, receiving notifications when agents complete work or need
input, and potentially triggering new tasks remotely. The containerized development
environment should support mobile access without compromising security.

**Critical constraint**: Mobile access must work with the containerized environment and not
require exposing the development container directly to the internet. Notifications and
monitoring should work without constant polling.

## Requirements

### Must Have (M)

- [ ] Notifications when AI agents complete tasks
- [ ] Notifications when agents need human input/approval
- [ ] Basic status monitoring (agent running, completed, failed)
- [ ] Secure access (no direct container exposure)
- [ ] Works with iOS and Android

### Should Have (S)

- [ ] View agent output/logs from mobile
- [ ] Approve/reject agent actions remotely
- [ ] Trigger predefined tasks from mobile
- [ ] Integration with existing notification services (Slack, Discord)
- [ ] Session resume capability
- [ ] Progress indicators for long-running tasks

### Could Have (C)

- [ ] Full terminal access from mobile
- [ ] Code review and approval on mobile
- [ ] Voice commands from mobile
- [ ] Widget for quick status check
- [ ] Multiple project/agent monitoring
- [ ] Custom notification rules

### Won't Have (W)

- [ ] Full IDE functionality on mobile
- [ ] Direct code editing on mobile
- [ ] Real-time streaming of agent activity
- [ ] Proprietary mobile app development (use existing tools)

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Notification reliability | Must | Alerts must arrive promptly |
| Security | Must | No direct container exposure |
| iOS and Android support | Must | Works on both platforms |
| Setup simplicity | High | Easy to configure |
| Integration options | High | Works with existing tools |
| Remote approval | Medium | Can approve agent actions |
| Cost | Medium | Reasonable for individual use |
| Latency | Medium | Notifications within seconds |

## Approach Candidates

| Approach | Type | Pros | Cons | Mobile Support | Spike Result |
|----------|------|------|------|----------------|--------------|
| Slack Integration | Chat Platform | Trigger agents via @mention, notifications, widely used, PWA mobile app | Requires Slack workspace, team tool | iOS, Android | Pending |
| Discord Webhooks | Chat Platform | Free, real-time notifications, mobile app | Less enterprise-friendly | iOS, Android | Pending |
| Ntfy.sh | Push Notifications | Simple, self-hostable, open source, topic-based | Basic functionality | iOS, Android | Pending |
| GitHub Mobile | Platform | Native PR/issue notifications, integrates with CI | Limited to GitHub actions | iOS, Android | Pending |
| Pushover | Push Service | Reliable push, priority levels, quiet hours | Paid service ($5 one-time) | iOS, Android | Pending |
| Custom Webhook + PWA | Self-built | Full control, tailored to needs | Development effort | iOS, Android | Pending |
| SSH App (Termius/Blink) | Terminal | Full terminal access, secure | Small screen, not optimized for monitoring | iOS, Android | Pending |

## Detailed Analysis

### Slack Integration

**Source**: [Cursor Slack Integration](https://cursor.com/), general Slack API

Slack provides comprehensive mobile access:

- **Trigger via @mention**: Tag @Cursor or custom bot to start tasks
- **Notifications**: Real-time alerts to mobile app
- **Threading**: Organize conversations per task
- **Rich messages**: Formatted output, buttons for actions
- **Enterprise ready**: SSO, compliance features

Integration pattern:
```
Container Agent → Webhook → Slack App → Mobile Notification
Mobile @mention → Slack Bot → Webhook → Container Agent
```

### Discord Webhooks

**Source**: [Discord Webhooks](https://discord.com/developers/docs/resources/webhook)

Lightweight notification system:

- **Webhooks**: Simple HTTP POST for notifications
- **Embeds**: Rich message formatting
- **Threads**: Organize per-task discussions
- **Free**: No cost for basic usage
- **Mobile app**: Full-featured iOS and Android apps

### Ntfy.sh

**Source**: [Ntfy.sh](https://ntfy.sh/) | [GitHub](https://github.com/binwiederhier/ntfy)

Simple pub/sub notifications:

- **Topic-based**: Subscribe to notification topics
- **Self-hostable**: Run your own server for privacy
- **Open source**: MIT license
- **Simple API**: `curl -d "message" ntfy.sh/topic`
- **Actions**: Support for action buttons

Container integration:
```bash
# Send notification when agent completes
curl -d "Agent completed: feature-xyz" ntfy.sh/my-dev-alerts
```

### GitHub Mobile + Actions

**Source**: [GitHub Mobile](https://github.com/mobile)

Native GitHub integration:

- **PR notifications**: Agent creates PR, get notified
- **Actions status**: CI/CD notifications
- **Issue updates**: Agent updates issues
- **Native app**: Full-featured mobile experience

Limited to GitHub-centric workflows but deeply integrated.

### Pushover

**Source**: [Pushover](https://pushover.net/)

Reliable push notification service:

- **Priority levels**: Quiet, normal, high, emergency
- **Quiet hours**: Don't disturb during off-hours
- **Delivery receipts**: Confirm notification received
- **Simple API**: HTTP POST with API key
- **One-time cost**: $5 per platform

### SSH Terminal Access

**Source**: [Termius](https://termius.com/), [Blink Shell](https://blink.sh/)

Full terminal access from mobile:

- **Complete access**: Full shell, can run any command
- **Secure**: SSH encryption
- **Mosh support**: Better connectivity for mobile
- **Limitation**: Small screen, not optimized for monitoring

## Recommended Architecture

### Notification Flow

```
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│ Container Agent │────▶│ Notification │────▶│ Mobile Device  │
│ (Claude Code,   │     │ Service      │     │ (Slack/Ntfy/   │
│  Cline, etc.)   │     │ (Webhook)    │     │  Pushover)     │
└─────────────────┘     └──────────────┘     └────────────────┘
```

### Trigger Flow (Slack)

```
┌────────────────┐     ┌───────────────┐     ┌─────────────────┐
│ Mobile Device  │────▶│ Slack/Discord │────▶│ Container Agent │
│ (@mention or   │     │ Bot/Webhook   │     │ (Task Queue)    │
│  command)      │     │               │     │                 │
└────────────────┘     └───────────────┘     └─────────────────┘
```

## Selected Approach

[Filled after spike]

## Acceptance Criteria

- [ ] Given agent completion, when task finishes, then mobile notification arrives within 30 seconds
- [ ] Given agent needs approval, when action requires input, then notification includes action context
- [ ] Given Slack integration, when I @mention bot, then agent task is triggered
- [ ] Given long-running task, when I check status on mobile, then current progress is visible
- [ ] Given security requirements, when accessing remotely, then container is not directly exposed
- [ ] Given multiple devices, when notifications are sent, then all registered devices receive them
- [ ] Given quiet hours configured, when agent completes at night, then notification respects settings

## Dependencies

- Requires: 005-prd-terminal-ai-agent, 006-prd-agentic-assistant (agents to monitor)
- Blocks: none (enhancement feature)

## Spike Tasks

### Notification Setup

- [ ] Configure Slack webhook notifications from container
- [ ] Test ntfy.sh for simple push notifications
- [ ] Evaluate Pushover for reliability
- [ ] Set up Discord webhook as alternative

### Agent Integration

- [ ] Add notification hooks to Claude Code workflows
- [ ] Add notification hooks to Cline workflows
- [ ] Implement notification on task completion
- [ ] Implement notification on approval required

### Remote Trigger

- [ ] Set up Slack bot for @mention triggers
- [ ] Create predefined task templates for remote trigger
- [ ] Implement secure webhook endpoint in container
- [ ] Test end-to-end trigger flow

### Security

- [ ] Implement authentication for webhooks
- [ ] Set up secure tunnel for remote access (if needed)
- [ ] Document security best practices
- [ ] Test access controls

### Mobile Experience

- [ ] Test notification reliability on iOS
- [ ] Test notification reliability on Android
- [ ] Configure notification priorities
- [ ] Set up quiet hours and preferences

## References

- [Cursor Slack Integration](https://cursor.com/)
- [Ntfy.sh Documentation](https://docs.ntfy.sh/)
- [Discord Webhooks](https://discord.com/developers/docs/resources/webhook)
- [Pushover API](https://pushover.net/api)
- [GitHub Mobile](https://github.com/mobile)
- [Termius](https://termius.com/)
- [Mobile AI Agents Research](https://research.aimultiple.com/mobile-ai-agent/)
