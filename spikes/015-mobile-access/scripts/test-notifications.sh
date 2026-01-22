#!/bin/bash
# Test Mobile Notification Systems
#
# This script tests various notification platforms to verify connectivity
# and mobile delivery.
#
# Usage:
#   ./test-notifications.sh [platform]
#
# Platforms: ntfy, discord, slack, pushover, all
#
# Set environment variables before running:
#   export NTFY_TOPIC="your-topic"
#   export DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
#   export SLACK_WEBHOOK="https://hooks.slack.com/services/..."
#   export PUSHOVER_TOKEN="..."
#   export PUSHOVER_USER="..."

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify.sh"
PLATFORM="${1:-all}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL++)); }
skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; ((SKIP++)); }

echo "=========================================="
echo "Mobile Notification System Tests"
echo "=========================================="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Test ntfy.sh
test_ntfy() {
    echo "--- Testing ntfy.sh ---"

    if [ -z "$NTFY_TOPIC" ]; then
        skip "ntfy: NTFY_TOPIC not set"
        return
    fi

    local server="${NTFY_SERVER:-https://ntfy.sh}"
    echo "Server: $server"
    echo "Topic: $NTFY_TOPIC"

    # Test notification with all priority levels
    for priority in low normal high urgent; do
        result=$("$NOTIFY_SCRIPT" ntfy "Test notification ($priority priority)" "Spike Test" "$priority" 2>&1)
        if echo "$result" | grep -q "successfully"; then
            pass "ntfy: $priority priority notification sent"
        else
            fail "ntfy: $priority priority notification failed - $result"
        fi
    done

    echo ""
}

# Test Discord webhook
test_discord() {
    echo "--- Testing Discord Webhook ---"

    if [ -z "$DISCORD_WEBHOOK" ]; then
        skip "Discord: DISCORD_WEBHOOK not set"
        return
    fi

    echo "Webhook configured: yes (URL hidden for security)"

    for priority in low normal high urgent; do
        result=$("$NOTIFY_SCRIPT" discord "Test notification ($priority priority)" "Spike Test" "$priority" 2>&1)
        if echo "$result" | grep -q "successfully"; then
            pass "Discord: $priority priority notification sent"
        else
            fail "Discord: $priority priority notification failed - $result"
        fi
        sleep 1  # Rate limiting
    done

    echo ""
}

# Test Slack webhook
test_slack() {
    echo "--- Testing Slack Webhook ---"

    if [ -z "$SLACK_WEBHOOK" ]; then
        skip "Slack: SLACK_WEBHOOK not set"
        return
    fi

    echo "Webhook configured: yes (URL hidden for security)"

    for priority in low normal high urgent; do
        result=$("$NOTIFY_SCRIPT" slack "Test notification ($priority priority)" "Spike Test" "$priority" 2>&1)
        if echo "$result" | grep -q "successfully"; then
            pass "Slack: $priority priority notification sent"
        else
            fail "Slack: $priority priority notification failed - $result"
        fi
        sleep 1  # Rate limiting
    done

    echo ""
}

# Test Pushover
test_pushover() {
    echo "--- Testing Pushover ---"

    if [ -z "$PUSHOVER_TOKEN" ] || [ -z "$PUSHOVER_USER" ]; then
        skip "Pushover: PUSHOVER_TOKEN and/or PUSHOVER_USER not set"
        return
    fi

    echo "Token configured: yes"
    echo "User configured: yes"

    for priority in low normal high urgent; do
        result=$("$NOTIFY_SCRIPT" pushover "Test notification ($priority priority)" "Spike Test" "$priority" 2>&1)
        if echo "$result" | grep -q "successfully"; then
            pass "Pushover: $priority priority notification sent"
        else
            fail "Pushover: $priority priority notification failed - $result"
        fi
        sleep 1  # Rate limiting
    done

    echo ""
}

# Run tests based on platform argument
case "$PLATFORM" in
    ntfy)
        test_ntfy
        ;;
    discord)
        test_discord
        ;;
    slack)
        test_slack
        ;;
    pushover)
        test_pushover
        ;;
    all)
        test_ntfy
        test_discord
        test_slack
        test_pushover
        ;;
    *)
        echo "Unknown platform: $PLATFORM"
        echo "Usage: $0 [ntfy|discord|slack|pushover|all]"
        exit 1
        ;;
esac

# Summary
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "${GREEN}Passed:${NC} $PASS"
echo -e "${RED}Failed:${NC} $FAIL"
echo -e "${YELLOW}Skipped:${NC} $SKIP"
echo "=========================================="

# Instructions
echo ""
echo "Next Steps:"
echo "1. Check your mobile device for test notifications"
echo "2. Verify notifications arrived within 30 seconds"
echo "3. Test priority levels appear correctly"
echo ""
echo "For ntfy.sh: Download the app from App Store / Play Store"
echo "  and subscribe to topic: ${NTFY_TOPIC:-<your-topic>}"
echo ""
