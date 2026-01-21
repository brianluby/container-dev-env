# CLI Contract: secrets-load.sh

**Feature**: 003-secret-injection
**Script**: `scripts/secrets-load.sh`

## Purpose

Runtime script that loads decrypted secrets as environment variables. Designed to be sourced by the container entrypoint before executing the main command.

## Usage

```bash
# In entrypoint.sh (source, not execute)
source /usr/local/bin/secrets-load.sh

# Or standalone for testing
./scripts/secrets-load.sh --check
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--check` | Validate secrets file without loading | Load secrets |
| `--secrets-file PATH` | Custom secrets file location | `~/.secrets.env` |
| `--quiet` | Suppress informational output | Show info |
| `--help` | Show usage information | - |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Secrets loaded successfully (or file doesn't exist) |
| 1 | Secrets file exists but is malformed |
| 2 | Secrets file exists but is unreadable |

## Behavior

### When Sourced (Normal Operation)

```bash
# entrypoint.sh
#!/bin/bash
source /usr/local/bin/secrets-load.sh
exec "$@"
```

1. Checks if `~/.secrets.env` exists
2. If missing: logs info message, continues (exit 0)
3. If exists: validates format, sources file with `set -a`
4. On parse error: logs error with line number, exits 1

### Output (stdout)

```text
[secrets-load] Loading secrets from ~/.secrets.env
[secrets-load] Loaded 5 environment variables
```

### Output on Error (stderr)

```text
[secrets-load] ERROR: Malformed secrets file at line 7
[secrets-load] ERROR: Invalid line: "INVALID LINE WITHOUT EQUALS"
[secrets-load] ERROR: Fix the file and restart the container
```

## Validation Rules

The script validates each line matches one of:
- Empty line (ignored)
- Comment: `# ...` (ignored)
- Variable: `NAME=value` where NAME matches `^[A-Z][A-Z0-9_]*$`

## Environment Variables Set

All variables from the secrets file are exported. Example:

```env
# Input file ~/.secrets.env
GITHUB_TOKEN=ghp_xxx
AWS_ACCESS_KEY_ID=AKIA...
DATABASE_URL=postgres://...
```

```bash
# After sourcing
echo $GITHUB_TOKEN  # ghp_xxx
echo $AWS_ACCESS_KEY_ID  # AKIA...
```

## Security Considerations

- Script never logs secret values
- Secrets only exist in process environment (not files after load)
- Exit immediately on parse error (fail fast)
- No secrets visible in `docker inspect` (loaded at runtime)

## Dependencies

- bash 4.0+ (for `set -a` and pattern matching)
- No external tools required

## Integration with Entrypoint

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
