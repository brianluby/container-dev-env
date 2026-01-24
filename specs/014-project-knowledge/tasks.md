# Tasks: Structured Project Knowledge for AI Agents

**Input**: Design documents from `/specs/014-project-knowledge/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Only the optional ADR helper script requires BATS tests (per constitution Principle III). Static documentation files are validated via structure checks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the docs/ directory structure that all documentation categories will use

- [x] T001 Create documentation directory structure: `mkdir -p docs/{architecture,decisions,api,domain,operations,security}`
- [x] T002 [P] Copy ADR template to docs/decisions/_template.md from specs/014-project-knowledge/contracts/adr-template.md
- [x] T002a [P] Copy glossary template to docs/domain/_template.md from specs/014-project-knowledge/contracts/glossary-template.md
- [x] T002b [P] Copy architecture overview template to docs/architecture/_template.md from specs/014-project-knowledge/contracts/architecture-overview-template.md

---

## Phase 2: User Story 2 - AI Navigates Project Documentation (Priority: P1) 🎯 MVP

**Goal**: AI agents can discover and navigate all project documentation via a single entry point

**Independent Test**: Ask an AI agent "how is our API designed?" and verify it finds docs/navigation.md, follows the reference, and reads the correct category document

### Implementation for User Story 2

- [x] T003 [US2] Create navigation guide at docs/navigation.md from specs/014-project-knowledge/contracts/navigation-guide-template.md (customize paths and categories for this project)
- [x] T004 [US2] Add "Project Knowledge" section to AGENTS.md referencing docs/navigation.md (use text from specs/014-project-knowledge/contracts/agents-md-integration.md)
- [x] T005 [US2] Verify all file paths in docs/navigation.md quick-reference table resolve to existing files (update as docs are created in later phases)

**Checkpoint**: AI agents can now discover the navigation guide via AGENTS.md and understand the documentation structure

---

## Phase 3: User Stories 1 & 3 - ADR System (Priority: P1)

**Goal (US1)**: AI agents read and follow documented architectural decisions instead of re-proposing rejected solutions

**Goal (US3)**: Developers can create standardized decision records in under 15 minutes

**Independent Test (US1)**: Document a decision (e.g., "We chose REST over GraphQL"), then ask the AI to create a new endpoint — it should follow REST patterns without being told

**Independent Test (US3)**: Create a new ADR using the template and verify it follows the standard format, is discoverable, and takes under 15 minutes

### Implementation for User Stories 1 & 3

- [x] T006 [P] [US1] Create first example ADR at docs/decisions/001-use-markdown-for-documentation.md documenting the decision to use Markdown for all project knowledge (use docs/decisions/_template.md)
- [x] T007 [P] [US3] Write BATS test for new-adr.sh at tests/unit/test_new_adr.bats (verify numbering, template copy, kebab-case naming) — write FIRST, verify it FAILS
- [x] T008 [US3] Create ADR creation helper script at src/scripts/new-adr.sh that auto-numbers and copies the template — verify T007 tests PASS
- [x] T009 [US1] Update docs/navigation.md to confirm decisions/ path references resolve correctly

**Checkpoint**: ADR system is complete — AI agents can find and follow decisions; developers can create new ones quickly

---

## Phase 4: User Story 4 - AI Understands Domain Terminology (Priority: P2)

**Goal**: AI agents use project-specific terminology correctly in generated code and responses

**Independent Test**: Define a domain term (e.g., "DevContainer" means a specific thing in this project) and verify the AI uses that term correctly when generating related code

### Implementation for User Story 4

- [x] T010 [US4] Create domain glossary at docs/domain/glossary.md from specs/014-project-knowledge/contracts/glossary-template.md (populate with initial project terms: DevContainer, Feature Branch, SpecKit, ADR, Chezmoi)
- [x] T011 [US4] Update docs/navigation.md to confirm domain/ path reference resolves correctly

**Checkpoint**: AI agents can look up and use project-specific terminology

---

## Phase 5: User Story 5 - AI Reads Architecture Diagrams (Priority: P2)

**Goal**: AI agents understand system structure and component relationships from text-based diagrams

**Independent Test**: Include a diagram showing component A communicates with component B, then ask the AI about interactions between those components — it should reference the documented relationship

### Implementation for User Story 5

- [x] T012 [P] [US5] Create architecture overview at docs/architecture/overview.md from specs/014-project-knowledge/contracts/architecture-overview-template.md (document container-dev-env system structure with components)
- [x] T013 [US5] Add Mermaid diagrams to docs/architecture/overview.md showing system components and their relationships (flowchart TD, under 15 nodes, prose before each diagram)
- [x] T014 [US5] Update docs/navigation.md to confirm architecture/ path reference resolves correctly

**Checkpoint**: AI agents can parse Mermaid diagrams to understand component relationships

---

## Phase 6: User Story 6 - Documentation Stays Current (Priority: P3)

**Goal**: Documentation has clear size limits, update workflows, and maintenance guidelines

**Independent Test**: Verify all documents are under 500 lines and that the update workflow is documented

### Implementation for User Story 6

- [x] T015 [P] [US6] Create API design principles document at docs/api/principles.md (document REST patterns, endpoint conventions, error response formats)
- [x] T016 [P] [US6] Create operations document at docs/operations/deployment.md (document container build and deployment procedures)
- [x] T017 [P] [US6] Create security document at docs/security/authentication.md (document auth patterns, secret handling practices — NO actual secrets)
- [x] T018 [US6] Verify all documentation files are under 500 lines: `wc -l docs/**/*.md`

**Checkpoint**: All documentation categories are populated with initial content; size constraints verified

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validate the complete system works end-to-end across multiple AI tools

- [x] T019 Update docs/navigation.md with final verified paths for all created documents
- [x] T020 [P] Verify no credentials, secrets, or internal infrastructure details in any docs/ file
- [x] T021 [P] Verify all cross-references between documents use valid relative paths
- [x] T022 Run quickstart.md validation steps (structure check, size check, navigation check, AI test)
- [x] T023 Verify AGENTS.md integration works: AI agent can navigate from AGENTS.md → docs/navigation.md → specific category (test with Claude Code)
- [x] T024 [P] Verify cross-tool compatibility (SC-007): confirm docs/ structure is discoverable by Cline (via .clinerules or AGENTS.md) and Continue (via .continue/config.yaml context) without modification

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **US2 Navigation (Phase 2)**: Depends on Setup — creates the discovery mechanism for all other docs
- **US1+US3 ADR System (Phase 3)**: Depends on Phase 2 (navigation guide must exist to reference decisions/)
- **US4 Domain (Phase 4)**: Depends on Phase 2 (navigation guide references domain/)
- **US5 Architecture (Phase 5)**: Depends on Phase 2 (navigation guide references architecture/)
- **US6 Maintenance (Phase 6)**: Depends on Phase 2 (populates remaining categories)
- **Polish (Phase 7)**: Depends on all previous phases

### User Story Dependencies

- **US2 (P1)**: Foundational — all other stories depend on the navigation guide existing
- **US1 + US3 (P1)**: Depends on US2 for discoverability; US1 and US3 share the ADR template artifact
- **US4 (P2)**: Independent after US2; can run in parallel with US1/US3/US5
- **US5 (P2)**: Independent after US2; can run in parallel with US1/US3/US4
- **US6 (P3)**: Can run after US2; creates remaining category documents

### Within Each User Story

- Create content files before updating navigation references
- Helper script tests before implementation (TDD for new-adr.sh only)
- Navigation guide updates after content files exist

### Parallel Opportunities

- T001, T002: Setup tasks can run in parallel
- T006, T007: ADR example and helper script are independent files
- T010 through T017: All category content files are independent (different directories)
- T012 → T013: Sequential (same file — overview.md); T012 creates structure, T013 adds diagrams
- T015, T016, T017: All remaining category docs can run in parallel
- T019, T020, T021: Polish validation tasks on different concerns

---

## Parallel Example: Phase 3 (US1 + US3)

```bash
# Launch independent ADR tasks together:
Task: "Create first example ADR at docs/decisions/001-use-markdown-for-documentation.md"
Task: "Create ADR helper script at src/scripts/new-adr.sh"

# Then sequentially:
Task: "Write BATS test for new-adr.sh" (depends on T007 existing)
Task: "Update navigation.md references" (depends on T006 existing)
```

## Parallel Example: Phase 6 (US6)

```bash
# All category content files can be created simultaneously:
Task: "Create docs/api/principles.md"
Task: "Create docs/operations/deployment.md"
Task: "Create docs/security/authentication.md"

# Then validate:
Task: "Verify all docs under 500 lines"
```

---

## Implementation Strategy

### MVP First (User Story 2 Only)

1. Complete Phase 1: Setup (directory structure)
2. Complete Phase 2: User Story 2 (navigation guide + AGENTS.md)
3. **STOP and VALIDATE**: AI agent can find docs/navigation.md from AGENTS.md
4. This alone provides the discovery framework for all future documentation

### Incremental Delivery

1. Setup + US2 (Navigation) → AI can discover docs → **MVP!**
2. Add US1 + US3 (ADR System) → AI follows decisions; devs can create ADRs
3. Add US4 (Domain Glossary) → AI uses correct terminology
4. Add US5 (Architecture Diagrams) → AI understands system structure
5. Add US6 (Remaining Categories) → Full documentation coverage
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers after Phase 2 (Navigation) is complete:

- Developer A: US1 + US3 (ADR system — tightly coupled)
- Developer B: US4 (Domain glossary) + US5 (Architecture)
- Developer C: US6 (Remaining category documents)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable after US2 (Navigation) is in place
- TDD for new-adr.sh: T007 (test) MUST be written and FAIL before T008 (implementation)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All docs must stay under 500 lines (FR-014 / SC-005)
- No secrets in any documentation file (FR-008 / SC-008)
