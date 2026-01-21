# CLI Contract: secrets-setup.sh

**Feature**: 003-secret-injection
**Script**: `scripts/secrets-setup.sh`

## Purpose

Interactive setup wizard for first-time secret injection configuration. Guides users through creating an encryption key, configuring Chezmoi, and adding their first secrets.

## Usage

```bash
./scripts/secrets-setup.sh [OPTIONS]
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--non-interactive` | Skip prompts, use defaults | Interactive |
| `--key-path PATH` | Custom age key location | `~/.config/chezmoi/key.txt` |
| `--help` | Show usage information | - |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Setup completed successfully |
| 1 | General error (see stderr) |
| 2 | Missing dependencies (age, chezmoi) |
| 3 | Key already exists (use --force to regenerate) |
| 4 | User cancelled setup |

## Interactive Flow

```text
=== Secret Injection Setup ===

Step 1/4: Checking dependencies...
  ✓ age v1.1.1 found
  ✓ chezmoi v2.47.1 found

Step 2/4: Creating encryption key...
  Key location: ~/.config/chezmoi/key.txt
  [Created] Your public key: age1xxxxxxxxx...

  ⚠️  IMPORTANT: Back up this key to a password manager!
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

## Non-Interactive Mode

With `--non-interactive`:
- Creates key without confirmation
- Uses all default paths
- Creates empty secrets template
- Exits with code 3 if key already exists

## Dependencies

- `age` (v1.1.1+) - encryption
- `chezmoi` (v2.47.1+) - dotfile management

## Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `~/.config/chezmoi/key.txt` | Created | age private key |
| `~/.config/chezmoi/chezmoi.toml` | Modified | Add age configuration |
| `~/.local/share/chezmoi/private_dot_secrets.env.age` | Created | Encrypted secrets template |

## Error Messages

| Condition | Message |
|-----------|---------|
| age not found | `ERROR: age is required but not installed. Install with: brew install age` |
| chezmoi not found | `ERROR: chezmoi is required but not installed. Install with: brew install chezmoi` |
| Key exists | `ERROR: Encryption key already exists at ~/.config/chezmoi/key.txt. Use --force to regenerate (this will invalidate existing encrypted files).` |
| Permission denied | `ERROR: Cannot write to ~/.config/chezmoi/. Check directory permissions.` |
