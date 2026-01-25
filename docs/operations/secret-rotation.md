# Runbook: Secret Rotation

This runbook describes how to rotate secrets used inside the container and verify they are loaded correctly.

Applies to: `main`

## Prerequisites

- `docs/features/secrets-management.md`
- You have generated a new credential in the upstream system (provider dashboard)

## Symptoms

- Provider authentication fails
- A token is suspected leaked or expired

## Diagnosis

Inside the container:

```bash
./scripts/secrets-edit.sh validate
```

## Procedure

1. Update the secret in its upstream source (provider UI).

2. Edit the secrets file:

```bash
chezmoi edit ~/.secrets.env
```

3. Apply changes:

```bash
chezmoi apply
```

4. Restart the container to reload secrets at startup:

```bash
exit
docker compose -f docker/docker-compose.yml restart
docker compose -f docker/docker-compose.yml exec dev bash
```

## Verification

Inside the container:

```bash
./scripts/secrets-edit.sh validate
```

Then run the relevant tool that uses the secret (for example `agent ...`).

## Rollback / safety

- Keep the previous credential valid until verification passes.
- If verification fails, revert the value in `~/.secrets.env` and re-apply.

## Related

- `docs/features/secrets-management.md`
- `docs/operations/container-rebuild.md`

## Next steps

- If secrets still do not load: `docs/operations/troubleshooting.md`
