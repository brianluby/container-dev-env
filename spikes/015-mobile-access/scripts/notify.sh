#!/bin/bash
# Mobile Access Notification Script
# Sends notifications to various platforms for AI agent status updates
#
# Usage:
#   ./notify.sh <platform> <message> [title] [priority]
#
# Platforms: ntfy, discord, slack, pushover
# Priority: low, normal, high, urgent (ntfy/pushover)
#
# Environment Variables Required:
#   NTFY_TOPIC        - ntfy.sh topic name (e.g., "my-dev-alerts")
#   NTFY_SERVER       - ntfy server URL (default: https://ntfy.sh)
#   DISCORD_WEBHOOK   - Discord webhook URL
#   SLACK_WEBHOOK     - Slack webhook URL
#   PUSHOVER_TOKEN    - Pushover application token
#   PUSHOVER_USER     - Pushover user key

set -e

PLATFORM="${1:-ntfy}"
MESSAGE="${2:-Agent notification}"
TITLE="${3:-AI Agent}"
PRIORITY="${4:-normal}"

# Map priority to platform-specific values
map_priority_ntfy() {
    case "$1" in
        low)    echo "2" ;;
        normal) echo "3" ;;
        high)   echo "4" ;;
        urgent) echo "5" ;;
        *)      echo "3" ;;
    esac
}

map_priority_pushover() {
    case "$1" in
        low)    echo "-1" ;;
        normal) echo "0" ;;
        high)   echo "1" ;;
        urgent) echo "2" ;;
        *)      echo "0" ;;
    esac
}

# Send notification via ntfy.sh
send_ntfy() {
    local server="${NTFY_SERVER:-https://ntfy.sh}"
    local topic="${NTFY_TOPIC:-dev-alerts}"
    local priority=$(map_priority_ntfy "$PRIORITY")

    curl -s -o /dev/null -w "%{http_code}" \
        -H "Title: $TITLE" \
        -H "Priority: $priority" \
        -H "Tags: robot" \
        -d "$MESSAGE" \
        "$server/$topic"
}

# Send notification via Discord webhook
send_discord() {
    if [ -z "$DISCORD_WEBHOOK" ]; then
        echo "Error: DISCORD_WEBHOOK not set" >&2
        return 1
    fi

    local color
    case "$PRIORITY" in
        low)    color="8421504" ;;  # Gray
        normal) color="3447003" ;;  # Blue
        high)   color="15105570" ;; # Orange
        urgent) color="15158332" ;; # Red
        *)      color="3447003" ;;
    esac

    curl -s -o /dev/null -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "{
            \"embeds\": [{
                \"title\": \"$TITLE\",
                \"description\": \"$MESSAGE\",
                \"color\": $color,
                \"footer\": {\"text\": \"Container Dev Env\"}
            }]
        }" \
        "$DISCORD_WEBHOOK"
}

# Send notification via Slack webhook
send_slack() {
    if [ -z "$SLACK_WEBHOOK" ]; then
        echo "Error: SLACK_WEBHOOK not set" >&2
        return 1
    fi

    local emoji
    case "$PRIORITY" in
        low)    emoji=":information_source:" ;;
        normal) emoji=":robot_face:" ;;
        high)   emoji=":warning:" ;;
        urgent) emoji=":rotating_light:" ;;
        *)      emoji=":robot_face:" ;;
    esac

    curl -s -o /dev/null -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "{
            \"blocks\": [
                {
                    \"type\": \"header\",
                    \"text\": {\"type\": \"plain_text\", \"text\": \"$emoji $TITLE\"}
                },
                {
                    \"type\": \"section\",
                    \"text\": {\"type\": \"mrkdwn\", \"text\": \"$MESSAGE\"}
                }
            ]
        }" \
        "$SLACK_WEBHOOK"
}

# Send notification via Pushover
send_pushover() {
    if [ -z "$PUSHOVER_TOKEN" ] || [ -z "$PUSHOVER_USER" ]; then
        echo "Error: PUSHOVER_TOKEN and PUSHOVER_USER must be set" >&2
        return 1
    fi

    local priority=$(map_priority_pushover "$PRIORITY")

    curl -s -o /dev/null -w "%{http_code}" \
        -F "token=$PUSHOVER_TOKEN" \
        -F "user=$PUSHOVER_USER" \
        -F "title=$TITLE" \
        -F "message=$MESSAGE" \
        -F "priority=$priority" \
        https://api.pushover.net/1/messages.json
}

# Main dispatch
case "$PLATFORM" in
    ntfy)
        result=$(send_ntfy)
        ;;
    discord)
        result=$(send_discord)
        ;;
    slack)
        result=$(send_slack)
        ;;
    pushover)
        result=$(send_pushover)
        ;;
    all)
        # Send to all configured platforms
        [ -n "$NTFY_TOPIC" ] && send_ntfy
        [ -n "$DISCORD_WEBHOOK" ] && send_discord
        [ -n "$SLACK_WEBHOOK" ] && send_slack
        [ -n "$PUSHOVER_TOKEN" ] && send_pushover
        result="200"
        ;;
    *)
        echo "Unknown platform: $PLATFORM" >&2
        echo "Usage: $0 <ntfy|discord|slack|pushover|all> <message> [title] [priority]" >&2
        exit 1
        ;;
esac

if [ "$result" = "200" ] || [ "$result" = "204" ]; then
    echo "Notification sent successfully via $PLATFORM"
    exit 0
else
    echo "Failed to send notification via $PLATFORM (HTTP $result)" >&2
    exit 1
fi
