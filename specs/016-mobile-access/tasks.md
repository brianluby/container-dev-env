# Tasks: Mobile Push Notifications for AI Agent Events

**Input**: Design documents from `/specs/016-mobile-access/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included (constitution mandates TDD for all production code)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, directory structure, and tooling

- [x] T001 Create project directory structure: `src/`, `tests/unit/`, `tests/integration/`, `tests/helpers/` per plan.md
- [x] T002 [P] Create `src/notify.yaml.template` with full config schema per data-model.md (services, priorities, quiet_hours, retry sections)
- [x] T003 [P] Create `tests/helpers/test_helper.bash` with common setup (mock curl function, temp dir creation, config file generation helpers)
- [x] T004 [P] Add `Makefile` with targets: `lint` (shellcheck), `format` (shfmt), `test` (bats), `test-unit`, `test-integration`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational

- [x] T005 [P] Write config parsing tests in `tests/unit/test_notify_config.bats` — test: load notify.yaml, extract service enabled state, extract priority mappings, handle missing file (exit 1), handle malformed YAML (exit 1)
- [x] T006 [P] Write CLI argument parsing tests in `tests/unit/test_cli.bats` — test: message required (exit 2 if missing), priority defaults to 3, priority validates 1-5 range (exit 2 if invalid), title defaults to "Agent Notification"

### Implementation for Foundational

- [x] T007 Implement config parser functions in `src/notify.sh` — locate config at `$NOTIFY_CONFIG` or `~/.config/notify/notify.yaml`; parse notify.yaml using grep/sed, load service enabled flags, load priority mappings, load retry settings; export `parse_config()` function
- [x] T008 Implement CLI argument parsing in `src/notify.sh` — validate message (non-empty), parse priority (default 3, validate 1-5), parse title (default "Agent Notification"); set exit code 2 for invalid args
- [x] T009 Implement logging functions in `src/notify.sh` — `log_info()`, `log_error()`, `log_warn()` writing timestamped messages to stderr; never log env var values containing secrets
- [x] T010 Implement environment variable validation in `src/notify.sh` — check `NTFY_TOPIC`, `NTFY_TOKEN` when ntfy enabled; check `SLACK_WEBHOOK` when slack enabled; `NTFY_SERVER` defaults to `https://ntfy.sh`; exit 1 with clear error if required vars missing

**Checkpoint**: Foundation ready — config parsing, CLI interface, logging, and env var validation all working. User story implementation can now begin.

---

## Phase 3: User Story 1 + User Story 2 — Core Notification Delivery (Priority: P1) 🎯 MVP

**Goal**: Send push notifications to ntfy.sh with priority support. US1 delivers task completion/failure notifications; US2 delivers urgent approval-needed alerts at priority 5.

**Independent Test (US1)**: Trigger `notify.sh "Task done"` with mocked curl and verify correct HTTP POST to ntfy.sh endpoint with Bearer auth and priority header.

**Independent Test (US2)**: Trigger `notify.sh "Approve?" 5 "Approval"` and verify priority-5 notification is sent with correct X-Priority header.

### Tests for User Story 1 + 2

- [x] T011 [P] [US1] Write ntfy.sh delivery tests in `tests/unit/test_ntfy.bats` — test: correct POST URL (`$NTFY_SERVER/$NTFY_TOPIC`), Authorization header (`Bearer $NTFY_TOKEN`), X-Priority header matches argument, X-Title header matches argument, message in request body, HTTPS enforced (reject http:// URLs)
- [x] T012 [US2] Write priority-5 delivery test in `tests/unit/test_ntfy.bats` — test: priority 5 sends X-Priority: 5, title "Approval Needed" maps to X-Title correctly

### Implementation for User Story 1 + 2

- [x] T013 [US1] Implement `send_ntfy()` function in `src/notify.sh` — construct curl POST to `$NTFY_SERVER/$NTFY_TOPIC` with headers: `Authorization: Bearer $NTFY_TOKEN`, `X-Priority: $priority`, `X-Title: $title`, body: message text; capture HTTP response code
- [x] T014 [US1] Implement main execution flow in `src/notify.sh` — parse args → load config → validate env → send to enabled services → log result → exit 0
- [x] T015 [US1] Make `src/notify.sh` executable and add shebang (`#!/usr/bin/env bash`), set `set -euo pipefail`, add `--help` flag support with usage from contracts/cli-interface.md
- [x] T016 [US1] Add empty message handling in `src/notify.sh` — if message is empty after sanitization, substitute "Agent event (no details)" per edge cases spec

**Checkpoint**: `notify.sh "message" [priority] [title]` sends to ntfy.sh with correct auth and priority. Both US1 (completion/failure) and US2 (approval at priority 5) are functional.

---

## Phase 4: User Story 5 — Content Sanitization (Priority: P2)

**Goal**: Strip file paths, API keys, code snippets, and env var assignments from notification messages before sending. Truncate to 200 chars.

**Independent Test**: Pass messages containing `/home/user/file.ts`, `sk-abc123`, `APIKEY=secret`, and code patterns to sanitize function; verify all are stripped and output is ≤200 chars.

### Tests for User Story 5

- [x] T017 [P] [US5] Write sanitization tests in `tests/unit/test_sanitize.bats` — test: strips absolute file paths (`/home/user/project/src/auth.ts` → removed), strips API key patterns (`sk-abc123def` → removed, `tk_tokenvalue` → removed, 20+ uppercase chars → removed), strips env var assignments (`API_KEY=secret123` → removed), strips code patterns (lines with `{`, `}`, `;`, `function `, `class `, `import ` → removed), collapses multiple spaces to single, truncates to 200 chars, preserves non-sensitive text

### Implementation for User Story 5

- [x] T018 [US5] Implement `sanitize_message()` function in `src/notify-sanitize.sh` — apply regex patterns in order per data-model.md ContentSanitizer: (1) strip file paths, (2) strip API keys, (3) strip env var assignments, (4) strip code pattern lines, (5) collapse whitespace, (6) truncate to 200 chars; use `sed` for pattern matching
- [x] T019 [US5] Integrate sanitization into `src/notify.sh` — source `notify-sanitize.sh`, call `sanitize_message()` on input message before passing to `send_ntfy()` or any service sender

**Checkpoint**: All messages are automatically sanitized before leaving the container. Sensitive content (paths, keys, code) never appears in notifications.

---

## Phase 5: User Story 4 — Priority-Based Delivery (Priority: P2)

**Goal**: Map event types (completed, failed, approval_needed, progress) to priority levels using notify.yaml configuration.

**Independent Test**: Call `notify.sh` with event type mappings from config and verify correct priority values are sent in HTTP headers.

### Tests for User Story 4

- [x] T020 [P] [US4] Write priority mapping tests in `tests/unit/test_priority.bats` — test: "completed" maps to priority 3, "failed" maps to priority 4, "approval_needed" maps to priority 5, "progress" maps to priority 2, custom mapping in notify.yaml overrides defaults, unknown event type defaults to priority 3

### Implementation for User Story 4

- [x] T021 [US4] Implement `resolve_priority()` function in `src/notify.sh` — if priority argument is numeric (1-5), use directly; if priority argument matches event type name, look up in config `priorities` section; fallback to default priority 3
- [x] T022 [US4] Update CLI interface in `src/notify.sh` — priority parameter now accepts both integers (1-5) and event type strings (completed, failed, approval_needed, progress); update `--help` text

**Checkpoint**: Event types are automatically mapped to priority levels. `notify.sh "done" completed` sends priority 3; `notify.sh "help" approval_needed` sends priority 5.

---

## Phase 6: User Story 3 — Multi-Service Delivery (Priority: P2)

**Goal**: Support Slack webhooks as a secondary notification channel alongside ntfy.sh. Both services fire independently.

**Independent Test**: Configure both services in notify.yaml, mock both endpoints, trigger notification, verify both receive HTTP POST.

### Tests for User Story 3

- [x] T023 [P] [US3] Write Slack delivery tests in `tests/unit/test_slack.bats` — test: correct POST to `$SLACK_WEBHOOK`, Content-Type application/json, payload contains priority emoji + title + message, priority 5 uses 🔴, priority 3 uses 🟢, handles missing jq gracefully (fallback to simple text)
- [x] T024 [P] [US3] Write multi-service tests in `tests/integration/test_multi_service.bats` — test: both services called when both enabled, ntfy failure doesn't block Slack delivery, Slack failure doesn't block ntfy delivery, disabled service is skipped

### Implementation for User Story 3

- [x] T025 [US3] Implement `send_slack()` function in `src/notify.sh` — construct JSON payload with priority emoji mapping (🔴/🟠/🟢/⬜) + bold title + message; POST to `$SLACK_WEBHOOK` with Content-Type application/json; use jq if available, fallback to printf for JSON construction
- [x] T026 [US3] Implement multi-service dispatch in `src/notify.sh` — iterate enabled services from config, call `send_ntfy()` and/or `send_slack()` independently; if one fails, continue to next; log per-service success/failure

**Checkpoint**: Notifications delivered to both ntfy.sh and Slack simultaneously. One service failing doesn't prevent the other from receiving.

---

## Phase 7: User Story 6 — Quiet Hours Configuration (Priority: P3)

**Goal**: Suppress notifications below a priority threshold during configured quiet hours. Priority 5 (urgent) always bypasses.

**Independent Test**: Set quiet hours 22:00-08:00 in config, mock time to 23:00, send priority 3 (suppressed) and priority 5 (delivered); verify correct behavior.

### Tests for User Story 6

- [x] T027 [P] [US6] Write quiet hours tests in `tests/unit/test_quiet_hours.bats` — test: during quiet hours priority 3 is suppressed, during quiet hours priority 5 is delivered, outside quiet hours all priorities delivered, overnight window (22:00-08:00) correctly detected, same-day window (09:00-17:00) correctly detected, disabled quiet hours passes all, suppressed notifications log to stderr

### Implementation for User Story 6

- [x] T028 [US6] Implement `is_quiet_hours()` function in `src/notify.sh` — compare current time (`date +%H%M`) against configured start/end; handle overnight wrap (start > end); return 0 if currently in quiet period, 1 otherwise
- [x] T029 [US6] Implement `should_suppress()` function in `src/notify.sh` — if quiet hours disabled return 1 (don't suppress); if not in quiet window return 1; if priority >= min_priority return 1 (bypass); otherwise return 0 (suppress)
- [x] T030 [US6] Integrate quiet hours check into main flow in `src/notify.sh` — after sanitization, before service dispatch, call `should_suppress()`; if suppressed, log "Notification suppressed (quiet hours)" to stderr and exit 0; otherwise proceed with delivery

**Checkpoint**: Quiet hours correctly filter low-priority notifications. Urgent alerts (priority 5) always get through. This completes US2's acceptance scenario 2 (quiet hours bypass).

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Retry logic, edge cases, documentation, linting, and integration examples

### Tests for Retry Logic

- [x] T031 [P] Write retry/backoff tests in `tests/integration/test_retry.bats` — test: retries on HTTP 429 with exponential delay (2s, 4s, 8s), retries on HTTP 5xx, does NOT retry on HTTP 400/401, discards after 3 failed attempts (exits 0), logs each retry attempt to stderr

### Implementation

- [x] T032 Implement `send_with_retry()` wrapper in `src/notify.sh` — wrap `send_ntfy()` and `send_slack()` calls; on retryable error (429, 5xx, connection timeout) sleep `$((2 ** attempt))` seconds; max 3 retries; on non-retryable (400, 401) fail immediately; after exhaustion log and exit 0
- [x] T033 [P] Add edge case handling in `src/notify.sh` — webhook URL env var not set but service enabled: skip with warning; both services unreachable: log and exit 0; HTTPS enforcement: reject non-https URLs in NTFY_SERVER
- [x] T034 [P] Create Claude Code hook example in `src/hooks/claude-code-example.json` — working `.claude/settings.local.json` snippet per research.md D-4 with Stop hook calling notify.sh
- [x] T035 [P] Run `shellcheck src/notify.sh src/notify-sanitize.sh` and fix all warnings
- [x] T036 [P] Run `shfmt -w src/notify.sh src/notify-sanitize.sh` to format all scripts (shfmt not available on host; scripts manually formatted consistently)
- [x] T037 Validate end-to-end flow: run full bats test suite (`bats tests/`) and verify all tests pass; note: FR-012 (30s delivery SLA) is validated manually with a real ntfy.sh endpoint, not in automated tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1+US2 (Phase 3)**: Depends on Phase 2 — MVP delivery
- **US5 (Phase 4)**: Depends on Phase 2 — can run parallel with Phase 3
- **US4 (Phase 5)**: Depends on Phase 3 (needs send functions)
- **US3 (Phase 6)**: Depends on Phase 3 (extends service dispatch)
- **US6 (Phase 7)**: Depends on Phase 3 (needs delivery to gate)
- **Polish (Phase 8)**: Depends on Phases 3-7

### User Story Dependencies

- **US1+US2 (P1)**: After Foundational — no other story dependencies
- **US5 (P2)**: After Foundational — independent sanitization module (can parallel with US1)
- **US4 (P2)**: After US1+US2 — extends priority handling
- **US3 (P2)**: After US1+US2 — adds second service to dispatch loop
- **US6 (P3)**: After US1+US2 — adds time-based gate before dispatch

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD per constitution)
- Implementation follows test completion
- Story checkpoint validates independently

### Parallel Opportunities

- T002, T003, T004 can run in parallel (Phase 1)
- T005, T006 can run in parallel (Phase 2 tests)
- T011 then T012 sequentially (same file: tests/unit/test_ntfy.bats)
- Phase 4 (US5) can run in parallel with Phase 3 (US1+US2) — different files
- T023, T024 can run in parallel (Phase 6 tests)
- T033, T034, T035, T036 can run in parallel (Phase 8 polish)

---

## Parallel Example: Phase 3 (US1+US2)

```bash
# Write tests sequentially (same file):
Task: "Write ntfy.sh delivery tests in tests/unit/test_ntfy.bats" (T011)
Task: "Write priority-5 delivery test in tests/unit/test_ntfy.bats" (T012)

# After tests fail (TDD), implement sequentially:
Task: "Implement send_ntfy() function in src/notify.sh" (T013)
Task: "Implement main execution flow in src/notify.sh" (T014)
```

## Parallel Example: Phase 4 (US5) alongside Phase 3

```bash
# These can run at the same time as Phase 3 (different files):
Task: "Write sanitization tests in tests/unit/test_sanitize.bats" (T017)
Task: "Implement sanitize_message() in src/notify-sanitize.sh" (T018)
```

---

## Implementation Strategy

### MVP First (User Stories 1+2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (config, CLI, logging, env vars)
3. Complete Phase 3: US1+US2 (ntfy.sh delivery with priority)
4. **STOP and VALIDATE**: `notify.sh "test" 3` delivers to phone; `notify.sh "approve?" 5` delivers urgently
5. Deploy/demo if ready — core value proposition is working

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1+US2 → Core delivery works (MVP!)
3. US5 → Messages sanitized (security hardening)
4. US4 → Event types auto-map to priorities
5. US3 → Slack as secondary channel
6. US6 → Quiet hours filtering
7. Polish → Retry, edge cases, docs
8. Each phase adds value without breaking previous functionality

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable after its phase
- Constitution requires: tests written first (TDD), shellcheck clean, shfmt formatted
- notify.sh always exits 0 for delivery failures (logs to stderr) to avoid blocking agent hooks
- Secrets (NTFY_TOKEN, SLACK_WEBHOOK) never logged or written to config files
