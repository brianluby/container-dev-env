# Known Issues

This page tracks known issues that can affect troubleshooting or local verification.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`

## Known issues list

### Pre-existing test failures

These failures were documented as pre-existing relative to feature work and may still be present.

- `tests/unit/test_checkpoint.bats`: rollback restores file state (stash pop conflicts)
- `tests/unit/test_usage.bats`: associative array lookup breaks under `set -u` for certain model names

Details (legacy source): `docs/pre-existing-failures.md`

## Related

- `docs/getting-started/troubleshooting.md`
- `docs/operations/troubleshooting.md`

## Next steps

- If you are contributing and hit a known test failure, note it in your PR description and link to this page
