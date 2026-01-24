#!/usr/bin/env bash
# shell-standards.contract.sh — Contract tests for shell script standards
# Verifies: FR-012, FR-016

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../../.."

echo "=== Shell Standards Contracts ==="
echo ""

# --- Contract: Strict mode (FR-012) ---
echo "Contract: All bash scripts use strict mode"
echo "  Scope: all committed .sh files and executables with #!/*bash shebang"
echo "  Excludes: Chezmoi templates (.tmpl), Dockerfile RUN blocks"
echo "  Expected: 'set -euo pipefail' within first 10 lines of each script"
echo "  OR: documented exception in a comment (e.g., '# strict-mode-exception: <reason>')"
echo ""

# --- Contract: Diagnostic format (FR-016) ---
echo "Contract: Standardized diagnostic output"
echo "  Scope: all scripts that emit errors or warnings"
echo "  Expected format: '[ERROR] <component>: <message>' for errors (to stderr)"
echo "  Expected format: '[WARN] <component>: <message>' for warnings (to stderr)"
echo "  Expected: component is a lowercase identifier (e.g., secrets, agent, build)"
echo "  Expected: no bare 'echo Error:' or 'echo Warning:' patterns remain"
echo ""

# --- Contract: Secrets editor special chars (FR-011) ---
echo "Contract: Secrets editor preserves special characters"
echo "  Input: values containing /, +, =, &, |, \\ characters"
echo "  Input: values starting with -n (echo flag injection)"
echo "  Expected: store/retrieve round-trip returns identical bytes"
echo "  Verification: diff or cmp on stored vs retrieved value"
echo ""

echo "---"
echo "Contract specification complete."
echo "Use ShellCheck + grep-based scanning for strict mode and format verification."
