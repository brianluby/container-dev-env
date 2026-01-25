# Secrets Management (Chezmoi + age)

This project uses Chezmoi + age encryption to keep secrets encrypted at rest while making them available as environment variables inside the container.

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`
- You are comfortable storing a private key in a password manager

## Why this approach

- Secrets are never baked into images (no layer leaks)
- Secrets do not show up in `docker inspect`
- After initial setup, secrets can be used offline

## Setup

1. Inside the container, run the setup script:

```bash
./scripts/secrets-setup.sh
```

2. Edit your decrypted secrets file:

```bash
chezmoi edit ~/.secrets.env
```

Example format (placeholders only):

```env
OPENAI_API_KEY=EXAMPLE_OPENAI_API_KEY_VALUE
ANTHROPIC_API_KEY=EXAMPLE_ANTHROPIC_API_KEY_VALUE
GITHUB_TOKEN=EXAMPLE_GITHUB_TOKEN_VALUE
```

3. Apply changes (Chezmoi re-encrypts at rest and renders the decrypted target):

```bash
chezmoi apply
```

4. Restart the container to ensure secrets are loaded at startup:

```bash
exit
docker compose -f docker/docker-compose.yml restart
docker compose -f docker/docker-compose.yml exec dev bash
```

## Configuration

- Secrets are stored as an age-encrypted file managed by Chezmoi.
- The decrypted target file is `~/.secrets.env` inside the container.
- Secrets are loaded into the process environment at runtime.

## Daily workflow

- Edit: `chezmoi edit ~/.secrets.env`
- Apply: `chezmoi apply`
- Validate: `./scripts/secrets-edit.sh validate`

## Verification

Inside the container:

```bash
./scripts/secrets-edit.sh validate
env | grep -E '^(OPENAI|ANTHROPIC|GOOGLE)_API_KEY=' || true
```

From the host (should not reveal secrets):

```bash
docker compose -f docker/docker-compose.yml exec dev env | head -n 5
docker inspect devenv | jq '.[0].Config.Env' 2>/dev/null || true
```

## Troubleshooting

- Secrets not loading after restart: confirm `~/.secrets.env` exists in the container and rerun `chezmoi apply`
- Parse/validation errors: run `./scripts/secrets-edit.sh validate` and fix the reported line
- Key lost: rerun `./scripts/secrets-setup.sh --force` and re-create secrets from their sources

## Related

- `docs/operations/secret-rotation.md`
- `docs/reference/security-guidance.md`

## Next steps

- Configure AI assistants: `docs/features/ai-assistants.md`
