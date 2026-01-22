#!/bin/bash
# Claude Code Hook Integration for Mobile Notifications
#
# This script provides hook functions that can be called by Claude Code
# to send notifications about agent activity.
#
# Usage in Claude Code settings.json:
#   "hooks": {
#     "PostToolUse": ["bash", "/path/to/claude-code-hooks.sh", "post_tool"],
#     "Stop": ["bash", "/path/to/claude-code-hooks.sh", "stop"]
#   }
#
# Environment Variables:
#   MOBILE_NOTIFY_PLATFORM - Platform(s) to notify (ntfy, discord, slack, pushover, all)
#   MOBILE_NOTIFY_ENABLED  - Set to "true" to enable notifications
#   Plus platform-specific env vars (see notify.sh)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify.sh"

# Default platform
PLATFORM="${MOBILE_NOTIFY_PLATFORM:-ntfy}"
ENABLED="${MOBILE_NOTIFY_ENABLED:-false}"

# Check if notifications are enabled
if [ "$ENABLED" != "true" ]; then
    exit 0
fi

# Get hook type from argument
HOOK_TYPE="${1:-unknown}"

# Read stdin for hook data (Claude Code passes JSON)
HOOK_DATA=$(cat)

# Parse hook data (basic parsing - for production use jq)
parse_json_field() {
    echo "$HOOK_DATA" | grep -o "\"$1\":[^,}]*" | sed 's/.*://' | tr -d '"\n '
}

case "$HOOK_TYPE" in
    post_tool)
        # Called after each tool use
        TOOL_NAME=$(parse_json_field "tool_name")
        TOOL_STATUS=$(parse_json_field "status")

        # Only notify on important events
        case "$TOOL_NAME" in
            Bash|Write|Edit)
                # Don't spam notifications for common operations
                ;;
            TodoWrite)
                # Notify on task progress
                "$NOTIFY_SCRIPT" "$PLATFORM" "Task updated" "Claude Code" "low"
                ;;
            AskUserQuestion)
                # High priority - agent needs input
                "$NOTIFY_SCRIPT" "$PLATFORM" "Agent requires your input" "Action Required" "high"
                ;;
            *)
                # Other tools - log but don't notify by default
                ;;
        esac
        ;;

    stop)
        # Called when agent stops
        REASON=$(parse_json_field "reason")

        case "$REASON" in
            completed|success)
                "$NOTIFY_SCRIPT" "$PLATFORM" "Agent completed task successfully" "Task Complete" "normal"
                ;;
            error|failed)
                "$NOTIFY_SCRIPT" "$PLATFORM" "Agent encountered an error and stopped" "Task Failed" "high"
                ;;
            user_interrupt)
                "$NOTIFY_SCRIPT" "$PLATFORM" "Agent was stopped by user" "Task Interrupted" "low"
                ;;
            needs_input)
                "$NOTIFY_SCRIPT" "$PLATFORM" "Agent needs your approval to continue" "Input Required" "urgent"
                ;;
            *)
                "$NOTIFY_SCRIPT" "$PLATFORM" "Agent stopped: $REASON" "Agent Status" "normal"
                ;;
        esac
        ;;

    start)
        # Called when agent starts (custom trigger)
        TASK=$(parse_json_field "task")
        "$NOTIFY_SCRIPT" "$PLATFORM" "Agent started: $TASK" "Task Started" "low"
        ;;

    approval_required)
        # Called when agent needs approval (custom trigger)
        ACTION=$(parse_json_field "action")
        "$NOTIFY_SCRIPT" "$PLATFORM" "Agent needs approval for: $ACTION" "Approval Required" "urgent"
        ;;

    progress)
        # Called for progress updates (custom trigger)
        PROGRESS=$(parse_json_field "progress")
        TOTAL=$(parse_json_field "total")
        "$NOTIFY_SCRIPT" "$PLATFORM" "Progress: $PROGRESS/$TOTAL" "Task Progress" "low"
        ;;

    *)
        # Unknown hook type
        echo "Unknown hook type: $HOOK_TYPE" >&2
        ;;
esac

exit 0
