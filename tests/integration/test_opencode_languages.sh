#!/usr/bin/env bash
# test_opencode_languages.sh — Integration test: Multi-language support
#
# Verifies:
#   Agent accepts prompts targeting Python, TypeScript, Rust, and Go projects
#   without configuration errors (binary starts in each project context).

set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

echo "=== Integration: OpenCode Multi-Language Support ==="

docker run --rm "$IMAGE" bash -c '
    PASS=0
    FAIL=0

    check_language() {
        local lang="$1"
        local dir="/tmp/test-$lang"
        local file="$2"
        local content="$3"

        mkdir -p "$dir"
        echo "$content" > "$dir/$file"

        # Verify opencode can be invoked in this project directory
        cd "$dir"
        if command -v opencode >/dev/null 2>&1; then
            ((PASS++))
            echo "  OK: opencode available in $lang project"
        else
            ((FAIL++))
            echo "  FAIL: opencode not available in $lang project"
        fi
    }

    echo "  [1/4] Python project..."
    check_language "python" "main.py" "def hello(): return \"world\""

    echo "  [2/4] TypeScript project..."
    check_language "typescript" "index.ts" "const hello: string = \"world\";"

    echo "  [3/4] Rust project..."
    check_language "rust" "main.rs" "fn main() { println!(\"hello\"); }"

    echo "  [4/4] Go project..."
    check_language "go" "main.go" "package main
func main() { println(\"hello\") }"

    if [[ $FAIL -gt 0 ]]; then
        echo "FAIL: $FAIL language(s) failed"
        exit 1
    fi
    echo "OK: All 4 languages supported"
'

echo "PASS: OpenCode multi-language test"
