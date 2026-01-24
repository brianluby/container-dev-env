# Feature Specification: Mobile Push Notifications for AI Agent Events

**Feature Branch**: `016-mobile-access`
**Created**: 2026-01-23
**Status**: Draft
**Input**: PRD 015-prd-mobile-access.md, ARD 015-ard-mobile-access.md, SEC 015-sec-mobile-access.md

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Task Completion Notification (Priority: P1)

A developer starts a long-running AI agent task (code generation, refactoring, test writing) and steps away from their workstation. When the agent finishes, the developer receives a push notification on their mobile device with a brief status summary, allowing them to return and review the results.

**Why this priority**: This is the core value proposition — knowing when work is done without staying at the desk. Without this, developers must periodically check their workstation.

**Independent Test**: Can be fully tested by triggering a notify.sh call with a completion message and verifying it arrives on a subscribed mobile device within 30 seconds.

**Acceptance Scenarios**:

1. **Given** an AI agent is running a task and ntfy.sh is configured, **When** the task completes successfully, **Then** the developer receives a push notification on their mobile device within 30 seconds containing the agent name and task summary.
2. **Given** an AI agent is running a task and ntfy.sh is configured, **When** the task fails, **Then** the developer receives a high-priority push notification indicating failure.
3. **Given** quiet hours are configured and active, **When** a normal-priority task completes, **Then** the notification is dropped silently (not queued).

---

### User Story 2 - Approval-Needed Alert (Priority: P1)

An AI agent reaches a decision point requiring human input (e.g., "Delete these files?", "Deploy to staging?"). The developer receives an urgent push notification on their phone with enough context to understand what's needed, enabling a timely response.

**Why this priority**: Approval-blocked agents waste time waiting. Urgent notifications ensure developers respond promptly even when away from their workstation.

**Independent Test**: Can be fully tested by triggering a notify.sh call with priority 5 (urgent) and verifying it arrives immediately, bypassing quiet hours.

**Acceptance Scenarios**:

1. **Given** an AI agent needs approval, **When** the approval event fires, **Then** a priority-5 (urgent) notification arrives on the mobile device with action context.
2. **Given** quiet hours are active, **When** an approval-needed event fires, **Then** the notification still arrives because priority 5 bypasses quiet hours.

---

### User Story 3 - Multi-Service Delivery (Priority: P2)

A developer configures both ntfy.sh and Slack as notification channels. When an agent event occurs, notifications are delivered to both services simultaneously, providing redundancy and reaching the developer through their preferred channel.

**Why this priority**: Redundancy ensures notifications arrive even if one service is down. Teams using Slack get notifications where they already work.

**Independent Test**: Can be fully tested by configuring both services in notify.yaml, triggering a notification, and verifying delivery on both ntfy.sh mobile app and Slack channel.

**Acceptance Scenarios**:

1. **Given** both ntfy.sh and Slack are enabled in notify.yaml, **When** an agent event fires, **Then** both services receive the notification via HTTP POST.
2. **Given** ntfy.sh is unreachable, **When** an agent event fires, **Then** Slack still receives the notification (services are independent).

---

### User Story 4 - Priority-Based Delivery (Priority: P2)

Different agent events have different urgency levels. A task completion is normal priority, a failure is high priority, and an approval request is urgent. The notification system maps event types to priority levels, and quiet hours configuration respects these levels.

**Why this priority**: Without priority levels, developers either get too many disruptive alerts or miss critical ones. Priority mapping enables smart notification behavior.

**Independent Test**: Can be fully tested by sending notifications at different priority levels and verifying that quiet hours filtering correctly suppresses low-priority but passes urgent notifications.

**Acceptance Scenarios**:

1. **Given** default priority mapping is configured, **When** a "completed" event fires, **Then** the notification is sent with priority 2-3 (normal).
2. **Given** default priority mapping is configured, **When** a "failed" event fires, **Then** the notification is sent with priority 4 (high).
3. **Given** default priority mapping is configured, **When** an "approval_needed" event fires, **Then** the notification is sent with priority 5 (urgent).

---

### User Story 5 - Content Sanitization (Priority: P2)

AI agents may include sensitive information (file paths, code snippets, API keys) in their event output. The notification system strips sensitive content before sending, ensuring only safe status summaries leave the container.

**Why this priority**: Notifications traverse external services (ntfy.sh, Slack). Any sensitive content in notifications is a security exposure. Sanitization is essential for safe operation.

**Independent Test**: Can be fully tested by passing messages containing file paths, API key patterns, and code snippets to notify.sh and verifying the output message has these stripped.

**Acceptance Scenarios**:

1. **Given** a notification message contains a file path like "/home/user/project/src/auth.ts", **When** sanitization runs, **Then** the path is stripped from the message.
2. **Given** a notification message exceeds 200 characters, **When** sanitization runs, **Then** the message is truncated to 200 characters.
3. **Given** a notification message contains an API key pattern, **When** sanitization runs, **Then** the key is removed from the message.

---

### User Story 6 - Quiet Hours Configuration (Priority: P3)

A developer configures quiet hours (e.g., 22:00-08:00) so that routine notifications don't disturb them at night. Only urgent notifications (priority 5) break through during quiet hours.

**Why this priority**: Prevents notification fatigue and respects developer work-life boundaries. Non-urgent alerts can wait until morning.

**Independent Test**: Can be fully tested by setting quiet hours in notify.yaml, sending notifications at various priorities during the quiet period, and verifying only priority-5 messages arrive.

**Acceptance Scenarios**:

1. **Given** quiet hours are 22:00-08:00 and current time is 23:00, **When** a priority-3 notification fires, **Then** it is suppressed.
2. **Given** quiet hours are 22:00-08:00 and current time is 23:00, **When** a priority-5 notification fires, **Then** it is delivered immediately.

---

### Edge Cases

- What happens when both notification services (ntfy.sh and Slack) are unreachable? The script logs the failure and exits gracefully without blocking the AI agent.
- What happens when notify.yaml is missing or malformed? The script fails fast with a clear error message on startup/first use.
- What happens when the notification message is empty? The script sends a default message like "Agent event (no details)".
- What happens when the webhook URL environment variable is not set but the service is enabled? The script skips that service and logs a warning.
- What happens during timezone changes or DST transitions for quiet hours? Quiet hours use local container time; edge cases may deliver or suppress one extra notification.

## Clarifications

### Session 2026-01-23

- Q: How should ntfy.sh topic access be secured? → A: Access token authentication (ntfy.sh token-based auth)
- Q: How do AI agents trigger the notification script? → A: Shell hooks (agents call notify.sh directly via configured post-task hooks)
- Q: What happens to notifications suppressed during quiet hours? → A: Dropped silently (developer checks agent logs on return)
- Q: What happens when all 3 notification retries fail? → A: Log failure and discard (notification is lost)
- Q: Should notify.sh target the public ntfy.sh instance or support custom server URLs? → A: Configurable server URL, defaulting to public ntfy.sh (https://ntfy.sh)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST send outbound HTTP POST notifications to ntfy.sh when AI agent events occur (traces to M-1, M-2)
- **FR-002**: System MUST support priority levels 1-5 for notifications, mapping event types to appropriate priorities (traces to M-2)
- **FR-003**: System MUST NOT expose any inbound ports on the container for mobile access (traces to M-4, SEC-1)
- **FR-004**: System MUST sanitize notification content to remove file paths, code snippets, and API key patterns before sending (traces to SEC-2, SEC-5)
- **FR-005**: System MUST truncate notification messages to a maximum of 200 characters (traces to SEC-4)
- **FR-006**: System MUST support quiet hours configuration that suppresses notifications below a configurable priority threshold (traces to AC-7)
- **FR-007**: System MUST use HTTPS for all outbound notification service calls (traces to SEC-6)
- **FR-008**: System MUST store webhook URLs and API keys in environment variables, not in configuration files (traces to SEC-3)
- **FR-009**: System MUST provide a notify.sh wrapper script with a consistent CLI interface: `notify.sh <message> [priority] [title]` (traces to ARD Component Overview)
- **FR-010**: System MUST support ntfy.sh as the primary notification service with topic-based subscription, authenticated via access tokens stored in environment variables; server URL is configurable (default: https://ntfy.sh) to support self-hosted instances (traces to ARD Selected Option)
- **FR-011**: System SHOULD support Slack webhooks as a secondary notification service (traces to S-4)
- **FR-012**: System SHOULD deliver notifications within 30 seconds of the triggering event (traces to Technical Constraints)
- **FR-013**: System SHOULD retry failed notification deliveries up to 3 times with exponential backoff; after exhaustion, log the failure and discard the notification (traces to ARD Error Handling)
- **FR-014**: System SHOULD log notification send attempts with success/failure status without logging webhook URLs (traces to SEC-7)
- **FR-015**: System SHOULD provide a notify.yaml configuration file template for service enablement and priority mapping (traces to ARD Interface Definitions)

### Key Entities

- **Notification Event**: An occurrence from an AI agent (completion, failure, approval_needed, progress) that triggers a notification. Has attributes: type, agent name, task summary, priority, timestamp.
- **Notification Service**: An external platform that delivers push notifications to mobile devices (ntfy.sh, Slack). Has attributes: enabled state, endpoint URL, authentication method (ntfy.sh uses access token auth via Authorization header).
- **Priority Level**: A 1-5 scale indicating notification urgency. Maps event types to delivery behavior: 1=min, 2=low, 3=default, 4=high, 5=urgent.
- **Quiet Hours**: A configured time window during which only notifications above a priority threshold are delivered; suppressed notifications are dropped (not queued). Has attributes: start time, end time, minimum priority to pass through.
- **Content Sanitizer**: A processing step that strips sensitive data (paths, keys, code) and truncates messages before they leave the container.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Notifications arrive on mobile device within 30 seconds of AI agent event firing
- **SC-002**: Notification delivery rate exceeds 99% when services are reachable
- **SC-003**: Zero inbound ports exposed on the container (verified by network scan)
- **SC-004**: No file paths, API keys, or code snippets appear in any delivered notification (verified by content audit)
- **SC-005**: Quiet hours correctly suppress all notifications below the configured priority threshold
- **SC-006**: Both iOS and Android devices receive notifications via ntfy.sh mobile app
- **SC-007**: Webhook URLs and secrets never appear in log output or configuration files committed to git
- **SC-008**: notify.sh setup and first notification delivery achievable within 15 minutes from documentation

## Assumptions

- [A-1] Developers have iOS or Android devices with ntfy.sh app installed
- [A-2] Outbound HTTP/HTTPS from the container is permitted by network configuration
- [A-3] AI agents (Claude Code, Cline) invoke notify.sh directly via their configured post-task shell hooks (e.g., Claude Code hooks config, Cline task completion callbacks)
- [A-4] curl is available in the container (already in base image per 001-container-base-image)
- [A-5] Mobile notifications are supplementary monitoring, not the primary interaction method

## Dependencies

- **005-terminal-ai-agent**: Provides AI agents whose events trigger notifications
- **006-agentic-assistant**: Provides additional AI agent configurations to hook into
- **001-container-base-image**: Provides curl in the base image for HTTP calls
- **External: ntfy.sh**: Push notification delivery service (free, self-hostable)
- **External: Slack API**: Webhook-based notification delivery (optional secondary)

## Constraints

- Outbound-only architecture: no inbound network connections to the container
- Message length limited to 200 characters (ntfy.sh practical limit)
- Notification content restricted to status summaries only — no source code, secrets, or internal paths
- Quiet hours use container-local time (no timezone coordination)
- No custom mobile app development — use existing ntfy.sh and Slack mobile apps
- jq is optional (used for JSON formatting in Slack payloads); curl is required
