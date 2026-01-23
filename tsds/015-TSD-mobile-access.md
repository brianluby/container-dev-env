# Technical Specification Document: 015-mobile-access

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/015-mobile-access/` and `prds/015-prd-mobile-access.md`

## 1. Executive Summary

This document specifies the Mobile Access architecture, prioritizing **Push Notifications** (Outbound) over direct remote control (Inbound) for security. **ntfy.sh** is the selected provider due to its zero-setup, open-source nature.

## 2. Technical Specifications

### 2.1 Notification Provider
*   **Service**: `ntfy.sh` (Public or Self-Hosted).
*   **Protocol**: HTTP POST.
*   **Topic**: `devenv-{random_uuid}` (generated at setup).

### 2.2 Client Script
*   **Script**: `scripts/notify.sh`
*   **Usage**: `notify.sh "Task Complete" "Unit tests passed." --priority high`

## 3. Data Models

### 3.1 Notification Payload
```json
{
  "topic": "devenv-xyz",
  "message": "Build failed",
  "title": "Agent Alert",
  "tags": ["warning", "cd"],
  "priority": 4,
  "click": "https://github.com/myrepo/actions/1"
}
```

## 4. API Contracts & Interfaces

### 4.1 CLI Interface
*   `--priority`: Maps to ntfy priorities (1-5).
*   `--tags`: Maps to emojis/tags.

## 5. Architectural Improvements

### 5.1 Rate Limiting (P2 Priority)
**Problem**: An infinite loop in an agent could spam the phone.
**Solution**: `notify.sh` implements a local lockfile/token bucket.
*   **Limit**: Max 1 notification per minute, 10 per hour.

### 5.2 Deep Linking
**Optimization**: Include a `click` URL in the payload pointing to the GitHub PR or Issue, allowing immediate context switching on mobile.

## 6. Testing Strategy
*   **Delivery Test**: Run `notify.sh test` and verify mobile vibration within 5 seconds.
*   **Rate Limit Test**: Run `notify.sh` in a loop; verify only the first few go through.
