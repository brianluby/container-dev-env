# Contract: Documentation Navigation

This contract defines the navigation expectations used to satisfy FR-001/FR-007 and SC-003/SC-005.

## Entry point

- `README.md` is the single documentation entry point.
- It must link to the top-level category indexes under `docs/`.

## Category indexes

Each top-level directory must have a clear landing page (index) that:

- Explains what the category is for.
- Lists the most important pages in reading order.
- Links to deeper pages by topic.

Recommended categories:

- `docs/getting-started/`
- `docs/features/`
- `docs/operations/`
- `docs/contributing/`
- `docs/architecture/`
- `docs/reference/`

## Reachability

- Every documentation page must be reachable from at least one navigation path.
- Target: any page reachable within 3 navigations from `README.md`.

## Navigation map

- `docs/navigation.md` provides a human-maintained map of the hierarchy for quick scanning.
