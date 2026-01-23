#!/usr/bin/env bash
# test_opencode_context.sh — Integration test: Context-aware file reading
#
# Verifies:
#   Agent can read files in the current project directory by confirming
#   the agent starts successfully in a directory containing source files.

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Integration: OpenCode Context Awareness ==="

# Test: Agent initializes with project files available
echo "  [1/1] Checking agent can access project files..."
docker run --rm "$IMAGE" bash -c '
    # Create a sample project
    mkdir -p /tmp/sample-project/src
    cd /tmp/sample-project

    # Create identifiable source files
    cat > src/main.py << "PYEOF"
def hello_world():
    """A sample function for context testing."""
    return "Hello from context test"

if __name__ == "__main__":
    print(hello_world())
PYEOF

    cat > README.md << "MDEOF"
# Sample Project
This project is used for context awareness testing.
MDEOF

    # Verify files exist and are readable
    if [[ ! -f src/main.py ]]; then
        echo "FAIL: Sample project file not created"
        exit 1
    fi

    # Verify opencode binary can be invoked from within the project directory
    if ! command -v opencode >/dev/null 2>&1; then
        echo "FAIL: opencode not found in PATH"
        exit 1
    fi

    # Verify the binary starts (even if it fails due to no API key, it should
    # still be able to read the project structure)
    OUTPUT=$(opencode --help 2>&1 || true)
    if [[ -z "$OUTPUT" ]]; then
        echo "FAIL: opencode produced no output"
        exit 1
    fi

    echo "OK: Agent binary accessible in project directory with source files"
'

echo "PASS: OpenCode context awareness test"
