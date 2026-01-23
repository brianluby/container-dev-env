# Tasks: AI IDE Extensions

**Input**: Design documents from `/specs/009-ai-ide-extensions/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Included — plan.md explicitly defines contract, integration, and unit test phases.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- This is an infrastructure/configuration project — no application code

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create project directory structure matching plan.md layout

- [x] T001 Create project directory structure: `src/docker/`, `src/scripts/`, `src/config/continue/`, `src/config/cline/`, `src/config/vscode/`, `src/hosts.d/`, `tests/contract/`, `tests/integration/`, `tests/unit/`
- [x] T002 [P] Create extension manifest file listing pinned versions at `src/docker/extensions.yaml` per Contract 1 schema (Continue v1.2.14, Cline v3.51.0)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Dockerfile layer and install script that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Create `src/scripts/install-extensions.sh` to download pinned VSIX files from Open VSX and install via `openvscode-server --install-extension` per research.md §7
- [x] T004 [P] Create `src/hosts.d/telemetry-block.conf` with entries blocking `data.cline.bot`, `us.posthog.com`, `eu.posthog.com` per Contract 6
- [x] T005 Create `src/docker/Dockerfile.ai-extensions` with: VSIX download layer, extension installation via install-extensions.sh, `npm install -g @modelcontextprotocol/server-filesystem@2026.1.14`, `pip install mcp-server-git==2026.1.14`, COPY telemetry-block.conf to `/etc/hosts.d/` and append to `/etc/hosts`

**Checkpoint**: Container image builds with extensions installed, MCP packages available, telemetry blocked at network level

---

## Phase 3: User Story 7 - Extension Installation & Activation (Priority: P1) 🎯 MVP

**Goal**: Both AI extensions install and activate in OpenVSCode-Server without errors on fresh container build

**Independent Test**: Build container, start it, verify both extensions appear in Extensions panel and activate cleanly in Output panel

### Tests for User Story 7

- [x] T006 [P] [US7] Integration test for extension activation in `tests/integration/test_extension_activation.sh` — verify Continue and Cline both show activated status
- [x] T007 [P] [US7] Integration test for telemetry blocking in `tests/integration/test_telemetry_block.sh` — verify DNS resolution of PostHog domains returns 0.0.0.0

### Implementation for User Story 7

- [x] T008 [US7] Create VS Code user settings at `src/config/vscode/settings.json` with `telemetry.telemetryLevel: "off"` per Contract 5
- [x] T009 [US7] Add Dockerfile step to copy `src/config/vscode/settings.json` to `~/.config/Code/User/settings.json` and create required parent directories
- [x] T009a [US7] Document volume mount requirements for extension persistence in `src/docker/Dockerfile.ai-extensions`: `~/.continue/` (config volume), `~/.config/Code/User/` (vscode-user volume), extension install directory (extensions volume) per data-model.md Volume Persistence table
- [x] T009b [US7] Integration test for rebuild persistence in `tests/integration/test_extension_persistence.sh` — rebuild container image, verify extensions and configs survive without re-installation

**Checkpoint**: Container starts with both extensions activated, telemetry disabled at application and network levels

---

## Phase 4: User Story 3 - API Key Configuration (Priority: P1)

**Goal**: API keys provided via environment variables are automatically bridged to extension auth without manual UI setup

**Independent Test**: Set `ANTHROPIC_API_KEY` env var, start container, verify Continue extension shows connected status

### Tests for User Story 3

- [x] T010 [P] [US3] Unit test for bridge script edge cases in `tests/unit/test_bridge_secrets.sh` — handles missing vars, empty values, whitespace, multiple keys
- [x] T011 [P] [US3] Contract test for no hardcoded API keys in `tests/contract/test_no_hardcoded_keys.sh` — scan src/ for literal API key patterns
- [x] T012 [P] [US3] Integration test for API key bridge flow in `tests/integration/test_api_key_bridge.sh` — verify env var → `~/.continue/.env` → extension auth

### Implementation for User Story 3

- [x] T013 [US3] Create `src/scripts/bridge-secrets.sh` that writes `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `MISTRAL_API_KEY` from OS env vars to `~/.continue/.env` with chmod 600 per Contract 3 — skip missing optional keys, error if no keys at all
- [x] T014 [US3] Add Dockerfile entrypoint integration to call `bridge-secrets.sh` at container startup after secret injection (integrates with existing 008 entrypoint)

**Checkpoint**: Container starts, env vars are bridged to `.env` file, Continue authenticates automatically

---

## Phase 5: User Story 1 - Inline Code Completions (Priority: P1)

**Goal**: Ghost text completions appear when typing code in Python, TypeScript, Rust, or Go files

**Independent Test**: Open a `.py` file, type a function signature, verify ghost text appears within 5 seconds

### Tests for User Story 1

- [x] T015 [P] [US1] Contract test for Continue config syntax in `tests/contract/test_continue_config_valid.sh` — validate YAML syntax and required schema fields per Contract 2
- [x] T016 [P] [US1] Integration test for completions in `tests/integration/test_completions.sh` — verify ghost text generation for `.py`, `.ts`, `.rs`, `.go` files

### Implementation for User Story 1

- [x] T017 [US1] Create `src/config/continue/config.yaml.tmpl` as Chezmoi Go template with: schema v1 header, Codestral autocomplete model entry (`codestral-latest`, `roles: [autocomplete]`, `apiKey: ${{ secrets.MISTRAL_API_KEY }}`), Qwen local fallback (`qwen2.5-coder:1.5b` via Ollama), `autocompleteOptions` with `debounceDelay: 250`
- [x] T018 [US1] Add Dockerfile step to render and install Continue config template to `~/.continue/config.yaml`

**Checkpoint**: Typing code produces AI-powered ghost text completions using FIM-trained model

---

## Phase 6: User Story 2 - Chat-Based Code Assistance (Priority: P1)

**Goal**: Chat panel returns helpful code explanations, debugging suggestions, and generated code

**Independent Test**: Open chat panel, ask "explain this function" with a file open, verify relevant response

### Tests for User Story 2

- [x] T019 [US2] Integration test for chat responses in `tests/integration/test_chat_response.sh` — verify chat panel returns a response to a code question

### Implementation for User Story 2

- [x] T020 [US2] Add Claude Sonnet chat model entry to `src/config/continue/config.yaml.tmpl` (`claude-sonnet-4-20250514`, `roles: [chat, edit]`, `apiKey: ${{ secrets.ANTHROPIC_API_KEY }}`)

**Checkpoint**: Chat panel answers code questions with contextually relevant responses

---

## Phase 7: User Story 4 - Multi-Provider LLM Support (Priority: P2)

**Goal**: Multiple LLM providers can be configured and switched between without restart

**Independent Test**: Configure Anthropic and OpenAI, send requests to each, verify both return valid responses

### Tests for User Story 4

- [x] T021 [US4] Integration test for provider switching in `tests/integration/test_provider_switch.sh` — verify switching between Anthropic and OpenAI providers works without IDE restart

### Implementation for User Story 4

- [x] T022 [US4] Add OpenAI GPT-4o model entry to `src/config/continue/config.yaml.tmpl` (`gpt-4o`, `roles: [chat]`, `apiKey: ${{ secrets.OPENAI_API_KEY }}`)
- [x] T023 [US4] Add Ollama local chat model entry to `src/config/continue/config.yaml.tmpl` (`qwen2.5-coder:7b`, `roles: [chat]`, `apiBase: http://localhost:11434`, no apiKey) — distinct from T017 autocomplete model
- [x] T023a [P] [US4] Create workspace override example at `src/config/continue/config.yaml.workspace-example` showing per-project customization (e.g., local-only Ollama provider for sensitive projects) per Contract 2 workspace override behavior — models and mcpServers entries ADD to user-scoped config

**Checkpoint**: Developers can switch providers based on task, cost, or privacy needs; workspace-level overrides documented for per-project customization

---

## Phase 8: User Story 5 - MCP Integration for Extended Context (Priority: P2)

**Goal**: AI extensions access workspace files and git context via MCP servers for richer responses

**Independent Test**: Ask chat about a file not currently open, verify AI can reference its contents

### Tests for User Story 5

- [x] T024 [P] [US5] Contract test for Cline MCP settings in `tests/contract/test_cline_mcp_valid.sh` — validate JSON syntax, `autoApprove: []`, `/workspace` scope per Contract 4
- [x] T025 [P] [US5] Integration test for MCP filesystem scope in `tests/integration/test_mcp_scope.sh` — verify MCP reads `/workspace`, blocked outside

### Implementation for User Story 5

- [x] T026 [US5] Add `mcpServers` section to `src/config/continue/config.yaml.tmpl` with filesystem MCP server (`command: mcp-server-filesystem`, `args: [/workspace]`)
- [x] T027 [US5] Create `src/config/cline/cline_mcp_settings.json` with filesystem and git MCP servers per Contract 4 schema (`autoApprove: []`, scoped to `/workspace`)
- [x] T028 [US5] Add Dockerfile step to create Cline globalStorage directory and copy MCP settings to `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

**Checkpoint**: AI responses leverage full project context via MCP filesystem and git servers

---

## Phase 9: User Story 6 - Agentic Multi-Step Tasks (Priority: P3)

**Goal**: Cline handles complex multi-file tasks with explicit human approval before file writes or command execution

**Independent Test**: Give Cline a multi-file task, verify it shows plan and requires approval for each change

### Implementation for User Story 6

- [x] T029 [US6] Verify Cline extension config defaults enforce human-in-the-loop approval (auto-approve GlobalState defaults to false per research.md §4) — document in implementation notes
- [x] T030 [US6] Add integration verification that `ANTHROPIC_API_KEY` env var is accessible to Cline for authentication (extends bridge-secrets.sh if needed)

**Checkpoint**: Cline proposes plans and requires explicit approval, never modifies files without developer consent

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and hardening across all stories

- [x] T031 Run quickstart.md verification checklist against built container
- [x] T032 [P] Security review: verify no API keys in image layers, Output panel, or logs per SC-009
- [x] T033 Validate all contract tests pass and integration test suite runs end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **US7 (Phase 3)**: Depends on Foundational - extension install + telemetry
- **US3 (Phase 4)**: Depends on Foundational - API key bridge
- **US1 (Phase 5)**: Depends on US7 (extensions activated) + US3 (API keys working)
- **US2 (Phase 6)**: Depends on US1 (Continue config exists to add chat model)
- **US4 (Phase 7)**: Depends on US2 (config.yaml.tmpl has base structure)
- **US5 (Phase 8)**: Depends on US7 (extensions installed) + Phase 2 (MCP packages installed)
- **US6 (Phase 9)**: Depends on US3 (API keys) + US5 (MCP configured for Cline)
- **Polish (Phase 10)**: Depends on all user stories being complete

### User Story Dependencies

- **US7 (P1)**: Can start after Foundational → MVP entry point
- **US3 (P1)**: Can start after Foundational → parallel with US7
- **US1 (P1)**: Depends on US7 + US3
- **US2 (P1)**: Depends on US1 (shares config file)
- **US4 (P2)**: Depends on US2 (extends config)
- **US5 (P2)**: Depends on Foundational (parallel with US7/US3)
- **US6 (P3)**: Depends on US3 + US5

### Within Each User Story

- Tests written FIRST, verify they FAIL before implementation
- Config files before Dockerfile integration steps
- Core implementation before integration verification

### Parallel Opportunities

- T001 and T002 (Setup phase) — independent files
- T003 and T004 (Foundational) — different files
- T006 and T007 (US7 tests) — different test files
- T010, T011, T012 (US3 tests) — different test files
- T015, T016 (US1 tests) — different test files
- T024, T025 (US5 tests) — different test files
- US7 and US3 can start in parallel after Foundational
- US5 can start in parallel with US1/US2 (different config files)

---

## Parallel Example: User Story 7

```bash
# Launch US7 tests together:
Task: "Integration test for extension activation in tests/integration/test_extension_activation.sh"
Task: "Integration test for telemetry blocking in tests/integration/test_telemetry_block.sh"
```

## Parallel Example: User Story 3

```bash
# Launch US3 tests together:
Task: "Unit test for bridge script in tests/unit/test_bridge_secrets.sh"
Task: "Contract test for no hardcoded keys in tests/contract/test_no_hardcoded_keys.sh"
Task: "Integration test for API key bridge in tests/integration/test_api_key_bridge.sh"
```

## Parallel Example: User Story 5

```bash
# Launch US5 tests together:
Task: "Contract test for Cline MCP settings in tests/contract/test_cline_mcp_valid.sh"
Task: "Integration test for MCP scope in tests/integration/test_mcp_scope.sh"
```

---

## Implementation Strategy

### MVP First (US7 + US3 + US1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - builds container with extensions)
3. Complete Phase 3: US7 (extensions activate cleanly)
4. Complete Phase 4: US3 (API keys flow correctly)
5. Complete Phase 5: US1 (autocomplete works)
6. **STOP and VALIDATE**: Build container, verify ghost text completions appear
7. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Container builds with extensions ✓
2. US7 → Extensions activate, telemetry blocked ✓
3. US3 → API keys bridge correctly ✓
4. US1 → Inline completions working → **MVP Demo!**
5. US2 → Chat panel working → Enhanced Demo
6. US4 → Multi-provider → Flexibility Demo
7. US5 → MCP context → Quality Demo
8. US6 → Agentic tasks → Full Feature Demo

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US7 (extensions) + US3 (API keys) → US1 (completions) → US2 (chat)
   - Developer B: US5 (MCP configs) → US6 (Cline agentic)
   - Developer C: US4 (multi-provider)
3. Stories integrate via shared config.yaml.tmpl (coordinate on this file)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- This is an infrastructure/config project — no application code, only Dockerfile, scripts, and config templates
- Continue config.yaml.tmpl is built incrementally across US1 → US2 → US4 → US5 (additive sections)
- Cline config is independent (separate JSON file) — can be done in parallel
- All MCP packages pre-installed in Dockerfile (never npx at runtime) per security requirements
- Extension versions pinned: Continue v1.2.14, Cline v3.51.0
- MCP versions pinned: @modelcontextprotocol/server-filesystem@2026.1.14, mcp-server-git==2026.1.14
