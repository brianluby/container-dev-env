# Quickstart: Secret Injection for Development Containers

**Feature**: 003-secret-injection
**Time to complete**: ~5 minutes

## Prerequisites

- Development container running (with Chezmoi and age installed)
- A secret you want to use (e.g., GitHub token, API key)

## Step 1: Run Setup Wizard

```bash
./scripts/secrets-setup.sh
```

Follow the interactive prompts. The wizard will:
1. Create your encryption key
2. Configure Chezmoi for age encryption
3. Create an empty secrets template

**Important**: When prompted, back up your encryption key to a password manager!

## Step 2: Add Your First Secret

```bash
# Open the secrets file in your editor
chezmoi edit ~/.secrets.env

# Or use the helper script to add directly
./scripts/secrets-edit.sh add GITHUB_TOKEN=ghp_your_token_here
```

Example secrets file:
```env
# API tokens
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
NPM_TOKEN=npm_xxxxxxxxxxxxxxxxxxxx

# Cloud credentials
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...

# Database
DATABASE_URL=postgres://user:pass@host:5432/db
```

## Step 3: Apply and Verify

```bash
# Apply chezmoi changes (decrypts secrets)
chezmoi apply

# Verify secrets are available
echo $GITHUB_TOKEN
```

## Step 4: Restart Container

For the container entrypoint to load your secrets as environment variables:

```bash
# Exit and restart the container
exit
docker-compose up -d
docker-compose exec dev bash

# Verify secrets are loaded
env | grep GITHUB
```

## Daily Workflow

After initial setup, secrets load automatically on container start. No daily action required.

**To add/update secrets**:
```bash
chezmoi edit ~/.secrets.env  # Edit and save
# Restart container to pick up changes
```

## Troubleshooting

### Secrets not loading?

1. Check the file exists: `ls -la ~/.secrets.env`
2. Check entrypoint ran: `docker logs <container>`
3. Verify chezmoi applied: `chezmoi status`

### Encryption key lost?

You'll need to:
1. Generate a new key: `age-keygen -o ~/.config/chezmoi/key.txt`
2. Recreate your secrets file from scratch
3. Re-encrypt: `chezmoi add --encrypt ~/.secrets.env`

### Parse error on startup?

Check your secrets file format:
```bash
./scripts/secrets-edit.sh validate
```

Fix any invalid lines (must be `KEY=value` or `# comment`).

## Security Reminders

- ✅ Encryption key backed up to password manager
- ✅ Secrets file encrypted before committing
- ✅ Never share your age private key
- ✅ Rotate secrets periodically
