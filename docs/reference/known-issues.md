# Known Issues

This page tracks known issues that can affect troubleshooting or local verification.

Applies to: `main`

## Prerequisites

- [Getting Started](../getting-started/index.md)

## Known issues list

### Pre-existing test failures

These failures were documented as pre-existing relative to feature work and may still be present.

- `tests/unit/test_checkpoint.bats`: rollback restores file state (stash pop conflicts)
- `tests/unit/test_usage.bats`: associative array lookup breaks under `set -u` for certain model names

Details (legacy source): [Pre-Existing Failures](../pre-existing-failures.md)

## Related

- [Getting Started Troubleshooting](../getting-started/troubleshooting.md)
- [Operations Troubleshooting](../operations/troubleshooting.md)

## Next steps

- If you are contributing and hit a known test failure, note it in your PR description and link to this page
