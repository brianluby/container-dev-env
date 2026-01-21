# Secret Injection Guide

This guide explains how to securely manage secrets (API keys, tokens, credentials) in your development container using age-encrypted dotfiles managed by Chezmoi.

## Table of Contents

- [Overview](#overview)
- [First-Time Setup](#first-time-setup)
- [Daily Workflow](#daily-workflow)
- [Managing Secrets](#managing-secrets)
- [Container Integration](#container-integration)
- [Offline Usage](#offline-usage)
- [Security Model](#security-model)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

The secret injection system provides:

- **Encryption at rest**: Secrets are encrypted with your personal age key
- **Automatic loading**: Secrets are available as environment variables at container startup
- **No network dependency**: Works completely offline after initial setup
- **Docker-invisible**: Secrets don't appear in `docker inspect` or image layers

### Architecture

```
Host Machine                          Container
─────────────────────────────────────────────────────
~/.config/chezmoi/key.txt ──────────► (mounted)
     (age private key)                    │
                                          ▼
~/.local/share/chezmoi/ ──────────────► chezmoi apply
  private_dot_secrets.env.age              │
     (encrypted)                           ▼
                                      ~/.secrets.env
                                         (decrypted)
                                          │
                                          ▼
                                      entrypoint.sh
                                      source ~/.secrets.env
                                          │
                                          ▼
                                      Environment Variables
                                      $GITHUB_TOKEN, etc.
```

## First-Time Setup

### Prerequisites

- Docker container with `age` and `chezmoi` installed
- 5 minutes of time

### Step 1: Run the Setup Wizard

```bash
./scripts/secrets-setup.sh
```

The wizard will:

1. **Check dependencies** - Verify age and chezmoi are installed
2. **Create encryption key** - Generate your personal age key
3. **Configure chezmoi** - Set up age encryption in chezmoi.toml
4. **Create secrets template** - Initialize an empty encrypted secrets file

Example output:

```
=== Secret Injection Setup ===

Step 1/4: Checking dependencies...
  ✓ age v1.1.1 found
  ✓ chezmoi v2.47.1 found

Step 2/4: Creating encryption key...
  Key location: ~/.config/chezmoi/key.txt
  [Created] Your public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  !!!  IMPORTANT: Back up this key to a password manager!  !!!
       If lost, you will need to recreate all secrets.

Step 3/4: Configuring chezmoi...
  [Updated] ~/.config/chezmoi/chezmoi.toml

Step 4/4: Creating secrets template...
  [Created] ~/.local/share/chezmoi/private_dot_secrets.env.age

=== Setup Complete ===

Next steps:
  1. Edit your secrets: chezmoi edit ~/.secrets.env
  2. Apply changes: chezmoi apply
  3. Restart container to load secrets
```

### Step 2: Add Your Secrets

```bash
chezmoi edit ~/.secrets.env
```

This opens your editor with the decrypted secrets file. Add your secrets:

```env
# API Tokens
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NPM_TOKEN=npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Cloud Credentials
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Database
DATABASE_URL=postgres://user:password@localhost:5432/mydb
```

Save and close. Chezmoi automatically re-encrypts the file.

### Step 3: Apply and Restart

```bash
chezmoi apply    # Decrypt secrets to ~/.secrets.env
exit             # Exit container
docker-compose up -d  # Restart container
```

Your secrets are now available as environment variables.

## Daily Workflow

After initial setup, secrets load automatically. You don't need to do anything special.

### Verify Secrets Are Loaded

```bash
# Inside the container
echo $GITHUB_TOKEN
# Should print: ghp_xxxx...

env | grep -E '^(GITHUB|AWS|DATABASE)'
# Lists all matching environment variables
```

### Secrets Are Invisible to Docker

```bash
# From the host
docker inspect <container_name>
# No secrets visible in Environment section
```

## Managing Secrets

### Using the secrets-edit.sh Helper

#### List All Secrets (names only)

```bash
./scripts/secrets-edit.sh list
```

Output:

```
GITHUB_TOKEN
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DATABASE_URL
```

#### Add a New Secret

```bash
./scripts/secrets-edit.sh add NEW_API_KEY=abc123
```

Note: The value is visible in shell history. For sensitive values, use `edit` instead.

#### Edit Secrets in Editor

```bash
./scripts/secrets-edit.sh edit
# or simply
./scripts/secrets-edit.sh
```

#### Remove a Secret

```bash
./scripts/secrets-edit.sh remove OLD_API_KEY
```

#### Validate Secrets File

```bash
./scripts/secrets-edit.sh validate
```

### Using Chezmoi Directly

```bash
# Edit secrets (opens editor, re-encrypts on save)
chezmoi edit ~/.secrets.env

# Apply changes (decrypt to target location)
chezmoi apply

# View status
chezmoi status
```

### After Changing Secrets

Restart the container to load the new values:

```bash
exit
docker-compose restart dev
docker-compose exec dev bash
```

## Container Integration

### Shell RC File Integration (Recommended for Interactive Sessions)

For secrets to be available in interactive terminal sessions (like when attaching to a container with VS Code or running `docker exec`), add this to your shell rc file:

```bash
# Add to ~/.bashrc, ~/.zshrc, or equivalent

# Load secrets if available
if [ -f /usr/local/bin/secrets-load.sh ]; then
    source /usr/local/bin/secrets-load.sh --quiet
fi
```

**Why shell rc file?** Environment variables set in VS Code's `postAttachCommand` or similar hooks run in a separate shell process that exits after completion. Any exported variables are lost. Loading secrets in the shell rc file ensures they're available in every interactive session.

To add this automatically via Chezmoi:

1. Edit your bashrc template:
   ```bash
   chezmoi edit ~/.bashrc
   ```

2. Add the secret loading snippet at the end of the file

3. Apply changes:
   ```bash
   chezmoi apply
   ```

4. Restart your shell or source the rc file:
   ```bash
   source ~/.bashrc
   ```

### Entrypoint Integration (T025)

For non-interactive containers (batch jobs, services), add this to your container's entrypoint script:

```bash
#!/bin/bash
# /usr/local/bin/entrypoint.sh

# Load secrets if available
if [ -f /usr/local/bin/secrets-load.sh ]; then
    source /usr/local/bin/secrets-load.sh
fi

# Execute the main command
exec "$@"
```

### Docker Compose Configuration

```yaml
# docker-compose.yml
services:
  dev:
    build: .
    volumes:
      # Mount chezmoi source and config
      - ~/.local/share/chezmoi:/home/dev/.local/share/chezmoi:ro
      - ~/.config/chezmoi:/home/dev/.config/chezmoi:ro
      # Mount the scripts
      - ./scripts/secrets-load.sh:/usr/local/bin/secrets-load.sh:ro
    # NO env_file or environment with secrets!
```

### Docker Run Usage (T043)

```bash
docker run -it \
  -v ~/.local/share/chezmoi:/home/dev/.local/share/chezmoi:ro \
  -v ~/.config/chezmoi:/home/dev/.config/chezmoi:ro \
  -v $(pwd)/scripts/secrets-load.sh:/usr/local/bin/secrets-load.sh:ro \
  my-dev-image
```

### VS Code DevContainer

See `templates/devcontainer/devcontainer.json` for a complete example configuration.

**Important**: The template uses `postCreateCommand` to decrypt secrets but does not use `postAttachCommand` to load them, as environment variables set in `postAttachCommand` won't persist (it runs in a separate shell process). Instead, integrate with your shell rc file as shown in the [Shell RC File Integration](#shell-rc-file-integration-recommended-for-interactive-sessions) section above.

## Offline Usage

The secret injection system works completely offline after initial setup:

### What Works Offline

- Loading secrets at container startup
- Editing and re-encrypting secrets
- All secrets-*.sh scripts

### What Requires Network (One-Time Only)

- Installing age and chezmoi (during container build)
- Initial setup if tools aren't installed

### Verification

```bash
# Disconnect from network, then:
docker-compose restart dev
docker-compose exec dev bash
echo $GITHUB_TOKEN  # Should still work
```

## Security Model

### Per-Developer Keys

- Each developer has their own encryption key
- Keys are stored locally, never shared
- No central key server or team keys
- Developers cannot decrypt each other's secrets

### What's Protected

| Asset | Protection |
|-------|------------|
| Encryption key | Never committed, user responsibility |
| Encrypted secrets | Safe to commit (can't decrypt without key) |
| Decrypted secrets | Only in container memory/process |
| Environment variables | Set at runtime, not visible to docker inspect |

### What's NOT Protected

- Shell history if using `secrets-edit.sh add`
- Process memory while running
- Secrets if container is compromised

### Recommendations

1. Use `secrets-edit.sh edit` for sensitive values (not `add`)
2. Back up your encryption key to a password manager
3. Rotate secrets periodically
4. Use separate secrets files for different environments

## Troubleshooting

### Secrets Not Loading

**Symptoms**: Environment variables not set after container restart

**Checklist**:

1. Check secrets file exists:
   ```bash
   ls -la ~/.secrets.env
   ```

2. Check entrypoint sources secrets-load.sh:
   ```bash
   cat /usr/local/bin/entrypoint.sh
   ```

3. Check for validation errors:
   ```bash
   ./scripts/secrets-load.sh --check
   ```

4. Check chezmoi status:
   ```bash
   chezmoi status
   chezmoi apply --verbose
   ```

### Parse Errors

**Symptom**: Container fails to start with validation error

**Example error**:

```
[secrets-load] ERROR: Line 5: Invalid key 'bad-key' - must match ^[A-Z][A-Z0-9_]*$
```

**Fix**: Edit the secrets file and correct the line:

```bash
chezmoi edit ~/.secrets.env
# Fix: Change 'bad-key=value' to 'BAD_KEY=value'
```

### Key Lost or Corrupted

**Symptom**: Cannot decrypt secrets, age errors

**Recovery**:

1. Generate a new key:
   ```bash
   ./scripts/secrets-setup.sh --force
   ```

2. Recreate all secrets from their original sources (GitHub, AWS console, etc.)

3. Add them back:
   ```bash
   chezmoi edit ~/.secrets.env
   ```

**Prevention**: Back up `~/.config/chezmoi/key.txt` to a password manager immediately after setup.

### Chezmoi Not Configured

**Symptom**: `chezmoi edit` doesn't decrypt

**Fix**: Re-run setup:

```bash
./scripts/secrets-setup.sh
```

## Best Practices

### Key Backup

1. **Immediately after setup**, copy your key to a password manager:
   ```bash
   cat ~/.config/chezmoi/key.txt
   # Copy the entire contents to your password manager
   ```

2. Store it with a clear label like "Dev Container Age Key"

3. Test recovery by noting the public key (age1xxx...)

### Secret Naming

Use SCREAMING_SNAKE_CASE for all secret names:

```env
# Good
GITHUB_TOKEN=xxx
AWS_ACCESS_KEY_ID=xxx
DATABASE_URL=xxx

# Bad (will fail validation)
github-token=xxx
awsAccessKeyId=xxx
database.url=xxx
```

### Special Characters

Values can contain any characters. Use quotes for complex values:

```env
# Simple values - no quotes needed
API_KEY=abc123

# Values with spaces
GREETING="Hello World"

# Values with special characters
PASSWORD='p@$$w0rd!#'

# JSON values
CONFIG='{"key": "value"}'
```

### Secret Rotation

1. Update the secret in the source system (GitHub, AWS, etc.)
2. Edit your secrets file:
   ```bash
   chezmoi edit ~/.secrets.env
   ```
3. Restart the container

### Multiple Environments

For different secret sets (dev, staging), use separate chezmoi profiles (future feature) or maintain separate encrypted files.
