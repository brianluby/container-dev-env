# Operations Troubleshooting

This page covers operational issues after you have a working baseline (container starts and you can attach a shell).

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`

## Common problems

### Volumes consume too much disk

- Run the cleanup runbook: `docs/operations/volume-cleanup.md`

### Secrets not loading

- Validate: `./scripts/secrets-edit.sh validate`
- Re-apply: `chezmoi apply`
- Restart container: `docker compose -f docker/docker-compose.yml restart`

See: `docs/features/secrets-management.md`

### Agent tools fail (missing keys, missing binaries)

- Confirm keys are present in the environment
- Confirm the backend binary exists (`which opencode`, `which claude`)

See: `docs/features/ai-assistants.md`

### Known failing tests

Some tests may be failing for reasons not caused by your change. These are tracked as known issues:

- `docs/reference/known-issues.md`

## Related

- `docs/operations/index.md`
- `docs/getting-started/troubleshooting.md`

## Next steps

- If you are contributing: `docs/contributing/testing.md`
