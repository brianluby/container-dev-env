# Data Model: Secret Injection for Development Containers

**Feature**: 003-secret-injection
**Date**: 2026-01-20

## Entities

### Secret

A single key-value pair representing sensitive configuration data.

| Attribute | Type | Description | Constraints |
|-----------|------|-------------|-------------|
| name | string | Environment variable name | `^[A-Z][A-Z0-9_]*$`, unique within file |
| value | string | Secret value (encrypted at rest) | Any UTF-8, supports special chars |
| description | string? | Optional comment/description | For documentation only |

**Example**:
```env
# GitHub personal access token for API calls
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### Encryption Key

User's personal age key for encrypting/decrypting secrets.

| Attribute | Type | Description | Constraints |
|-----------|------|-------------|-------------|
| identity | file path | Path to age private key | Default: `~/.config/chezmoi/key.txt` |
| recipient | string | age public key (age1...) | Derived from identity |
| created_at | timestamp | When key was generated | Immutable after creation |

**Lifecycle**:
1. Generated once during initial setup via `age-keygen`
2. Never committed to version control
3. User responsible for backup (e.g., password manager)
4. Loss requires regenerating all secrets from source systems

### Secrets File

Encrypted container for multiple secrets, managed by Chezmoi.

| Attribute | Type | Description | Constraints |
|-----------|------|-------------|-------------|
| source_path | file path | Chezmoi source location | `~/.local/share/chezmoi/private_dot_secrets.env.age` |
| target_path | file path | Decrypted destination | `~/.secrets.env` |
| format | enum | File format | `.env` (KEY=value pairs) |
| encryption | enum | Encryption method | `age` |

**States**:
- **Encrypted** (at rest): Stored in Chezmoi source, safe for version control
- **Decrypted** (runtime): Exists only inside container after `chezmoi apply`

### Secret Profile (Future)

Optional grouping mechanism for different secret sets.

| Attribute | Type | Description | Constraints |
|-----------|------|-------------|-------------|
| name | string | Profile identifier | `^[a-z][a-z0-9-]*$` |
| secrets_file | file path | Associated secrets file | One file per profile |
| active | boolean | Currently loaded profile | One active at a time |

**Note**: Profiles are out of scope for initial implementation. Documented for future extensibility.

## File Locations

```text
Host Filesystem (persisted)
├── ~/.config/chezmoi/
│   ├── chezmoi.toml          # Chezmoi config with age settings
│   └── key.txt               # age private key (NEVER commit)
│
└── ~/.local/share/chezmoi/
    └── private_dot_secrets.env.age  # Encrypted secrets (safe to commit)

Container Filesystem (runtime)
└── ~/
    └── .secrets.env          # Decrypted secrets (ephemeral)
```

## Data Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│                        SETUP (one-time)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  age-keygen ──► ~/.config/chezmoi/key.txt (private key)        │
│                                                                 │
│  User edits ──► ~/.secrets.env (plaintext)                     │
│       │                                                         │
│       ▼                                                         │
│  chezmoi add --encrypt ──► private_dot_secrets.env.age         │
│                            (encrypted, in chezmoi source)       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CONTAINER STARTUP (every time)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  chezmoi apply ──► Decrypts .age file using key.txt            │
│       │            Creates ~/.secrets.env (plaintext)           │
│       ▼                                                         │
│  entrypoint.sh ──► source ~/.secrets.env                       │
│       │            Exports all variables                        │
│       ▼                                                         │
│  Application ──► Reads secrets from environment                │
│                  (e.g., $GITHUB_TOKEN)                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    UPDATE SECRETS (as needed)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  chezmoi edit ~/.secrets.env ──► Opens decrypted in $EDITOR    │
│       │                          Saves re-encrypted             │
│       ▼                                                         │
│  Container restart ──► Picks up new values                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Validation Rules

### Secret Name Validation
- Must start with uppercase letter
- May contain uppercase letters, digits, underscores
- Cannot be empty
- Cannot contain `=` or newlines

### Secret Value Validation
- May contain any UTF-8 characters
- Values with spaces/quotes should be quoted in .env file
- Newlines within values use `\n` escape sequence
- Empty values are allowed (`KEY=`)

### File Validation
- Must be valid `.env` format
- Each line: `KEY=value` or `# comment` or blank
- Parse error on malformed lines → fail fast with line number
