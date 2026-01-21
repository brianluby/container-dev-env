# Research: Secret Injection for Development Containers

**Feature**: 003-secret-injection
**Date**: 2026-01-20

## Research Tasks Completed

### 1. Chezmoi Encrypted Templates

**Question**: How do Chezmoi encrypted templates work with age?

**Decision**: Use Chezmoi's native `age` encryption with `.age` suffix templates.

**Rationale**:
- Chezmoi has built-in age support via `chezmoi encrypt` and automatic decryption
- Encrypted files use `.age` extension and are decrypted during `chezmoi apply`
- Age key stored in `~/.config/chezmoi/key.txt` (configurable)
- No additional tooling required beyond what's in 002-dotfile-management

**Alternatives Considered**:
- SOPS: More complex, requires KMS setup for team use
- GPG: Older, more complex key management
- Raw age files: Would bypass Chezmoi templating benefits

**Implementation Notes**:
```bash
# Generate age key (one-time setup)
age-keygen -o ~/.config/chezmoi/key.txt

# Configure chezmoi to use age
chezmoi edit-config
# Add: [age]
#        identity = "~/.config/chezmoi/key.txt"
#        recipient = "age1..."

# Create encrypted secret template
chezmoi add --encrypt ~/.secrets.env
```

### 2. Environment Variable Injection Pattern

**Question**: How to load encrypted secrets as environment variables at container startup?

**Decision**: Source decrypted env file in container entrypoint.

**Rationale**:
- Simple, standard Unix pattern (`source ~/.secrets.env`)
- Works with all shells and applications
- No custom tooling required
- Variables available to all child processes

**Alternatives Considered**:
- Docker secrets: Requires swarm mode for full functionality
- Vault agent: Heavy infrastructure for local dev
- direnv: Would need `.envrc` per project, encryption layer still needed

**Implementation Notes**:
```bash
# In entrypoint.sh (before exec)
if [ -f "$HOME/.secrets.env" ]; then
    set -a  # Export all variables
    source "$HOME/.secrets.env"
    set +a
fi
exec "$@"
```

### 3. Secret File Format

**Question**: What format should the secrets file use?

**Decision**: Standard `.env` format (KEY=value, one per line).

**Rationale**:
- Universally supported across all languages/frameworks
- Simple to parse and validate
- Human-readable when decrypted for editing
- Direct compatibility with docker-compose and .env loaders

**Alternatives Considered**:
- JSON: More complex to edit, overkill for key-value pairs
- YAML: Requires parser, more error-prone
- Custom format: No benefit, breaks compatibility

**Implementation Notes**:
```env
# ~/.secrets.env (plaintext, before encryption)
GITHUB_TOKEN=ghp_xxxxxxxxxxxx
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
DATABASE_URL=postgres://user:pass@host/db
```

### 4. Security Model

**Question**: How to ensure secrets don't leak via docker inspect or history?

**Decision**: Secrets loaded at runtime via entrypoint, never in Dockerfile or compose env.

**Rationale**:
- Environment variables set by entrypoint after container start
- Not visible in `docker inspect` (only shows compose-defined vars)
- Not in image layers (encrypted file mounted, not copied)
- Decryption happens inside container at runtime

**Alternatives Considered**:
- Docker build-time secrets: Still visible in history without multi-stage
- --env-file flag: Visible in docker inspect
- Volume-mounted env file: Would still need to source it

**Implementation Notes**:
```yaml
# docker-compose.yml - SECURE pattern
services:
  dev:
    volumes:
      - ~/.local/share/chezmoi:/home/dev/.local/share/chezmoi:ro
    # NO env_file or environment with secrets!
```

### 5. First-Time Setup Workflow

**Question**: How to guide new users through initial setup?

**Decision**: Interactive shell script wizard with prompts.

**Rationale**:
- Shell script works everywhere without additional dependencies
- Can validate each step before proceeding
- Provides clear feedback and instructions
- Can be re-run safely if interrupted

**Alternatives Considered**:
- TUI application: Additional dependency
- Web-based wizard: Overkill for local setup
- Documentation only: Higher user friction

**Implementation Notes**:
```bash
#!/bin/bash
# secrets-setup.sh

echo "=== Secret Injection Setup ==="

# Step 1: Check for existing age key
if [ ! -f ~/.config/chezmoi/key.txt ]; then
    echo "Creating new age encryption key..."
    age-keygen -o ~/.config/chezmoi/key.txt
fi

# Step 2: Configure chezmoi
echo "Configuring chezmoi for age encryption..."
# ... configure age.identity and age.recipient

# Step 3: Create template secrets file
echo "Creating secrets template..."
# ... create ~/.secrets.env.tmpl with example

# Step 4: Encrypt and add to chezmoi
echo "Encrypting secrets..."
# ... chezmoi add --encrypt

echo "Setup complete! Edit your secrets with: chezmoi edit ~/.secrets.env"
```

## Dependencies Verified

| Dependency | Version | Status | Notes |
|------------|---------|--------|-------|
| age | 1.1.1+ | Available | Already in base image per 002 |
| chezmoi | 2.47.1+ | Available | Already in base image per 002 |
| bash | 5.x | Available | In Debian bookworm |

## Open Questions Resolved

All technical questions resolved. No NEEDS CLARIFICATION items remaining.
