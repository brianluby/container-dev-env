# Phase 1 Design: Documentation Data Model

This feature is documentation-only; the "data model" is a content/domain model used to keep structure consistent.

## Entities

### DocumentationPage

Represents a single Markdown page.

- `path` (string, unique): repository-relative path (e.g., `docs/getting-started/install.md`).
- `title` (string): H1 title.
- `category` (enum): one of `getting-started`, `features`, `operations`, `architecture`, `contributing`, `reference`.
- `audience` (set): any of `new-user`, `existing-user`, `contributor`, `operator`.
- `prerequisites` (list of links): other pages or external prerequisites.
- `related` (list of links): conceptually adjacent pages.
- `next_steps` (list of links): recommended progression.
- `applies_to` (optional string): e.g., `main`.
- `tested_with` (optional string): e.g., image tag or commit SHA when behavior is version-sensitive.

Validation rules:

- Must have a single H1.
- Must include sections for: Prerequisites, Related, Next steps.
- If behavior differs across releases, must include Applies to / Tested with.

### DocumentationCategory

Represents a logical group of pages.

- `name` (enum): matches `DocumentationPage.category`.
- `index_page` (path): the category landing page.
- `pages` (list of paths).

### NavigationStructure

Represents the docs navigation and reachability expectations.

- `entry_point` (path): `README.md`.
- `docs_root` (path): `docs/`.
- `navigation_map` (path): `docs/navigation.md`.

Validation rules:

- Entry point links to each top-level category index.
- Every docs page is reachable from at least one navigation path.
- Target: <= 3 clicks/navigations from entry point to any page.

### FeatureGuide (subtype of DocumentationPage)

Required sections:

- What it is / Why it matters
- Prerequisites
- Setup
- Configuration
- Verification
- Troubleshooting

### Runbook (subtype of DocumentationPage)

Required sections:

- Symptoms
- Diagnosis
- Procedure
- Verification (required by SC-006)
- Rollback / Safety notes (when applicable)

### ArchitectureDecisionRecord (ADR)

Referenced entity type for linking; ADRs may live under `docs/decisions/`.

- `id` (string): e.g., `ADR-001`.
- `path` (string).
- `status` (string): accepted/superseded/etc.

## Relationships

- A `DocumentationCategory` groups many `DocumentationPage` items.
- `NavigationStructure` references the category index pages.
- `FeatureGuide` and `Runbook` are specialized `DocumentationPage` types with stricter section requirements.
