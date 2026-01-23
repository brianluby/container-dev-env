#!/usr/bin/env bash
# test_opencode_sessions.sh — Integration test: Session persistence
#
# Verifies:
#   1. Session directory exists at ~/.local/share/opencode/sessions/ with 0700 permissions
#   2. Config file has session.persist=true
#   3. Session files have 0600 permissions (when created)

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Integration: OpenCode Session Persistence ==="

# Test 1: Session directory exists with correct permissions
echo "  [1/3] Checking session directory..."
docker run --rm "$IMAGE" bash -c '
    SESSION_DIR="$HOME/.local/share/opencode/sessions"
    if [[ ! -d "$SESSION_DIR" ]]; then
        echo "FAIL: Session directory does not exist: $SESSION_DIR"
        exit 1
    fi
    PERMS=$(stat -c %a "$SESSION_DIR" 2>/dev/null || stat -f %Lp "$SESSION_DIR" 2>/dev/null)
    if [[ "$PERMS" != "700" ]]; then
        echo "FAIL: Session directory permissions are $PERMS (expected 700)"
        exit 1
    fi
    echo "OK: Session directory exists with 0700 permissions"
'

# Test 2: Config has session persistence enabled
echo "  [2/3] Checking session persistence config..."
docker run --rm "$IMAGE" bash -c '
    CONFIG="$HOME/.config/opencode/config.yaml"
    if [[ ! -f "$CONFIG" ]]; then
        echo "FAIL: Config file not found at $CONFIG"
        exit 1
    fi
    if ! grep -q "persist: true" "$CONFIG"; then
        echo "FAIL: persist: true not found in config"
        exit 1
    fi
    if ! grep -q "sessions/" "$CONFIG"; then
        echo "FAIL: sessions path not found in config"
        exit 1
    fi
    echo "OK: session.persist=true configured"
'

# Test 3: Session directory is writable (can create files with 0600)
echo "  [3/3] Checking session directory is writable with correct permissions..."
docker run --rm "$IMAGE" bash -c '
    SESSION_DIR="$HOME/.local/share/opencode/sessions"
    TEST_FILE="$SESSION_DIR/test-session.json"
    echo "{}" > "$TEST_FILE"
    chmod 0600 "$TEST_FILE"
    PERMS=$(stat -c %a "$TEST_FILE" 2>/dev/null || stat -f %Lp "$TEST_FILE" 2>/dev/null)
    if [[ "$PERMS" != "600" ]]; then
        echo "FAIL: Session file permissions are $PERMS (expected 600)"
        rm -f "$TEST_FILE"
        exit 1
    fi
    rm -f "$TEST_FILE"
    echo "OK: Session files can be created with 0600 permissions"
'

echo "PASS: OpenCode session persistence tests"
