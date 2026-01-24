# Gemini CLI Code Review (2026-01-23)

**Component**: Agent Web Service (`src/agent/`)
**Reviewer**: Gemini CLI
**Date**: 2026-01-23

## Executive Summary

The Agent Service (`src/agent/`) demonstrates a strong foundation with good modularity and adherence to shell scripting standards (strict mode, clear separation of concerns). However, **Critical** security vulnerabilities related to injection attacks (JSON and Command Injection) were identified. Addressing these is the highest priority. Performance for session management will degrade with usage and requires optimization.

## Detailed Findings

### 1. Security Vulnerabilities (CRITICAL)

#### A. JSON Injection in Logging
- **Severity**: **Critical**
- **Location**: `src/agent/lib/log.sh` (Function: `log_action`)
- **Issue**: The `log_action` function constructs JSON manually using `printf` without escaping user input in the `target` and `details` fields.
- **Impact**: An attacker or malformed input containing double quotes (`"`) or newlines can break the JSON structure. This allows for log integrity violations (injecting fake entries) and will crash downstream tools that expect valid JSON (e.g., the web UI).
- **Example**: A task description like `Review "Project"` results in invalid JSON: `{"details": "Review "Project""}`.

#### B. Command Injection in Task Execution
- **Severity**: **Critical**
- **Location**: `src/agent/agent.sh` (Line 656) and `src/agent/lib/provider.sh`
- **Issue**: The command string is constructed using string concatenation (`echo "${cmd} \"${task}\""`) and executed using `eval`.
- **Impact**: A malicious task description containing shell metacharacters (e.g., `"; rm -rf /; echo "`) will break out of the quoted string and execute arbitrary code on the container/host.
- **Recommendation**: Remove `eval`. Use Bash arrays to construct the command and arguments (e.g., `cmd=(opencode run "$task")`) to ensure the shell handles argument boundaries safely.

### 2. Performance Optimization

#### A. Inefficient Session Lookup
- **Severity**: Medium
- **Location**: `src/agent/lib/session.sh` (Function: `find_latest_session`)
- **Issue**: The function iterates through *every* session JSON file and parses it with `jq` to find the latest timestamp.
- **Impact**: Performance is $O(N)$ where $N$ is the number of sessions. As history grows, session startup and status checks will become noticeably slow.
- **Recommendation**:
    1.  Embed the timestamp in the filename (e.g., `YYYY-MM-DD-HHMMSS_UUID.json`) to allow sorting via `ls` or globbing without file I/O.
    2.  Alternatively, maintain a `latest` symlink or index file.

#### B. Subshell Overhead
- **Severity**: Low
- **Location**: `src/agent/lib/log.sh`
- **Issue**: The `_redact_credentials` function spawns multiple subshells and `sed` processes for every log entry.
- **Impact**: Increases latency for logging operations.
- **Recommendation**: Use Bash parameter expansion (`${var//pattern/replacement}`) which is native and faster than forking `sed`.

### 3. Maintainability & Standards

- **Strengths**:
    -   **Strict Mode**: Consistent use of `set -euo pipefail` prevents silent failures.
    -   **Modularity**: Logic is cleanly separated into `lib/` files (`provider.sh`, `session.sh`, etc.), making the codebase easy to navigate.
    -   **Linting**: Code respects `shellcheck` directives.
- **Weaknesses**:
    -   **Runtime Config Generation**: `src/agent/lib/provider.sh` generates configuration files (e.g., `permissions.json`) at runtime. This side-effect behavior can be brittle and hard to debug if permissions need to be managed externally.

### 4. Test Coverage

- **Status**: Mixed
- **Gaps**:
    -   **Security Testing**: `tests/unit/test_log.bats` only tests "happy path" inputs. There are **no tests** verifying that quotes, newlines, or special characters are safely escaped in JSON logs.
    -   **Command Construction**: `tests/unit/test_provider.bats` does not verify that the backend command is constructed safely preventing argument injection.
- **Recommendation**: Add negative test cases specifically targeting injection vectors.

## Action Plan

1.  **Refactor `src/agent/lib/log.sh`**: Replace `printf` JSON construction with `jq --arg` to ensure automatic and correct escaping.
2.  **Refactor `src/agent/agent.sh`**: Switch from string-based command construction (`eval`) to Bash arrays (`"${cmd[@]}"`).
3.  **Enhance Tests**: Add BATS test cases for:
    -   Log entries containing quotes and newlines.
    -   Task descriptions containing shell operators (`&`, `;`, `|`).
4.  **Optimize Sessions**: Plan a migration to timestamp-prefixed filenames for session storage.
