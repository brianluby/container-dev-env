# Tasks: Voice Input for AI Coding Prompts

**Input**: Design documents from `/specs/015-voice-input/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Integration tests included as the spec explicitly mentions testability and the constitution requires test-first development.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- This feature uses `src/scripts/`, `src/config/`, `src/chezmoi/`, and `tests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, directory structure, and shared utilities

- [ ] T001 Create project directory structure per plan.md layout (`src/scripts/`, `src/scripts/lib/`, `src/config/`, `src/chezmoi/voice-input/dot_config/voice-input/`, `tests/integration/`, `tests/unit/`)
- [ ] T002 [P] Create environment variable template in `src/config/voice-input.env.example` with ANTHROPIC_API_KEY, OPENAI_API_KEY placeholders
- [ ] T003 [P] Create shared shell library with common functions (logging, validation, macOS detection) in `src/scripts/lib/common.sh`
- [ ] T004 [P] Add shellcheck configuration (`.shellcheckrc`) and shfmt settings at repository root for Bash linting compliance per plan.md Bash Standards

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core configuration schemas and seed data that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Create Chezmoi settings template with all VoiceInputSettings fields (activation_shortcut, activation_mode, whisper_model, cleanup_tier, custom_vocab_paths, silence_timeout_ms, max_recording_duration_s, output_method, visual_feedback) in `src/chezmoi/voice-input/dot_config/voice-input/settings.yaml.tmpl`
- [ ] T006 [P] Create seed vocabulary file with common developer technical terms (50+ entries using spoken_forms/display_form/category schema) in `src/config/vocabulary.yaml`
- [ ] T007 [P] Create AI cleanup system prompt template in `src/config/ai-cleanup-prompt.txt` per research.md tiered prompt strategy
- [ ] T008 [P] Create config validation function in `src/scripts/lib/config-validator.sh` that validates settings.yaml against VoiceInputSettings schema from data-model.md (field types, enums, ranges)
- [ ] T009 Implement platform prerequisite checks (macOS detection, Apple Silicon check, Superwhisper/VoiceInk installation detection) in `src/scripts/lib/prerequisites.sh`

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Developer Dictates Complex Instructions to AI (Priority: P1) 🎯 MVP

**Goal**: Developer presses a keyboard shortcut, speaks a technical instruction, and receives accurate transcribed text ready to paste into an AI agent

**Independent Test**: Activate voice dictation, speak "Create a function that validates email addresses using the pattern from our utils module", verify accurate transcription appears within 5 seconds

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T010 [P] [US1] Integration test verifying setup script creates `~/.config/voice-input/settings.yaml`, vocabulary.yaml, and ai-cleanup-prompt.txt in `tests/integration/test_setup.sh`
- [ ] T011 [P] [US1] Unit test verifying settings.yaml is valid YAML and contains required fields (whisper_model, activation_shortcut, cleanup_tier) in `tests/unit/test_config_parsing.sh`

### Implementation for User Story 1

- [ ] T012 [US1] Implement `setup-voice-input.sh` argument parsing (--tool, --model, --shortcut, --cleanup-tier, --offline-only, --dry-run, --help) in `src/scripts/setup-voice-input.sh`
- [ ] T013 [US1] Implement prerequisite validation in `setup-voice-input.sh` (calls prerequisites.sh: macOS check, Apple Silicon check, tool installed check, mic permission check)
- [ ] T014 [US1] Implement settings file generation in `setup-voice-input.sh` (creates `~/.config/voice-input/settings.yaml` from template with user-provided options)
- [ ] T015 [US1] Implement vocabulary seed in `setup-voice-input.sh` (copies `src/config/vocabulary.yaml` to `~/.config/voice-input/vocabulary.yaml` if not exists)
- [ ] T016 [US1] Implement AI cleanup prompt deployment in `setup-voice-input.sh` (copies `src/config/ai-cleanup-prompt.txt` to `~/.config/voice-input/`)
- [ ] T017 [US1] Implement `--dry-run` mode in `setup-voice-input.sh` (prints what would be created/modified without making changes)
- [ ] T018 [US1] Implement `verify-voice-input.sh` with all 7 health checks (settings exists, tool installed, tool running, mic permission, vocab valid, cleanup available, API key set) in `src/scripts/verify-voice-input.sh`
- [ ] T019 [US1] Implement `--json` output mode in `verify-voice-input.sh` per contracts/setup-script-interface.md JSON format
- [ ] T020 [US1] Add Superwhisper-specific configuration guidance (large-v3 model download, push-to-talk shortcut setup, Code Dictation mode) as output from `setup-voice-input.sh`

**Checkpoint**: User Story 1 complete — developer can run setup, configure Superwhisper, and dictate instructions with accurate transcription

---

## Phase 4: User Story 2 — Privacy-Preserving Local Processing (Priority: P1)

**Goal**: All voice processing happens locally with no network calls; system works fully offline

**Independent Test**: Enable offline mode, disconnect from internet, verify dictation works with no network requests

### Tests for User Story 2

- [ ] T021 [P] [US2] Integration test verifying offline_only=true prevents cleanup_tier=cloud in `tests/integration/test_offline_mode.sh`
- [ ] T022 [P] [US2] Integration test verifying only none/rules/local_llm cleanup tiers are valid when offline_only=true in `tests/integration/test_offline_mode.sh`

### Implementation for User Story 2

- [ ] T023 [US2] Add offline mode enforcement in config validation (if offline_only=true, cleanup_tier must be none, rules, or local_llm) in `src/scripts/lib/config-validator.sh`
- [ ] T024 [US2] Add offline mode check in `setup-voice-input.sh` that warns if --cleanup-tier=cloud conflicts with --offline-only
- [ ] T025 [US2] Document offline verification steps in setup script output (how to confirm no network calls during dictation)

**Checkpoint**: User Story 2 complete — privacy-preserving local-only mode is enforced and verifiable

---

## Phase 5: User Story 3 — Quick Activation via Keyboard Shortcut (Priority: P1)

**Goal**: Developer presses a single keyboard shortcut to start dictation within 1 second, and the entire flow completes in under 5 seconds

**Independent Test**: Press configured shortcut, verify dictation begins within 1 second, confirm short phrase is transcribed in under 5 seconds total

### Implementation for User Story 3

- [ ] T026 [US3] Add activation_shortcut validation in `src/scripts/lib/config-validator.sh` (validate shortcut identifier: RightCommand, RightOption, Fn, key combos)
- [ ] T027 [US3] Add shortcut setup instructions in `setup-voice-input.sh` output (tool-specific: Superwhisper Preferences → Shortcuts, VoiceInk Settings → Hotkey)
- [ ] T028 [US3] Document push_to_talk vs toggle mode configuration and recommended defaults (RightCommand, push_to_talk mode) in setup output

**Checkpoint**: User Story 3 complete — configurable keyboard shortcut activates dictation within 1 second

---

## Phase 6: User Story 4 — AI-Powered Transcription Cleanup (Priority: P2)

**Goal**: Optional AI cleanup step formats raw transcription with proper punctuation, technical term capitalization, and code convention formatting using the tiered approach (rules → local_llm → cloud)

**Independent Test**: Dictate "create a function called get user by id that takes a user id parameter", verify cleanup produces "Create a function called getUserById that takes a userId parameter"

### Tests for User Story 4

- [ ] T029 [P] [US4] Integration test verifying cleanup_tier=local_llm generates correct Ollama configuration check in `tests/integration/test_cleanup_config.sh`
- [ ] T030 [P] [US4] Unit test verifying AI cleanup prompt template contains required formatting instructions in `tests/unit/test_cleanup_prompt.sh`

### Implementation for User Story 4

- [ ] T031 [US4] Implement Ollama availability check in `src/scripts/lib/prerequisites.sh` (curl localhost:11434, model list check for phi3:mini or configured model)
- [ ] T032 [US4] Add tiered cleanup configuration to `setup-voice-input.sh` (--cleanup-tier flag: validates prerequisites per tier, configures settings.yaml cleanup_tier field)
- [ ] T033 [US4] Implement tiered cleanup configuration in `src/chezmoi/voice-input/dot_config/voice-input/settings.yaml.tmpl` (cleanup_tier enum, cleanup_local_llm_model, cleanup_cloud_provider, cleanup_cloud_api_key_env)
- [ ] T034 [US4] Add cloud cleanup opt-in warning in `setup-voice-input.sh` (when cleanup_tier=cloud selected, print privacy notice about text being sent to external API)
- [ ] T035 [US4] Document Superwhisper AI mode configuration (how to set up Code Dictation mode with custom prompt for developer context) in setup output

**Checkpoint**: User Story 4 complete — AI cleanup improves transcription quality with tiered privacy options

---

## Phase 7: User Story 5 — Integration with Containerized IDE Workflow (Priority: P2)

**Goal**: Transcribed text can be pasted into browser-based IDE (code-server) or terminal AI tools running in containers via system clipboard

**Independent Test**: Dictate text, paste into code-server running in container, verify text arrives correctly

### Tests for User Story 5

- [ ] T036 [P] [US5] Integration test verifying clipboard roundtrip (pbcopy/pbpaste) with special characters in `tests/integration/test_clipboard.sh`

### Implementation for User Story 5

- [ ] T037 [US5] Implement clipboard verification check in `verify-voice-input.sh` (pbcopy/pbpaste roundtrip test with backticks, quotes, brackets)
- [ ] T038 [US5] Document clipboard integration workflow in setup output (dictate on host → Cmd+V into browser/terminal → text in container IDE)
- [ ] T039 [US5] Add special character handling guidance (how backticks, quotes, brackets behave when pasting into terminal vs browser)

**Checkpoint**: User Story 5 complete — voice input works seamlessly with containerized development workflow

---

## Phase 8: User Story 6 — Custom Vocabulary for Project Terms (Priority: P3)

**Goal**: Developer can add project-specific terms with spoken forms, display forms, and categories to improve transcription accuracy

**Independent Test**: Add custom term to vocabulary, dictate a sentence using that term, verify improved recognition

### Tests for User Story 6

- [ ] T040 [P] [US6] Integration test verifying vocabulary add-term command creates valid entry with spoken_forms/display_form/category in `tests/integration/test_vocabulary.sh`
- [ ] T041 [P] [US6] Integration test verifying vocabulary validate command catches schema violations in `tests/integration/test_vocabulary.sh`
- [ ] T042 [P] [US6] Unit test verifying vocabulary YAML structure matches vocabulary-schema.yaml (version field, terms array with required properties) in `tests/unit/test_config_parsing.sh`

### Implementation for User Story 6

- [ ] T043 [US6] Implement `update-vocabulary.sh` argument parsing (add-term, remove-term, list, validate, sync subcommands) in `src/scripts/update-vocabulary.sh`
- [ ] T044 [US6] Implement `add-term` subcommand (append term with --spoken-forms, --display-form, --category, --project flags; validate max 500 terms) in `src/scripts/update-vocabulary.sh`
- [ ] T045 [US6] Implement `remove-term` subcommand (remove term by name from vocabulary.yaml) in `src/scripts/update-vocabulary.sh`
- [ ] T046 [US6] Implement `list` subcommand (display current vocabulary grouped by category, optionally filtered by --category or --project) in `src/scripts/update-vocabulary.sh`
- [ ] T047 [US6] Implement `validate` subcommand (check vocabulary file against vocabulary-schema.yaml: required fields, max 500 terms, spoken_forms non-empty) in `src/scripts/update-vocabulary.sh`
- [ ] T048 [US6] Implement `sync` subcommand for Superwhisper (invoke SuperWhisper Trainer or update vocabulary hints) in `src/scripts/update-vocabulary.sh`
- [ ] T049 [US6] Implement `sync` subcommand for VoiceInk (update Personal Dictionary via VoiceInk's config path) in `src/scripts/update-vocabulary.sh`

**Checkpoint**: User Story 6 complete — developer can manage project-specific vocabulary for improved accuracy

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Quality improvements that span multiple user stories

- [ ] T050 [P] Run shellcheck and shfmt on all scripts in `src/scripts/` and fix any issues per plan.md Bash Standards
- [ ] T051 [P] Add `--help` output to all three scripts with usage examples per contracts/setup-script-interface.md
- [ ] T052 Validate all scripts work end-to-end by running quickstart.md verification steps
- [ ] T053 [P] Add error handling for edge cases in all scripts (missing YAML parser, permission denied, disk full, interrupted signals)
- [ ] T054 Update CLAUDE.md with final technology additions from this feature

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US1 (Phase 3): No dependencies on other stories — **start here for MVP**
  - US2 (Phase 4): Independent of other stories (config validation only)
  - US3 (Phase 5): Independent (shortcut configuration guidance)
  - US4 (Phase 6): Independent (AI cleanup is additive)
  - US5 (Phase 7): Independent (clipboard verification)
  - US6 (Phase 8): Independent (vocabulary management)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Core setup — no dependencies on other stories
- **User Story 2 (P1)**: Adds offline enforcement to US1's config — can run in parallel but integrates with US1
- **User Story 3 (P1)**: Adds shortcut guidance — can run in parallel with US1/US2
- **User Story 4 (P2)**: Adds AI cleanup layer — independent, can run after US1
- **User Story 5 (P2)**: Adds clipboard verification — independent, can run after US1
- **User Story 6 (P3)**: Adds vocabulary management — independent, can run after US1

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Library functions before scripts that use them
- Settings generation before verification scripts
- Core implementation before edge case handling

### Parallel Opportunities

- T002, T003, T004 can run in parallel (different files, no dependencies)
- T005, T006, T007, T008 can run in parallel within Phase 2
- T010, T011 can run in parallel (test files)
- T021, T022 can run in parallel (same test file, different test functions)
- T029, T030 can run in parallel (different test files)
- T040, T041, T042 can run in parallel (test files)
- T050-T053 can run in parallel (different concerns)
- Once Phase 2 completes, US2-US6 can all begin in parallel (if team capacity allows)

---

## Parallel Example: User Story 1

```bash
# Launch tests for User Story 1 together:
Task: "Integration test verifying setup creates settings.yaml in tests/integration/test_setup.sh"
Task: "Unit test verifying settings.yaml validity in tests/unit/test_config_parsing.sh"

# After tests written and failing, implementation tasks T012-T017 are sequential
# (all modify setup-voice-input.sh), but T018-T019 (verify script) can run in parallel
# with T012-T017 since they target a different file.
```

---

## Parallel Example: User Story 6

```bash
# Launch all vocabulary tests together:
Task: "Integration test verifying vocabulary add-term in tests/integration/test_vocabulary.sh"
Task: "Integration test verifying vocabulary validate in tests/integration/test_vocabulary.sh"
Task: "Unit test verifying vocabulary YAML structure in tests/unit/test_config_parsing.sh"

# After tests, T043 (arg parsing) must come first, then T044-T049 can be done sequentially
# within the same file (update-vocabulary.sh)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (directory structure)
2. Complete Phase 2: Foundational (settings schema, seed vocabulary, shared libs)
3. Complete Phase 3: User Story 1 (setup + verify scripts)
4. **STOP and VALIDATE**: Run `setup-voice-input.sh`, configure Superwhisper with large-v3 model, dictate a test sentence
5. Deploy/demo if ready — developer can now dictate instructions to AI agents

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test setup flow → **MVP!** (basic dictation works)
3. Add User Story 2 → Verify offline mode → Privacy guaranteed
4. Add User Story 3 → Validate shortcut response time → Quick activation
5. Add User Story 4 → Test tiered AI cleanup quality → Better transcription formatting
6. Add User Story 5 → Verify paste into container IDE → Full workflow
7. Add User Story 6 → Test custom vocabulary → Project-specific accuracy

### Suggested MVP Scope

**User Stories 1-3 (all P1)** form the minimal viable product:
- Setup automation (US1)
- Privacy enforcement (US2)
- Quick activation (US3)

This delivers the core value: fast, private voice dictation with a keyboard shortcut.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Primary tool: **Superwhisper** (research.md recommendation)
- Budget alternative: VoiceInk (supported via --tool flag)
- Default model: **large-v3** (95%+ accuracy, recommended for developer use)
- Default cleanup: **rules** tier (local, no network, instant)
- Config file: `~/.config/voice-input/settings.yaml` (all artifacts aligned)
- All scripts must pass shellcheck and shfmt before merge
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
