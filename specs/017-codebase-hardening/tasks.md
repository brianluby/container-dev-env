# Tasks: Codebase Hardening

**Input**: Design documents from `/specs/017-codebase-hardening/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Included per constitution principle III (Test-First Development) and spec scope ("Adding tests for all security fixes").

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify prerequisites and create shared utilities

- [x] T001 Verify BATS test infrastructure exists at tests/unit/.bats-battery/ (bats-core, bats-support, bats-assert)
- [x] T002 [P] Create standardized diagnostic helper function `_log_msg()` supporting `[ERROR]` and `[WARN]` prefixed output in scripts/secrets-common.sh (FR-016). The function must write to stderr with format: `[LEVEL] component: message`. This utility will be sourced by secrets-load.sh, secrets-edit.sh, and agent scripts.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: None required. All user stories are independent — each modifies different files with no shared blocking infrastructure beyond Phase 1.

**Checkpoint**: Setup complete — user story implementation can begin immediately

---

## Phase 3: User Story 1 — Secure Agent Command Execution (Priority: P1) 🎯 MVP

**Goal**: Eliminate command injection via `eval` in the agent wrapper by replacing string-based command construction with Bash array execution.

**Independent Test**: Submit task descriptions with hostile shell metacharacters (`;`, `$()`, backticks, `|`, `&&`) and verify no unintended commands execute.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T003 [US1] Write BATS injection tests in tests/unit/test_agent_injection.bats. Tests must: (1) source src/agent/lib/provider.sh, (2) call build_backend_command with hostile task descriptions containing `;rm -rf /`, `$(touch /tmp/canary)`, `` `id` ``, `| cat /etc/passwd`, `&& echo pwned`, (3) assert canary files are NOT created, (4) assert hostile command output does NOT appear. Include setup/teardown for canary file cleanup. Use bats-assert helpers (assert_success, refute_output).

### Implementation for User Story 1

- [x] T004 [US1] Refactor build_backend_command() in src/agent/lib/provider.sh to populate a global array variable `AGENT_CMD=()` instead of echoing a string. For opencode: `AGENT_CMD=(opencode run "$task")`. For claude with auto mode: `AGENT_CMD=(claude --dangerously-skip-permissions -p "$task")`. For claude manual/hybrid: `AGENT_CMD=(claude -p "$task")`. Remove the `echo` return pattern entirely.
- [x] T005 [US1] Update src/agent/agent.sh main() function (around line 652-656): Replace `cmd=$(build_backend_command ...)` + `eval "${cmd}"` with `build_backend_command "${backend}" "${AGENT_CFG_MODE}" "${TASK_DESCRIPTION}"` followed by `"${AGENT_CMD[@]}"` (or `exec "${AGENT_CMD[@]}"` where appropriate). Also update the --serve path (line 610) to use `exec opencode serve` directly (already safe, just verify). Update the --resume path (lines 623-627) similarly.
- [x] T006 [US1] Run tests/unit/test_agent_injection.bats and verify all tests pass

**Checkpoint**: Agent command injection is eliminated. Hostile task descriptions pass as literal text arguments.

---

## Phase 4: User Story 2 — Safe JSON Logging and Session Management (Priority: P1)

**Goal**: Replace unsafe printf/heredoc-based JSON construction with `jq --arg` to prevent JSON injection from user-controlled fields.

**Independent Test**: Generate log entries and sessions with special characters (`"`, `\`, newlines, control chars) in user-controlled fields and validate output with `jq empty`.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T007 [US2] Write BATS JSON escape tests in tests/unit/test_json_escape.bats. Tests must: (1) source src/agent/lib/session.sh and src/agent/lib/log.sh, (2) call create_session with task descriptions containing `"quotes"`, `back\\slashes`, `new\nlines`, `control\x01chars`, (3) validate resulting JSON files with `jq empty`, (4) assert field values contain the literal special characters properly escaped, (5) call log_action with hostile target/details and validate JSONL output is valid JSON per line.

### Implementation for User Story 2

- [x] T008 [US2] Rewrite create_session() in src/agent/lib/session.sh to use `jq -n` with `--arg` for all string fields (id, backend, started_at, task_description, approval_mode, workspace, action_log_path). Replace the heredoc JSON template (lines 45-66) with a single `jq -n` invocation that constructs the complete session object. Write result to session_path atomically (write to .tmp then mv).
- [x] T009 [US2] Rewrite log_action() in src/agent/lib/log.sh to use `jq -n` with `--arg` for timestamp, action, target, details fields, and `--argjson` for result and checkpoint_id (which can be null). Replace the printf-based JSON construction (lines 98-101) with a `jq -n` invocation. Ensure output is a single line (no pretty-printing) for JSONL format. Credential redaction still happens before passing to jq.
- [x] T010 [US2] Run tests/unit/test_json_escape.bats and verify all tests pass

**Checkpoint**: All JSON output is valid regardless of input content. Session and log files are always parseable.

---

## Phase 5: User Story 3 — Verified Software Downloads (Priority: P2)

**Goal**: Create a centralized SHA256 checksum manifest and add verification to all Dockerfile download steps.

**Independent Test**: Build the container image successfully with correct checksums; modify a checksum and verify the build fails.

### Implementation for User Story 3

- [x] T011 [US3] Create checksums.sha256 at repository root with SHA256 hashes for: opencode-linux-amd64 (v0.5.2), opencode-linux-arm64 (v0.5.2), chezmoi-linux-amd64 (v2.47.1), chezmoi-linux-arm64 (v2.47.1), age-linux-amd64 (v1.1.1), age-linux-arm64 (v1.1.1), continue-v1.2.14.vsix, cline-v3.51.0.vsix. Obtain hashes by downloading each binary/extension and computing `sha256sum`. Use format: `<hash>  <filename>` (two-space separator). Note: NodeSource packages are APT-managed with built-in GPG signature verification and do not require SHA256 manifest entries.
- [x] T012 [P] [US3] Update Dockerfile (root) to add checksum verification for the Chezmoi download (line 88). Replace the `sh -c "$(curl ...)"` install with: curl the tarball/binary to a temp path, verify with `echo "$HASH /tmp/file" | sha256sum -c -`, then install. Select hash based on `TARGETARCH` (amd64/arm64). Fail build on mismatch.
- [x] T013 [P] [US3] Update Dockerfile (root) to add checksum verification for the age download (lines 92-95). After downloading the tarball, verify its SHA256 against the architecture-specific hash from the manifest before extracting.
- [x] T014 [P] [US3] Update docker/Dockerfile.agent to add checksum verification for the OpenCode download (lines 23-33). After `curl -fsSL ... -o /usr/local/bin/opencode`, add `echo "$HASH /usr/local/bin/opencode" | sha256sum -c -` with TARGETARCH-based hash selection. Build must fail on mismatch.
- [ ] T015 [P] [US3] Update src/docker/Dockerfile.ai-extensions to add checksum verification for VSIX extension downloads (Continue v1.2.14, Cline v3.51.0). After each curl download, verify SHA256 against the manifest before proceeding with installation.
- [ ] T016 [US3] Verify container builds succeed with correct checksums by running `docker build -t devcontainer:test .`, `docker build -t devcontainer:agent-test -f docker/Dockerfile.agent .`, and verifying the AI extensions Dockerfile builds.

**Checkpoint**: All binary downloads are verified. A tampered binary causes an immediate build failure.

---

## Phase 6: User Story 4 — Safe Secrets Loading (Priority: P2)

**Goal**: Rewrite the secrets loader to use safe line-by-line parsing without `source` or `eval`, with key validation, permission checking, and command substitution rejection.

**Independent Test**: Create secrets files containing `$()`, backticks, invalid keys, and world-readable permissions — verify none execute and appropriate errors/warnings are emitted.

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T017 [US4] Write BATS secrets loader tests in tests/unit/test_secrets_load.bats. Tests must cover: (1) valid KEY=VALUE parsing exports correctly, (2) first-= split preserves `KEY=val=ue`, (3) key validation rejects `2INVALID`, `invalid-key`, `lowercase` with `[WARN]`, (4) command substitution patterns `$()`, `${}`, backticks in values are rejected with `[WARN]` and NOT executed (canary test), (5) bare `$` in values is allowed, (6) world-readable file (mode 0644) is rejected with `[ERROR]` before any parsing, (7) comments (#) and blank lines are skipped, (8) values starting with `=` (empty key side) handled correctly. Each test uses a temp secrets file created in setup().

### Implementation for User Story 4

- [x] T018 [US4] Rewrite scripts/secrets-load.sh as a safe line-by-line parser. Replace any `source`-based loading with a `while IFS='=' read -r key value` loop. Implementation must: (1) check file permissions first (reject if group-writable or world-readable using `stat`), (2) skip blank lines and `#` comments, (3) validate key against `^[A-Z_][A-Z0-9_]*$` regex, (4) reject values matching `\$\(`, `\$\{`, or backtick patterns, (5) allow bare `$` in values, (6) export validated pairs with `export "$key=$value"`, (7) emit `[WARN] secrets: <message>` for skipped lines and `[ERROR] secrets: <message>` for fatal errors (all to stderr). Source the `_log_msg` helper from scripts/secrets-common.sh.
- [x] T019 [US4] Run tests/unit/test_secrets_loader.bats and verify all tests pass

**Checkpoint**: Secrets loading is safe from injection. Tampered files produce warnings, not code execution.

---

## Phase 7: User Story 5 — Localhost-Only Agent Port Binding (Priority: P2)

**Goal**: Ensure the agent server mode binds only to 127.0.0.1 and requires authentication before starting.

**Independent Test**: Start agent in server mode, verify listening socket is 127.0.0.1 only, and verify server refuses to start without OPENCODE_SERVER_PASSWORD.

### Implementation for User Story 5

- [x] T020 [US5] Update src/agent/agent.sh serve mode handling (around line 604-611): Before `exec opencode serve`, add a check that `OPENCODE_SERVER_PASSWORD` is set and non-empty. If unset, emit `[ERROR] agent: Server mode requires OPENCODE_SERVER_PASSWORD to be configured` to stderr and exit with EXIT_ERROR. Pass `--host 127.0.0.1` to the serve command (or equivalent flag) to bind to localhost only.
- [x] T021 [P] [US5] Update docker/docker-compose.agent.yml port mapping from `"4096:4096"` to `"127.0.0.1:4096:4096"` to ensure the port is only exposed on the host's loopback interface even at the Docker level.

**Checkpoint**: Agent server mode is localhost-only and requires authentication.

---

## Phase 8: User Story 6 — Reliable CI Pipeline Triggers (Priority: P2)

**Goal**: Pin all GitHub Actions to commit SHAs for supply-chain security and expand path filters to cover all source directories.

**Independent Test**: Inspect all `uses:` lines for 40-character SHA references; verify path filters include docker/**, src/**, templates/**, scripts/**, and other key paths.

### Implementation for User Story 6

- [x] T022 [US6] Pin all third-party actions in .github/workflows/container-build.yml to full commit SHAs with version comments. Look up the current commit SHA for each tag reference (e.g., `actions/checkout@v4` → `actions/checkout@<sha> # v4.x.x`). Pin: actions/checkout, docker/setup-buildx-action, docker/login-action, docker/build-push-action, and any other third-party actions.
- [x] T023 [P] [US6] Pin all third-party actions in .github/workflows/worktree-tests.yml to full commit SHAs. Pin: actions/checkout, ludeeus/action-shellcheck. Replace `@master` with the SHA of the latest stable release.
- [x] T024 [US6] Expand path filters in .github/workflows/container-build.yml under on.push.paths and on.pull_request.paths to include: `docker/**`, `src/**`, `templates/**`, `scripts/**`, `Dockerfile`, `pyproject.toml`, `uv.lock`, `Makefile`, `checksums.sha256`, `.github/workflows/container-build.yml`.
- [x] T025 [P] [US6] Create .github/dependabot.yml with two ecosystems: (1) `github-actions` with directory `/` and weekly schedule, (2) `docker` with directory `/` and weekly schedule. This satisfies FR-015.

**Checkpoint**: CI workflows are immutably pinned and trigger on all relevant file changes.

---

## Phase 9: User Story 7 — Safe Secrets Editing (Priority: P3)

**Goal**: Fix the secrets editor to preserve special characters through store/retrieve cycles without corruption.

**Independent Test**: Store and retrieve values containing `/`, `+`, `=`, `&`, `|`, `\`, and values starting with `-n` — verify byte-perfect round-trip.

### Implementation for User Story 7

- [x] T026 [US7] Fix scripts/secrets-edit.sh to handle special characters in values. Replace any `echo "$value"` with `printf '%s\n' "$value"` to prevent `-n`/`-e` flag injection. Ensure sed/awk operations use proper delimiters that don't conflict with value content (use `\x1f` or `|` as delimiter instead of `/`). Verify the store operation writes the exact bytes provided without shell interpretation.

**Checkpoint**: Secrets editor preserves all special characters through edit cycles.

---

## Phase 10: User Story 8 — Consistent Shell Strict Mode (Priority: P3)

**Goal**: Ensure all committed .sh files and bash-shebang executables use `set -euo pipefail` or document exceptions.

**Independent Test**: Run a grep/scan across all .sh files verifying `set -euo pipefail` appears within the first 10 lines, or a `# strict-mode-exception:` comment exists.

### Implementation for User Story 8

- [x] T027 [US8] Audit all committed .sh files and bash-shebang executables in the repository. Produce a list of scripts missing `set -euo pipefail`. Check: scripts/*.sh, src/agent/*.sh, src/agent/lib/*.sh, src/scripts/*.sh, src/scripts/lib/*.sh, src/mcp/*.sh, src/notify*.sh, docker/entrypoint.sh, docker/healthcheck.sh, tests/run-tests.sh, tests/fixtures/*.sh.
- [x] T028 [US8] Add `set -euo pipefail` to any scripts identified in T027 that are missing it. For scripts where strict mode would break functionality (e.g., scripts that intentionally check $? after commands), add a `# strict-mode-exception: <reason>` comment in the header instead.

**Checkpoint**: All shell scripts have consistent error handling. ShellCheck reports zero strict-mode warnings.

---

## Phase 11: User Story 9 — Canonical Container Documentation (Priority: P3)

**Goal**: Create an Architecture Decision Record documenting which Dockerfile serves which use case.

**Independent Test**: A new developer can read the ADR and identify the correct container image for their use case.

### Implementation for User Story 9

- [x] T029 [US9] Create docs/decisions/005-container-image-architecture.md documenting: (1) Dockerfile (root) — base development image with Python, Node.js, Chezmoi, (2) docker/Dockerfile — volume architecture development container with MCP support, (3) docker/Dockerfile.agent — agent layer extending base with OpenCode/Claude Code, (4) src/docker/Dockerfile — OpenCode installation stage, (5) src/docker/Dockerfile.ai-extensions — IDE extensions layer, (6) src/docker/Dockerfile.ide — IDE container. For each: purpose, when to use, how to build, key dependencies. Follow the ADR format from existing docs/adr/ if present, otherwise use standard ADR template (Title, Status, Context, Decision, Consequences).

**Checkpoint**: Container image architecture is documented. New developers have a clear reference.

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Final validation across all stories

- [x] T030 Run full BATS test suite: `tests/unit/.bats-battery/bats-core/bin/bats tests/unit/` — all tests must pass including new security tests
- [ ] T031 [P] Run ShellCheck on all modified scripts: `shellcheck scripts/*.sh src/agent/*.sh src/agent/lib/*.sh src/scripts/*.sh` — zero errors
- [x] T032 [P] Verify no `eval` remains in agent execution path: `grep -rn 'eval ' src/agent/` should return zero results in the command execution flow
- [x] T033 [P] Verify SHA pinning completeness: `grep -rn 'uses:' .github/workflows/ | grep -v '@[a-f0-9]\{40\}'` should return empty
- [ ] T034 Verify container build with checksums: `docker build -t devcontainer:verify .` succeeds

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (minimal — just T001/T002)
- **User Stories (Phase 3+)**: All depend on Phase 1 completion only (T002 for diagnostic helper)
  - US1 and US2 can proceed in parallel (different files)
  - US3-US6 can proceed in parallel with each other (different files)
  - US7-US9 can proceed in parallel (different files)
- **Polish (Phase 12)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Independent — modifies src/agent/lib/provider.sh, src/agent/agent.sh
- **US2 (P1)**: Independent — modifies src/agent/lib/session.sh, src/agent/lib/log.sh
- **US3 (P2)**: Independent — modifies Dockerfiles, creates checksums.sha256
- **US4 (P2)**: Independent — modifies scripts/secrets-load.sh
- **US5 (P2)**: Partially depends on US1 (same file: agent.sh), but different code region (serve mode vs main execution). Can be implemented after US1 or in parallel if changes don't conflict.
- **US6 (P2)**: Independent — modifies .github/ files only
- **US7 (P3)**: Independent — modifies scripts/secrets-edit.sh
- **US8 (P3)**: Independent — adds headers to multiple scripts (non-functional change)
- **US9 (P3)**: Independent — creates new docs/adr/ file

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation tasks may have internal ordering (T004 before T005)
- Verification task (run tests) always last in each story

### Parallel Opportunities

- **P1 stories**: US1 (T003-T006) and US2 (T007-T010) can run in parallel
- **P2 stories**: US3 (T011-T016), US4 (T017-T019), US5 (T020-T021), US6 (T022-T025) can all run in parallel
- **P3 stories**: US7 (T026), US8 (T027-T028), US9 (T029) can all run in parallel
- **Within US3**: T012, T013, T014, T015 can run in parallel (different Dockerfiles)
- **Within US6**: T023, T025 can run in parallel with T022, T024

---

## Parallel Example: User Story 1 + User Story 2

```bash
# Launch both P1 stories in parallel (different files, no conflicts):

# Agent 1 - US1: Command Injection Fix
Task: "Write BATS injection tests in tests/unit/test_agent_injection.bats"
Task: "Refactor build_backend_command() in src/agent/lib/provider.sh to use array"
Task: "Update src/agent/agent.sh to use array execution"

# Agent 2 - US2: JSON Injection Fix
Task: "Write BATS JSON escape tests in tests/unit/test_json_escape.bats"
Task: "Rewrite create_session() in src/agent/lib/session.sh with jq"
Task: "Rewrite log_action() in src/agent/lib/log.sh with jq"
```

---

## Parallel Example: All P2 Stories

```bash
# Launch all P2 stories in parallel after P1 completion:

# Agent 1 - US3: Supply Chain
Task: "Create checksums.sha256 at repository root"
Task: "Update Dockerfile for Chezmoi checksum verification"
Task: "Update Dockerfile for age checksum verification"
Task: "Update docker/Dockerfile.agent for OpenCode checksum verification"

# Agent 2 - US4: Secrets Loading
Task: "Write BATS secrets loader tests in tests/unit/test_secrets_load.bats"
Task: "Rewrite scripts/secrets-load.sh as safe parser"

# Agent 3 - US5: Port Binding
Task: "Update src/agent/agent.sh serve mode for localhost + auth"
Task: "Update docker/docker-compose.agent.yml port mapping"

# Agent 4 - US6: CI Fixes
Task: "Pin actions in container-build.yml to SHAs"
Task: "Pin actions in worktree-tests.yml to SHAs"
Task: "Expand path filters in container-build.yml"
Task: "Create .github/dependabot.yml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 3: User Story 1 — Command Injection Fix (T003-T006)
3. **STOP and VALIDATE**: Run test_agent_injection.bats — all pass
4. Critical security vulnerability eliminated

### Incremental Delivery (Recommended)

1. Setup (T001-T002) → Foundation ready
2. US1 + US2 in parallel (P1 stories) → Critical injection risks eliminated
3. US3-US6 in parallel (P2 stories) → Supply chain, secrets, network, CI hardened
4. US7-US9 in parallel (P3 stories) → Polish items complete
5. Phase 12 → Full validation pass

### Sequential Delivery (Single Developer)

1. Setup → US1 → US2 → US3 → US4 → US5 → US6 → US7 → US8 → US9 → Polish
2. Each story is independently testable after completion
3. Commit after each story for incremental progress

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Tests are written FIRST and must FAIL before implementation
- Commit after each user story completion
- US5 modifies agent.sh (shared with US1) — implement after US1 or coordinate
- Checksum values in T011 require downloading actual binaries to compute — this is a research/fetch step
- SHA values for GitHub Actions in T022/T023 require looking up commit hashes for current tag versions
