#!/usr/bin/env bash
# test_opencode_install.sh — Integration test: OpenCode binary installation
#
# Verifies:
#   1. Binary exists at /usr/local/bin/opencode
#   2. Binary is executable
#   3. Binary returns version information
#   4. Binary matches container architecture

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Integration: OpenCode Install Verification ==="

# Test 1: Binary exists
echo "  [1/4] Checking binary exists..."
docker run --rm "$IMAGE" test -f /usr/local/bin/opencode

# Test 2: Binary is executable
echo "  [2/4] Checking binary is executable..."
docker run --rm "$IMAGE" test -x /usr/local/bin/opencode

# Test 3: Binary returns version
echo "  [3/4] Checking version output..."
VERSION_OUTPUT=$(docker run --rm "$IMAGE" /usr/local/bin/opencode --version 2>&1 || true)
if [[ -z "$VERSION_OUTPUT" ]]; then
    echo "FAIL: No version output from opencode --version"
    exit 1
fi
echo "      Version: $VERSION_OUTPUT"

# Test 4: Binary matches architecture
echo "  [4/4] Checking architecture match..."
CONTAINER_ARCH=$(docker run --rm "$IMAGE" dpkg --print-architecture)
FILE_INFO=$(docker run --rm "$IMAGE" file /usr/local/bin/opencode)

case "$CONTAINER_ARCH" in
    amd64)
        echo "$FILE_INFO" | grep -qi "x86-64\|x86_64\|amd64" || {
            echo "FAIL: Binary architecture mismatch (expected amd64)"
            echo "      file output: $FILE_INFO"
            exit 1
        }
        ;;
    arm64)
        echo "$FILE_INFO" | grep -qi "aarch64\|arm64" || {
            echo "FAIL: Binary architecture mismatch (expected arm64)"
            echo "      file output: $FILE_INFO"
            exit 1
        }
        ;;
    *)
        echo "FAIL: Unexpected architecture: $CONTAINER_ARCH"
        exit 1
        ;;
esac

# Test 5: Session directory has correct permissions
echo "  [5/5] Checking session directory permissions..."
SESSION_DIR_PERMS=$(docker run --rm "$IMAGE" stat -c %a /root/.local/share/opencode/sessions 2>/dev/null || \
    docker run --rm "$IMAGE" stat -f %Lp /root/.local/share/opencode/sessions 2>/dev/null || echo "MISSING")
if [[ "$SESSION_DIR_PERMS" == "MISSING" ]]; then
    echo "FAIL: Session directory does not exist"
    exit 1
fi
if [[ "$SESSION_DIR_PERMS" != "700" ]]; then
    echo "FAIL: Session directory permissions are $SESSION_DIR_PERMS (expected 700)"
    exit 1
fi

echo "PASS: OpenCode install verification ($CONTAINER_ARCH)"
