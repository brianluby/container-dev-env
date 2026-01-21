# CLI Contract: secrets-edit.sh

**Feature**: 003-secret-injection
**Script**: `scripts/secrets-edit.sh`

## Purpose

Helper script for securely editing encrypted secrets. Wraps `chezmoi edit` with validation and provides a streamlined workflow for adding, updating, or removing secrets.

## Usage

```bash
./scripts/secrets-edit.sh [COMMAND] [OPTIONS]
```

## Commands

| Command | Description |
|---------|-------------|
| `edit` | Open secrets in $EDITOR (default) |
| `add KEY=VALUE` | Add a single secret |
| `remove KEY` | Remove a secret by name |
| `list` | List secret names (not values) |
| `validate` | Check secrets file format |

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--help` | Show usage information | - |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Operation completed successfully |
| 1 | General error |
| 2 | Secrets not configured (run setup first) |
| 3 | Validation failed |
| 4 | Key not found (for remove) |

## Command Details

### edit (default)

Opens the decrypted secrets file in your editor, then re-encrypts on save.

```bash
./scripts/secrets-edit.sh
# or explicitly
./scripts/secrets-edit.sh edit
```

**Flow**:
1. Runs `chezmoi edit ~/.secrets.env`
2. Opens file in `$EDITOR` (or `vi` if unset)
3. On save: validates format, re-encrypts with age
4. On validation error: prompts to fix or discard changes

### add KEY=VALUE

Adds a single secret without opening an editor.

```bash
./scripts/secrets-edit.sh add GITHUB_TOKEN=ghp_xxx
```

**Flow**:
1. Validates key format (`^[A-Z][A-Z0-9_]*$`)
2. Decrypts current secrets
3. Appends or updates the key
4. Re-encrypts and saves

**Output**:
```text
[secrets-edit] Added GITHUB_TOKEN
[secrets-edit] Restart container to apply changes
```

### remove KEY

Removes a secret by name.

```bash
./scripts/secrets-edit.sh remove OLD_API_KEY
```

**Output**:
```text
[secrets-edit] Removed OLD_API_KEY
[secrets-edit] Restart container to apply changes
```

**Error** (key not found):
```text
[secrets-edit] ERROR: Key 'NONEXISTENT' not found in secrets file
```

### list

Lists all secret names (never shows values).

```bash
./scripts/secrets-edit.sh list
```

**Output**:
```text
GITHUB_TOKEN
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DATABASE_URL
```

### validate

Checks the secrets file format without modifying it.

```bash
./scripts/secrets-edit.sh validate
```

**Output (success)**:
```text
[secrets-edit] Secrets file is valid (4 variables defined)
```

**Output (failure)**:
```text
[secrets-edit] ERROR: Invalid line 5: "bad line here"
[secrets-edit] ERROR: Key names must match ^[A-Z][A-Z0-9_]*$
```

## Dependencies

- `chezmoi` (for edit, encryption)
- `age` (encryption backend)
- Standard Unix tools (`grep`, `sed`)

## Security Considerations

- `add` command reads value from argument (visible in shell history)
  - For sensitive values, prefer `edit` command
- `list` never shows values, only names
- Temporary decrypted file handled by chezmoi (secure cleanup)
