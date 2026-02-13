# Testing

This page explains how to run the same checks CI runs and how to add tests for new shell functionality.

Applies to: `main`

## Prerequisites

- [Getting Started](../getting-started/index.md)
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

## Digest pinning verifier

Use the digest validator before opening a PR that updates in-scope Dockerfiles:

```bash
./scripts/validate-base-image-digests.sh
./scripts/validate-base-image-digests.sh --json
```

Expected output:

- Text mode prints PASS with checked reference count
- JSON mode returns `{"status":"pass",...}`
- Any missing digest pin or missing amd64/arm64 coverage returns non-zero exit status

## Writing tests (BATS)

Guidelines:

- Follow AAA: Arrange, Act, Assert
- Keep tests isolated (use temp dirs)
- Prefer checking exit codes + output
- Include at least one edge case

## Related

- [Test Matrix](../test-matrix.md) (legacy reference)
- [Search](../reference/search.md)

## Next steps

- Review repo layout: [Project Structure](project-structure.md)
