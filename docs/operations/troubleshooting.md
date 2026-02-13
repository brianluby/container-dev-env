# Operations Troubleshooting

This page covers operational issues after you have a working baseline (container starts and you can attach a shell).

Applies to: `main`

## Prerequisites

- [Getting Started](../getting-started/index.md)

## Common problems

### Volumes consume too much disk

- Run the cleanup runbook: [Volume Cleanup](volume-cleanup.md)

### Secrets not loading

- Validate: `./scripts/secrets-edit.sh validate`
- Re-apply: `chezmoi apply`
- Restart container: `docker compose -f docker/docker-compose.yml restart`

See: [Secrets Management](../features/secrets-management.md)

### Agent tools fail (missing keys, missing binaries)

- Confirm keys are present in the environment
- Confirm the backend binary exists (`which opencode`, `which claude`)

See: [AI Assistants](../features/ai-assistants.md)

### Known failing tests

Some tests may be failing for reasons not caused by your change. These are tracked as known issues:

- [Known Issues](../reference/known-issues.md)

### Digest refresh fails (missing platform coverage)

- Run `./scripts/validate-base-image-digests.sh --json` and inspect reported failures.
- If a digest is missing `linux/amd64` or `linux/arm64`, select a different upstream digest.
- Do not merge partial architecture coverage.

### Roll back a digest refresh safely

- Revert Dockerfile changes for the affected `tag@digest` references.
- Re-run local validator and confirm CI passes on the reverted state.
- In PR notes, explain rollback reason and the blocked digest.

## Related

- [Operations](index.md)
- [Getting Started Troubleshooting](../getting-started/troubleshooting.md)

## Next steps

- If you are contributing: [Testing](../contributing/testing.md)
