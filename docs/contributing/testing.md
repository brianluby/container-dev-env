# Testing

This page explains how to run the same checks CI runs and how to add tests for new shell functionality.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`
- You can run the repo inside the dev container (recommended)

## Test types

- Unit tests: BATS under `tests/unit/`
- Integration tests: scripts under `tests/integration/` (some require Docker)
- Contract tests: scripts under `tests/contract/`
- Static analysis: ShellCheck for shell scripts

## Run tests

From the repo root:

```bash
bats tests/unit/
bats tests/contract/
bats tests/integration/
```

## Run ShellCheck

```bash
shellcheck scripts/*.sh docker/*.sh src/**/*.sh 2>/dev/null || true
```

If the repo provides a wrapper script for CI parity, prefer it.

## Writing tests (BATS)

Guidelines:

- Follow AAA: Arrange, Act, Assert
- Keep tests isolated (use temp dirs)
- Prefer checking exit codes + output
- Include at least one edge case

## Related

- `docs/test-matrix.md` (legacy reference)
- `docs/reference/search.md`

## Next steps

- Review repo layout: `docs/contributing/project-structure.md`
